import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_credential_store.dart';
import 'package:norte/domain/ports/ai_engine.dart';
import 'package:norte/infrastructure/ai/claude_api_engine.dart';
import 'package:norte/infrastructure/ai/claude_code_cli_engine.dart';
import 'package:norte/infrastructure/ai/copilot_cli_engine.dart';

import '../fakes/fake_ai_engine.dart';
import '../fakes/fake_clock.dart';
import '../support/cli_fixtures.dart';
import '../support/fake_claude_server.dart';
import '../support/fake_process_runner.dart';
import '../support/meeting_fixtures.dart';

/// A situation the contract names, in words rather than in one transport's
/// vocabulary.
///
/// **The old suite spelled these as HTTP statuses**, which worked while every
/// subject spoke HTTP. A subprocess does not have a 401, and expressing the
/// case as "force a 401" would have forced one of two bad answers: invent an
/// HTTP layer inside the CLI adapter, or drop the case for the CLI subjects and
/// stop claiming they pass the same suite.
enum _Situation {
  /// The engine has a credential and it was refused.
  credentialRejected,

  /// The engine is being asked faster than it will answer.
  throttled,

  /// There is no usable credential at all.
  noCredential,
}

/// One engine under test, with the knobs the shared cases need.
class _Subject {
  _Subject({
    required this.name,
    required this.engine,
    required this.answerWith,
    required this.parseAs,
    required this.provoke,
    required this.raises,
    required this.advertisesTokenCeiling,
  });

  final String name;
  final AiEngine engine;

  /// Makes the next `summarize` answer with this raw model text.
  final void Function(String raw) answerWith;

  /// Makes the next `parseIntent` answer with this raw model text.
  final void Function(String raw) parseAs;

  /// Puts the engine into [situation] before the next call.
  final void Function(_Situation situation) provoke;

  /// The `Failure` this engine raises for each situation.
  ///
  /// **Declared per subject because the answers genuinely differ, and the
  /// difference is a finding of S07-CT-01 rather than a hole in it.** The
  /// assertion this buys is still sharp: the two CLI engines are handed the
  /// *same* map ([_cliRaises]), so a change to either adapter's failure
  /// translation breaks this suite; and every entry is a [Failure], which is
  /// what `FallbackAiEngine` needs in order to route it (BR-10).
  final Map<_Situation, TypeMatcher<Failure>> raises;

  /// Whether the engine can state a token ceiling.
  ///
  /// The API engine sends `max_tokens` and therefore knows one. A CLI chooses
  /// its own limits server-side and reports nothing, so it advertises `0` —
  /// which nothing in the app reads, and which is recorded here rather than
  /// papered over with a plausible-looking number.
  final bool advertisesTokenCeiling;
}

/// What both CLI engines raise, for every situation the contract names.
///
/// **All three collapse onto `AiProcessFailure`, and that is the divergence.**
/// Norte holds no credential for either CLI — both authenticate themselves and
/// keep their token under their own name — so `MissingApiKeyFailure` is not
/// merely unraised here, it is unraisable: there is nothing for Settings to
/// clear. What the user actually meets is a CLI that has not been signed in,
/// and what that CLI does is print a complaint and exit non-zero.
///
/// Faking a key to make the original case pass would have made the suite agree
/// with itself about a credential the app does not hold. Mapping the situation
/// onto the failure the CLI really produces keeps the case running, keeps it
/// true, and keeps BR-10 satisfied — `AiProcessFailure` drives the fallback
/// chain exactly as `MissingApiKeyFailure` does.
const Map<_Situation, TypeMatcher<Failure>> _cliRaises =
    <_Situation, TypeMatcher<Failure>>{
      _Situation.credentialRejected: TypeMatcher<AiProcessFailure>(),
      _Situation.throttled: TypeMatcher<AiProcessFailure>(),
      _Situation.noCredential: TypeMatcher<AiProcessFailure>(),
    };

