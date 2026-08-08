import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_credential_store.dart';
import 'package:norte/domain/ports/ai_engine.dart';
import 'package:norte/infrastructure/ai/claude_api_engine.dart';

import '../fakes/fake_ai_engine.dart';
import '../fakes/fake_clock.dart';
import '../support/fake_claude_server.dart';
import '../support/meeting_fixtures.dart';

/// One engine under test, with the knobs the shared cases need.
class _Subject {
  _Subject({
    required this.name,
    required this.engine,
    required this.answerWith,
    required this.failWith,
    required this.clearKey,
  });

  final String name;
  final AiEngine engine;

  /// Makes the next `summarize` answer with this raw model text.
  final void Function(String raw) answerWith;

  /// Makes the next `summarize` fail the way [status] would.
  final void Function(int status) failWith;

  /// Removes the configured API key.
  final void Function() clearKey;
}

/// S03-CT-01 — the `AiEngine` contract.
///
/// **The same cases, on every adapter.** `FakeAiEngine` is what the widget and
/// E2E suites are shown; `ClaudeApiEngine` is what a user's transcript
/// actually goes through. If those two ever disagree about the shape of a
/// summary or the class of a failure, every test above them is testing
/// something the app does not do.
///
/// The fake is not a mock of the parser — it runs the real
/// `MeetingSummaryCodec` — so it cannot quietly be more forgiving than
/// production. `CopilotCliEngine` joins this suite as a third subject in
/// Sprint 07.
void main() {
  late FakeClaudeServer server;
  final List<_Subject> subjects = <_Subject>[];

  setUp(() async {
    server = await FakeClaudeServer.start(answer: summaryFixture('retro.json'));

    final FakeAiEngine fake = FakeAiEngine(
      generatedAt: DateTime.utc(2026, 8, 8, 11),
    )..alwaysAnswer(summaryFixture('retro.json'));

    String? key = 'synthetic-key';
    subjects
      ..clear()
      ..add(
        _Subject(
          name: 'FakeAiEngine',
          engine: fake,
          answerWith: (String raw) => fake
            ..reset()
            ..alwaysAnswer(raw),
          failWith: (int status) => fake.failWith = switch (status) {
            401 => const AuthFailure('rejected'),
            429 => const RateLimitFailure('throttled'),
            _ => const EngineFailure('failed'),
          },
          clearKey: () => fake.failWith = const MissingApiKeyFailure(),
        ),
      )
      ..add(
        _Subject(
          name: 'ClaudeApiEngine',
          // Reads the key through a closure so `clearKey` can take it away
          // mid-test, exactly as clearing it in Settings would.
          engine: ClaudeApiEngine(
            dio: Dio(),
            credentialStore: _LazyKeyStore(() => key),
            clock: FakeClock(DateTime.utc(2026, 8, 8, 11)),
            baseUrl: server.baseUrl,
          ),
          answerWith: (String raw) => server
            ..answer = raw
            ..forceStatus = null,
          failWith: (int status) => server.forceStatus = status,
          clearKey: () => key = null,
        ),
      );
  });

  tearDown(() => server.close());

  for (int index = 0; index < 2; index++) {
    // Resolved inside each test, because `setUp` rebuilds the list.
    _Subject subject() => subjects[index];
    final String name = index == 0 ? 'FakeAiEngine' : 'ClaudeApiEngine';

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

      test('S03-CT-01: a rejected credential is AuthFailure', () async {
        subject().failWith(401);

        await expectLater(
          subject().engine.summarize(retroTranscript, retroTemplate),
          throwsA(isA<AuthFailure>()),
        );
      });

      test('S03-CT-01: throttling is RateLimitFailure', () async {
        subject().failWith(429);

        await expectLater(
          subject().engine.summarize(retroTranscript, retroTemplate),
          throwsA(isA<RateLimitFailure>()),
        );
      });

      test('S03-CT-01: no key configured is MissingApiKeyFailure', () async {
        subject().clearKey();

        await expectLater(
          subject().engine.summarize(retroTranscript, retroTemplate),
          throwsA(isA<MissingApiKeyFailure>()),
        );
      });

      test('S03-CT-01: capabilities are constant and answer BR-07', () async {
        final AiCapabilities first = subject().engine.capabilities;
        final AiCapabilities second = subject().engine.capabilities;

        expect(first, second);
        // Both subjects are remote, which is what obliges the use case to
        // redact. A local engine only arrives in Sprint 07.
        expect(first.isLocal, isFalse);
        expect(first.maxTokens, greaterThan(0));
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
  }
}

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
