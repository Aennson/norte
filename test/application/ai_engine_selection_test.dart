import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/ai/ai_engine_selection.dart';
import 'package:norte/application/ai/fallback_ai_engine.dart';
import 'package:norte/domain/entities/ai_engine_settings.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_engine.dart';

import '../fakes/fakes.dart';
import '../support/meeting_fixtures.dart';

/// An engine that counts its calls and answers however the test says.
///
/// Deliberately **not** `FakeAiEngine`: this suite asserts *how many times* and
/// *in what order* engines were called, which is a different question from
/// whether a summary parses, and mixing the two would make a failure here
/// ambiguous between the chain and the codec.
class _SpyEngine implements AiEngine {
  // `failures` is settable rather than a constructor argument: every scenario
  // in this suite adjusts it after building the engine — that is what "fails
  // once, then works" is — so an argument nobody passed was only ever going to
  // go stale.
  _SpyEngine({this.name = 'spy'});

  /// How many of the first calls should fail before one succeeds.
  int failures = 0;

  final String name;

  /// Calls received.
  int calls = 0;

  /// The failure raised while [failures] has not been used up.
  Failure failWith = const EngineFailure('spy failed');

  @override
  AiCapabilities get capabilities => const AiCapabilities(
    isLocal: false,
    supportsStreaming: false,
    supportsPromptCache: false,
    maxTokens: 0,
  );

  @override
  Future<MeetingSummary> summarize(
    String transcript,
    MeetingTemplate template,
  ) async {
    _tick();
    return MeetingSummary(
      sections: <String, String>{
        for (final String title in template.sectionTitles) title: 'from $name',
      },
      actionItems: const <ActionItem>[],
      generatedAt: DateTime.utc(2026, 8, 10),
      engineId: name,
    );
  }

  @override
  Future<VoiceIntent> parseIntent(
    String utterance,
    IntentContext context,
  ) async {
    _tick();
    return VoiceIntent(
      type: IntentType.createTask,
      slots: <String, String>{'title': 'from $name'},
      confidence: 0.9,
    );
  }

  @override
  Future<void> primeCache() async {}

  void _tick() {
    calls++;
    if (calls <= failures) throw failWith;
  }
}