/// What an engine speaking HTTP raises, where each situation has its own status.
const Map<_Situation, TypeMatcher<Failure>> _httpRaises =
    <_Situation, TypeMatcher<Failure>>{
      _Situation.credentialRejected: TypeMatcher<AuthFailure>(),
      _Situation.throttled: TypeMatcher<RateLimitFailure>(),
      _Situation.noCredential: TypeMatcher<MissingApiKeyFailure>(),
    };

/// S03-CT-01 — the `AiEngine` contract · S07-CT-01 — over the CLI engines.
///
/// **The same cases, on every adapter.** `FakeAiEngine` is what the widget and
/// E2E suites are shown; `ClaudeApiEngine` is what a user's transcript
/// actually goes through; `CopilotCliEngine` and `ClaudeCodeCliEngine` are what
/// answers on Windows when the user picks a CLI. If any of those disagree about
/// the shape of a summary or the class of a failure, every test above them is
/// testing something the app does not do.
///
/// The fake is not a mock of the parser — it runs the real
/// `MeetingSummaryCodec` — so it cannot quietly be more forgiving than
/// production. The CLI subjects run the real `CliAiEngine` over a
/// `FakeProcessRunner`, so they exercise the real watchdog, the real JSON
/// extraction and the real failure translation; only the child process is
/// substituted.
///
/// **Two cases diverge across transports, and both are recorded rather than
/// hidden** — see [_cliRaises] for the credential and throttling situations,
/// and `advertisesTokenCeiling` for `maxTokens`. Everything else — the section
/// shape, the action-item rules, the unreadable-answer failure, the intent
/// schema, and the rule that nothing but a `Failure` escapes — holds
/// identically on all four.
void main() {
  late FakeClaudeServer server;
  final List<_Subject> subjects = <_Subject>[];

  setUp(() async {
    server = await FakeClaudeServer.start(answer: summaryFixture('retro.json'));

    final FakeAiEngine fake = FakeAiEngine(
      generatedAt: DateTime.utc(2026, 8, 8, 11),
    )..alwaysAnswer(summaryFixture('retro.json'));

    String? key = 'synthetic-key';
    // Seeded with the same default answer the fake server and the fake engine
    // start from, so a case that never calls `answerWith` is testing the same
    // thing on all four subjects rather than an empty stdout on two of them.
    final _CliDouble copilot = _CliDouble(copilotAnswer)
      ..answer(summaryFixture('retro.json'));
    final _CliDouble claudeCode = _CliDouble(claudeCodeAnswer)
      ..answer(summaryFixture('retro.json'));
    final FakeClock clock = FakeClock(DateTime.utc(2026, 8, 8, 11));

    subjects
      ..clear()
      ..add(
        _Subject(
          name: 'FakeAiEngine',
          engine: fake,
          answerWith: (String raw) => fake
            ..reset()
            ..alwaysAnswer(raw),
          parseAs: fake.alwaysParseAs,
          provoke: (_Situation situation) =>
              fake.failWith = switch (situation) {
                _Situation.credentialRejected => const AuthFailure('rejected'),
                _Situation.throttled => const RateLimitFailure('throttled'),
                _Situation.noCredential => const MissingApiKeyFailure(),
              },
          raises: _httpRaises,
          advertisesTokenCeiling: true,
        ),
      )
      ..add(
        _Subject(
          name: 'ClaudeApiEngine',
          // Reads the key through a closure so `noCredential` can take it away
          // mid-test, exactly as clearing it in Settings would.
          engine: ClaudeApiEngine(
            dio: Dio(),
            credentialStore: _LazyKeyStore(() => key),
            clock: clock,
            baseUrl: server.baseUrl,
          ),
          answerWith: (String raw) => server
            ..answer = raw
            ..forceStatus = null,
          parseAs: (String raw) => server
            ..answer = raw
            ..forceStatus = null,
          provoke: (_Situation situation) => switch (situation) {
            _Situation.credentialRejected => server.forceStatus = 401,
            _Situation.throttled => server.forceStatus = 429,
            _Situation.noCredential => key = null,
          },
          raises: _httpRaises,
          advertisesTokenCeiling: true,
        ),
      )
      ..add(
        _Subject(
          name: 'CopilotCliEngine',
          engine: CopilotCliEngine(
            runner: copilot.runner,
            clock: clock,
            isWindows: true,
          ),
          answerWith: copilot.answer,
          parseAs: copilot.answer,
          provoke: (_) => copilot.refuse(),
          raises: _cliRaises,
          // A CLI reports no ceiling it could report honestly.
          advertisesTokenCeiling: false,
        ),
      )
      ..add(
        _Subject(
          name: 'ClaudeCodeCliEngine',
          engine: ClaudeCodeCliEngine(
            runner: claudeCode.runner,
            clock: clock,
            isWindows: true,
          ),
          answerWith: claudeCode.answer,
          parseAs: claudeCode.answer,
          provoke: (_) => claudeCode.refuse(),
          raises: _cliRaises,
          advertisesTokenCeiling: false,
        ),
      );
  });

  tearDown(() => server.close());

  const List<String> names = <String>[
    'FakeAiEngine',
    'ClaudeApiEngine',
    'CopilotCliEngine',
    'ClaudeCodeCliEngine',
  ];

  for (int index = 0; index < names.length; index++) {
    // Resolved inside each test, because `setUp` rebuilds the list.
    _Subject subject() => subjects[index];
    final String name = names[index];

    group('S03-CT-01: $name', () {
      test('S03-CT-01: returns the template\'s sections, in order', () async {
        final MeetingSummary summary = await subject().engine.summarize(
          retroTranscript,
          retroTemplate,
        );

        expect(summary.sections.keys.toList(), retroTemplate.sectionTitles);
        expect(summary.sections['What went well'], isNotEmpty);
      });

      test(
        'S03-CT-01: a section the meeting did not cover is present, empty',
        () async {
          subject().answerWith(summaryFixture('daily.json'));

          final MeetingSummary summary = await subject().engine.summarize(
            'Ana: nothing to report.',
            dailyTemplate,
          );

          expect(summary.sections.keys.toList(), dailyTemplate.sectionTitles);
          // Present-and-empty, never absent: a missing key would be
          // indistinguishable from a parse that went wrong.
          expect(summary.sections.containsKey('Blockers'), isTrue);
          expect(summary.sections['Blockers'], isEmpty);
        },
      );

      test(
        'S03-CT-01: action items come back with unique, non-empty ids',
        () async {
          final MeetingSummary summary = await subject().engine.summarize(
            retroTranscript,
            retroTemplate,
          );

          expect(summary.actionItems, hasLength(2));
          final Set<String> ids = summary.actionItems
              .map((ActionItem i) => i.id)
              .toSet();
          expect(ids, hasLength(2));
          expect(ids.every((String id) => id.isNotEmpty), isTrue);
        },
      );

      test(
        'S03-CT-01: fresh action items are never already converted',
        () async {
          final MeetingSummary summary = await subject().engine.summarize(
            retroTranscript,
            retroTemplate,
          );

          expect(
            summary.actionItems.every(
              (ActionItem i) => i.convertedTaskId == null,
            ),
            isTrue,
          );
        },
      );

      test('S03-CT-01: an empty action item list is legal', () async {
        subject().answerWith(summaryFixture('daily.json'));

        final MeetingSummary summary = await subject().engine.summarize(
          'Ana: nothing to report.',
          dailyTemplate,
        );

        expect(summary.actionItems, isEmpty);
      });

      test('S03-CT-01: extractActionItems false returns no items', () async {
        final MeetingTemplate quiet = retroTemplate.copyWith(
          extractActionItems: false,
        );

        final MeetingSummary summary = await subject().engine.summarize(
          retroTranscript,
          quiet,
        );

        expect(summary.actionItems, isEmpty);
      });

      test('S03-CT-01: an unreadable answer is AiResponseFailure', () async {
        subject().answerWith(summaryFixture('malformed.txt'));

        await expectLater(
          subject().engine.summarize(retroTranscript, retroTemplate),
          throwsA(isA<AiResponseFailure>()),
        );
      });

      test(
        'S03-CT-01: an answer with none of the sections is refused',
        () async {
          subject().answerWith(summaryFixture('wrong_sections.json'));

          await expectLater(
            subject().engine.summarize(retroTranscript, retroTemplate),
            throwsA(isA<AiResponseFailure>()),
          );
        },
      );

      test('S03-CT-01: a rejected credential is the declared Failure', () async {
        subject().provoke(_Situation.credentialRejected);

        await expectLater(
          subject().engine.summarize(retroTranscript, retroTemplate),
          throwsA(subject().raises[_Situation.credentialRejected]),
        );
      });

      test('S03-CT-01: throttling is the declared Failure', () async {
        subject().provoke(_Situation.throttled);

        await expectLater(
          subject().engine.summarize(retroTranscript, retroTemplate),
          throwsA(subject().raises[_Situation.throttled]),
        );
      });

      test('S03-CT-01: no credential is the declared Failure', () async {
        subject().provoke(_Situation.noCredential);

        await expectLater(
          subject().engine.summarize(retroTranscript, retroTemplate),
          throwsA(subject().raises[_Situation.noCredential]),
        );
      });

      test('S03-CT-01: capabilities are constant and answer BR-07', () async {
        final AiCapabilities first = subject().engine.capabilities;
        final AiCapabilities second = subject().engine.capabilities;

        expect(first, second);
        // **All four subjects are remote** — DEC-037 settled that a CLI is a
        // client for a server-side model, not local inference — so BR-07's
        // redactor relaxation is reachable by no engine that ships in v1.0.
        expect(first.isLocal, isFalse);
        expect(
          first.maxTokens,
          subject().advertisesTokenCeiling ? greaterThan(0) : isZero,
        );
      });

      test('S03-CT-01: nothing but a Failure escapes', () async {
        subject().answerWith(summaryFixture('malformed.txt'));

        try {
          await subject().engine.summarize(retroTranscript, retroTemplate);
          fail('expected a Failure');
        } on Failure {
          // The contract (`docs/project-rules.md` §6).
        } catch (error) {
          fail('a ${error.runtimeType} escaped the port: $error');
        }
      });
    });

    group('S05-CT-02: $name', () {
      test(
        'S05-CT-02: the three test utterances come back as valid intents',
        () async {
          for (final (String utterance, String raw, VoiceIntent expected)
              in _intentCases) {
            subject().parseAs(raw);

            final VoiceIntent intent = await subject().engine.parseIntent(
              utterance,
              const IntentContext(),
            );

            expect(intent, expected, reason: utterance);
            // "Valid against the schema" as the app means it: a type in the
            // enum, confidence in range, and every required slot filled.
            expect(IntentType.values, contains(intent.type));
            expect(intent.confidence, inInclusiveRange(0.0, 1.0));
            expect(intent.missingSlots, isEmpty, reason: utterance);
          }
        },
      );

      test('S05-CT-02: an unreadable answer is AiResponseFailure', () async {
        // Not `unknown`: the adapter reports that it could not read the
        // answer, and `IntentParser` is the only layer entitled to decide
        // that an unreadable answer means "ask the user to rephrase".
        subject().parseAs('Desculpe, não entendi.');

        await expectLater(
          subject().engine.parseIntent('faz aquilo lá', const IntentContext()),
          throwsA(isA<AiResponseFailure>()),
        );
      });

      test('S05-CT-02: a transport failure maps to the same Failure', () async {
        subject().provoke(_Situation.throttled);

        await expectLater(
          subject().engine.parseIntent(
            'muda o PROJ-123 pra concluído',
            const IntentContext(),
          ),
          throwsA(subject().raises[_Situation.throttled]),
        );
      });

      test('S05-CT-02: no credential is the declared Failure', () async {
        subject().provoke(_Situation.noCredential);

        await expectLater(
          subject().engine.parseIntent(
            'muda o PROJ-123 pra concluído',
            const IntentContext(),
          ),
          throwsA(subject().raises[_Situation.noCredential]),
        );
      });

      test('S05-CT-02: primeCache never throws, whatever the state', () async {
        // The port's promise, and the one an engine is most likely to break by
        // accident — a warm-up that can end a voice session is worse than a
        // cold cache. Provoked into its worst state first, because that is
        // when a naive implementation would raise.
        subject().provoke(_Situation.noCredential);

        await expectLater(subject().engine.primeCache(), completes);
      });
    });
  }

  group('S07-CT-01: the CLI engines answer as one', () {
    test(
      'S07-CT-01: both CLI subjects declare the same failure translation',
      () {
        // The sprint's claim is that both engines pass the *same* suite. The
        // per-subject failure map is what makes the divergent cases runnable,
        // so it needs its own guard: if either CLI adapter's translation is
        // changed on its own, this is the assertion that notices.
        expect(subjects[2].raises, subjects[3].raises);
        expect(subjects[2].raises, _cliRaises);
      },
    );

    test('S07-CT-01: neither CLI engine can raise MissingApiKeyFailure', () {
      // Stated as an assertion rather than left as prose, because it is the
      // reason the contract diverges at all: Norte holds no credential for
      // either CLI, so there is nothing for Settings to clear and nothing that
      // could produce this failure.
      for (final _Subject subject in <_Subject>[subjects[2], subjects[3]]) {
        expect(
          subject.raises.values,
          isNot(contains(const TypeMatcher<MissingApiKeyFailure>())),
          reason: subject.name,
        );
      }
    });
  });
}