void main() {
  final IntentContext context = IntentContext(locale: 'pt-BR');

  NamedEngine named(String id, _SpyEngine engine) =>
      NamedEngine(id: id, label: id, engine: engine);

  group('S07-UT-01: selection by platform and preference', () {
    /// The four combinations the sprint names, plus the two the third engine
    /// adds. `resolve` is given builders that record whether they were called,
    /// because "did not choose Copilot" and "chose it and it happened not to
    /// run" are different facts.
    AiEngine resolveWith({
      required EnginePref pref,
      required bool isWindows,
      required List<String> built,
      bool fallbackEnabled = true,
    }) => AiEngineSelection.resolve(
      settings: AiEngineSettings(
        engine: pref,
        fallbackEnabled: fallbackEnabled,
      ),
      isWindows: isWindows,
      claudeApi: () {
        built.add('claude-api');
        return _SpyEngine(name: 'claude-api');
      },
      copilotCli: () {
        built.add('copilot-cli');
        return _SpyEngine(name: 'copilot-cli');
      },
      claudeCodeCli: () {
        built.add('claude-code-cli');
        return _SpyEngine(name: 'claude-code-cli');
      },
    );

    test(
      'S07-UT-01: (copilot, Windows) is Copilot with the Claude fallback',
      () {
        final List<String> built = <String>[];
        final FallbackAiEngine chain =
            resolveWith(
                  pref: EnginePref.copilotCli,
                  isWindows: true,
                  built: built,
                )
                as FallbackAiEngine;

        expect(chain.primary.id, AiEngineSelection.copilotCliId);
        expect(chain.fallback?.id, AiEngineSelection.claudeApiId);
        expect(built, containsAll(<String>['copilot-cli', 'claude-api']));
        expect(built, isNot(contains('claude-code-cli')));
      },
    );

    test('S07-UT-01: (copilot, non-Windows) is the Claude API', () {
      final List<String> built = <String>[];
      final FallbackAiEngine chain =
          resolveWith(
                pref: EnginePref.copilotCli,
                isWindows: false,
                built: built,
              )
              as FallbackAiEngine;

      expect(chain.primary.id, AiEngineSelection.claudeApiId);
      expect(chain.fallback, isNull);
      // The point of the assertion: a phone must not so much as *construct* a
      // subprocess engine, let alone offer it.
      expect(built, isNot(contains('copilot-cli')));
    });

    test('S07-UT-01: (claude, Windows) is the Claude API', () {
      final List<String> built = <String>[];
      final FallbackAiEngine chain =
          resolveWith(pref: EnginePref.claudeApi, isWindows: true, built: built)
              as FallbackAiEngine;

      expect(chain.primary.id, AiEngineSelection.claudeApiId);
      expect(built, isNot(contains('copilot-cli')));
    });

    test('S07-UT-01: (claude, non-Windows) is the Claude API', () {
      final List<String> built = <String>[];
      final FallbackAiEngine chain =
          resolveWith(
                pref: EnginePref.claudeApi,
                isWindows: false,
                built: built,
              )
              as FallbackAiEngine;

      expect(chain.primary.id, AiEngineSelection.claudeApiId);
      expect(chain.fallback, isNull);
    });

    test(
      'S07-UT-01: (claudeCode, Windows) is Claude Code with the Claude fallback (DEC-038)',
      () {
        final List<String> built = <String>[];
        final FallbackAiEngine chain =
            resolveWith(
                  pref: EnginePref.claudeCodeCli,
                  isWindows: true,
                  built: built,
                )
                as FallbackAiEngine;

        expect(chain.primary.id, AiEngineSelection.claudeCodeCliId);
        expect(chain.fallback?.id, AiEngineSelection.claudeApiId);
        expect(built, isNot(contains('copilot-cli')));
      },
    );

    test('S07-UT-01: (claudeCode, non-Windows) is the Claude API', () {
      final List<String> built = <String>[];
      final FallbackAiEngine chain =
          resolveWith(
                pref: EnginePref.claudeCodeCli,
                isWindows: false,
                built: built,
              )
              as FallbackAiEngine;

      expect(chain.primary.id, AiEngineSelection.claudeApiId);
      expect(built, isNot(contains('claude-code-cli')));
    });

    test('S07-UT-01: the preference survives a platform that cannot honour it', () {
      // Selection reads; it does not correct. A user who chose Copilot at their
      // desk and opened Norte on a phone still has Copilot chosen when they get
      // back to the desk.
      const AiEngineSettings settings = AiEngineSettings(
        engine: EnginePref.copilotCli,
      );
      AiEngineSelection.resolve(
        settings: settings,
        isWindows: false,
        claudeApi: () => _SpyEngine(name: 'claude-api'),
        copilotCli: () => _SpyEngine(name: 'copilot-cli'),
        claudeCodeCli: () => _SpyEngine(name: 'claude-code-cli'),
      );
      expect(settings.engine, EnginePref.copilotCli);
    });
  });

  group('S07-UT-02: the fallback chain (BR-10)', () {
    late _SpyEngine primary;
    late _SpyEngine fallback;
    late List<String> log;
    late FakeAiEngineSettingsStore usage;

    setUp(() {
      primary = _SpyEngine(name: 'primary');
      fallback = _SpyEngine(name: 'fallback');
      log = <String>[];
      usage = FakeAiEngineSettingsStore();
    });

    FallbackAiEngine chain({bool fallbackEnabled = true}) => FallbackAiEngine(
      primary: named('primary', primary),
      fallback: named('fallback', fallback),
      fallbackEnabled: fallbackEnabled,
      usage: usage,
      log: log.add,
    );

    test(
      'S07-UT-02 A: primary fails once, works on retry, fallback untouched',
      () async {
        primary.failures = 1;

        final VoiceIntent intent = await chain().parseIntent('cria', context);

        expect(intent.slots['title'], 'from primary');
        expect(primary.calls, 2);
        expect(fallback.calls, 0);
        expect(usage.recorded, <String>['primary']);
      },
    );

    test(
      'S07-UT-02 B: primary fails twice, the fallback answers and the switch is logged',
      () async {
        primary.failures = 2;

        final VoiceIntent intent = await chain().parseIntent('cria', context);

        expect(intent.slots['title'], 'from fallback');
        expect(primary.calls, 2);
        expect(fallback.calls, 1);
        // The counter follows the engine that *answered*, which is the only way
        // a user can discover that the one they chose is not replying.
        expect(usage.recorded, <String>['fallback']);
        // The switch, and its reason. The sprint's validation rule asks for both.
        final String switched = log.firstWhere(
          (String line) => line.contains('switching'),
          orElse: () => '',
        );
        expect(switched, contains('primary → fallback'));
        expect(switched, contains('EngineFailure'));
      },
    );

    test(
      'S07-UT-02 C: both fail, and the error names what was tried',
      () async {
        primary.failures = 99;
        fallback.failures = 99;

        await expectLater(
          chain().parseIntent('cria', context),
          throwsA(
            isA<AiUnavailableFailure>().having(
              (AiUnavailableFailure f) => f.tried,
              'tried',
              <String>['primary', 'fallback'],
            ),
          ),
        );
        expect(primary.calls, 2);
        expect(fallback.calls, 1);
        expect(usage.recorded, isEmpty);
      },
    );

    test('S07-UT-02 D: with the fallback off it is never touched', () async {
      primary.failures = 99;

      await expectLater(
        chain(fallbackEnabled: false).parseIntent('cria', context),
        throwsA(isA<AiUnavailableFailure>()),
      );

      expect(primary.calls, 2);
      // Stronger than "did not answer": an engine that is asked and fails has
      // still spent the user's money and their time.
      expect(fallback.calls, 0);
      expect(
        log.any((String line) => line.contains('disabled by the user')),
        isTrue,
      );
    });

    test(
      'S07-UT-02: the retry is unconditional, even for a settled failure',
      () async {
        // BR-10 says *exact sequence*. Skipping the retry for a failure that
        // cannot change is a tempting optimisation and was removed for that
        // reason — a rule that says "exact" stops meaning anything the first time
        // an implementation decides it knows better.
        primary
          ..failures = 99
          ..failWith = const MissingApiKeyFailure();

        final VoiceIntent intent = await chain().parseIntent('cria', context);

        // A missing key is the clearest possible "settled" failure — it cannot
        // become present between two calls a millisecond apart — and it is still
        // attempted twice before the chain moves on.
        expect(primary.calls, 2);
        expect(intent.slots['title'], 'from fallback');
      },
    );

    test(
      'S07-UT-02: a chain with no fallback still retries, then reports honestly',
      () async {
        primary.failures = 99;
        final FallbackAiEngine solo = FallbackAiEngine(
          primary: named('primary', primary),
          fallback: null,
          fallbackEnabled: true,
          log: log.add,
        );

        await expectLater(
          solo.parseIntent('cria', context),
          throwsA(
            isA<AiUnavailableFailure>().having(
              (AiUnavailableFailure f) => f.tried,
              'tried',
              <String>['primary'],
            ),
          ),
        );
        expect(primary.calls, 2);
        expect(
          log.any((String line) => line.contains('none configured')),
          isTrue,
        );
      },
    );

    test(
      'S07-UT-02: summarize goes through the same chain as parseIntent',
      () async {
        primary.failures = 2;

        final MeetingSummary summary = await chain().summarize(
          'a transcript',
          retroTemplate,
        );

        // One policy, both operations. A chain that only covered the voice path
        // would leave meeting summaries with no fallback at all.
        expect(summary.engineId, 'fallback');
        expect(usage.recorded, <String>['fallback']);
      },
    );

    test(
      'S07-UT-02: a usage counter that cannot save does not fail the answer',
      () async {
        usage.failWith = const StorageFailure('disk full');

        final VoiceIntent intent = await chain().parseIntent('cria', context);

        // The counter is a diagnostic. Turning a summary the user is waiting for
        // into an error because a count could not be written is the wrong trade.
        expect(intent.slots['title'], 'from primary');
      },
    );
  });
}