/// A CLI standing in for one engine's child process.
///
/// Holds the process the next `start` will hand out, so the shared cases can
/// rewrite what the CLI "prints" between calls exactly as they rewrite the fake
/// server's answer.
class _CliDouble {
  _CliDouble(this._envelope);

  /// Wraps a raw model answer in this CLI's output shape.
  final String Function(String payload) _envelope;

  late FakeProcess Function() _next = () => FakeProcess();

  late final FakeProcessRunner runner = FakeProcessRunner.always(
    () => _next(),
  );

  /// Answers with [raw], surrounded by the bookkeeping the real CLI prints.
  ///
  /// The noise is not decoration. It is the difference between a fixture that
  /// proves the parser steps over a banner and one that only proves it can read
  /// a line — and the adapter shipped a bug that only the former would catch.
  void answer(String raw) => _next = () => FakeProcess(
    stdout: <String>[
      updateBanner,
      ...copilotNoise,
      _envelope(raw),
      copilotResult,
    ],
  );

  /// The CLI refusing to work: a complaint on stderr and a non-zero exit.
  ///
  /// The one shape a subprocess has for every credential and quota problem it
  /// meets. See [_cliRaises].
  void refuse() => _next = () => FakeProcess(
    stderr: const <String>[notSignedInStderr],
    exit: 1,
  );
}

/// The three utterances of S05-CT-02, one raw answer each and the intent both
/// adapters must arrive at.
const List<(String, String, VoiceIntent)> _intentCases =
    <(String, String, VoiceIntent)>[
      (
        'muda o PROJ-123 pra concluído',
        '{"intent":"updateJira","slots":{"issueKey":"PROJ-123",'
            '"transition":"Done"},"confidence":0.92}',
        VoiceIntent(
          type: IntentType.updateJira,
          slots: <String, dynamic>{
            'issueKey': 'PROJ-123',
            'transition': 'Done',
          },
          confidence: 0.92,
        ),
      ),
      (
        'cria tarefa revisar PR do conector',
        '{"intent":"createTask","slots":{"title":"revisar PR do conector"},'
            '"confidence":0.95}',
        VoiceIntent(
          type: IntentType.createTask,
          slots: <String, dynamic>{'title': 'revisar PR do conector'},
          confidence: 0.95,
        ),
      ),
      (
        'como tá o PROJ-99?',
        '{"intent":"queryStatus","slots":{"issueKey":"PROJ-99"},'
            '"confidence":0.96}',
        VoiceIntent(
          type: IntentType.queryStatus,
          slots: <String, dynamic>{'issueKey': 'PROJ-99'},
          confidence: 0.96,
        ),
      ),
    ];

/// Reads the key each time, so a test can take it away mid-run.
class _LazyKeyStore implements AiCredentialStore {
  const _LazyKeyStore(this._read);
  final String? Function() _read;

  @override
  Future<String?> read() async => _read();
  @override
  Future<void> write(String apiKey) async {}
  @override
  Future<void> clear() async {}
}
