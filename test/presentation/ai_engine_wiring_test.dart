import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:norte/application/ai/ai_engine_selection.dart';
import 'package:norte/domain/entities/ai_engine_settings.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_engine.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/meetings/meeting_labels.dart';
import 'package:norte/presentation/settings/ai_engine_providers.dart';
import 'package:norte/presentation/voice/voice_labels.dart';

import '../fakes/fakes.dart';

/// The wiring between the engine preference, the chain and what the user reads.
///
/// Two defects live here, both found by S07-E2E-01 and S07-E2E-02 and both
/// fixed in Sprint 07. The E2E suites are the ones that describe the user's
/// journey; these are the regression tests that will still fail loudly if
/// either fix is undone, and unlike the E2E suites they run in the ordinary
/// `flutter test` pass rather than only on the desktop host.
void main() {
  group('the engine preference takes effect on the first request', () {
    /// Capabilities that exist only to be told apart.
    ///
    /// `FallbackAiEngine.capabilities` delegates to its primary, so a distinct
    /// `maxTokens` per fake is enough to read off which engine the chain put
    /// first — without calling either one, and therefore without the answer
    /// depending on what they would have said.
    const AiCapabilities remoteMarker = AiCapabilities(
      isLocal: false,
      supportsStreaming: true,
      supportsPromptCache: true,
      maxTokens: 8192,
    );
    const AiCapabilities copilotMarker = AiCapabilities(
      isLocal: false,
      supportsStreaming: false,
      supportsPromptCache: false,
      maxTokens: 4242,
    );

    /// A container wired the way the composition root wires one.
    ///
    /// The CLI builders hand back plain fakes rather than real `CliAiEngine`s:
    /// what is under test is which engine the chain *chose*, and a real one
    /// would drag a subprocess seam into a question that has nothing to do
    /// with subprocesses.
    ProviderContainer containerFor(AiEngineSettings settings) {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          isWindowsProvider.overrideWithValue(true),
          aiEngineSettingsStoreProvider.overrideWithValue(
            FakeAiEngineSettingsStore(settings),
          ),
          remoteAiEngineProvider.overrideWithValue(
            FakeAiEngine(capabilities: remoteMarker),
          ),
          copilotCliBuilderProvider.overrideWithValue(
            (String? _) => FakeAiEngine(capabilities: copilotMarker),
          ),
          claudeCodeCliBuilderProvider.overrideWithValue(
            (String? _) => FakeAiEngine(capabilities: copilotMarker),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('read cold, the chain is built from the defaults — the defect', () {
      // **The bug, stated as a test.** A Riverpod provider is lazy: nothing
      // reads `aiEngineSettingsProvider` until something reads
      // `aiEngineProvider`, and that read returns the defaults synchronously.
      // Left alone, the first summary of every session went to the remote
      // engine no matter what the user had chosen, the usage counter credited
      // an engine they had not picked, and nothing anywhere reported a
      // problem. S07-E2E-01 is what found it.
      final ProviderContainer container = containerFor(
        const AiEngineSettings(engine: EnginePref.copilotCli),
      );

      expect(
        container.read(aiEngineProvider).capabilities,
        remoteMarker,
        reason: 'a cold read cannot know the preference yet',
      );
    });

    testWidgets('rendering the app closes that window before a user can act', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = containerFor(
        const AiEngineSettings(engine: EnginePref.copilotCli),
      );

      // The real widget, in the real place. If `_AiEngineWarmUp` is deleted
      // from `NorteApp`, this test fails — which is the only thing that makes
      // the fix durable, since nothing else in the app looks at it.
      //
      // A one-route router, because what is being rendered is the app's
      // builder chain and not any screen: the production router would need the
      // whole repository graph to answer a question about a preference.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: NorteApp(
            router: GoRouter(
              routes: <RouteBase>[
                GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(aiEngineProvider).capabilities,
        copilotMarker,
        reason: 'the app should have read the preference by its first frame',
      );
    });

    testWidgets('a preference the platform cannot honour is still not used', (
      WidgetTester tester,
    ) async {
      // The warm-up must not turn into "always trust the preference". On a
      // phone the CLI engine is unreachable, and `AiEngineSelection` is what
      // says so — warmed or not (S07-UT-01).
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          isWindowsProvider.overrideWithValue(false),
          aiEngineSettingsStoreProvider.overrideWithValue(
            FakeAiEngineSettingsStore(
              const AiEngineSettings(engine: EnginePref.copilotCli),
            ),
          ),
          remoteAiEngineProvider.overrideWithValue(
            FakeAiEngine(capabilities: remoteMarker),
          ),
          copilotCliBuilderProvider.overrideWithValue(
            (String? _) => FakeAiEngine(capabilities: copilotMarker),
          ),
          claudeCodeCliBuilderProvider.overrideWithValue(
            (String? _) => FakeAiEngine(capabilities: copilotMarker),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: NorteApp(
            router: GoRouter(
              routes: <RouteBase>[
                GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(aiEngineProvider).capabilities, remoteMarker);
      // And the preference itself is untouched — a desktop choice survives a
      // session on a phone.
      expect(
        container.read(aiEngineSettingsProvider).valueOrNull?.engine,
        EnginePref.copilotCli,
      );
    });
  });

  group('the CLI failures reach the user as something they can act on', () {
    late AppLocalizations l10n;

    setUpAll(
      () async =>
          l10n = await AppLocalizations.delegate.load(const Locale('en')),
    );

    test('a chain that ran out of engines names Settings', () {
      const AiUnavailableFailure failure = AiUnavailableFailure(
        'No AI engine could answer. Tried GitHub Copilot CLI and Claude API.',
        tried: <String>[
          AiEngineSelection.copilotCliId,
          AiEngineSelection.claudeApiId,
        ],
      );

      // Until Sprint 07 wired the key, this fell through to "Summarizing
      // failed. Try again." — advice that cannot work, because by the time
      // this failure is raised the app has already tried everything it has.
      expect(meetingFailureText(l10n, failure), l10n.aiErrorEngineUnavailable);
      expect(meetingFailureText(l10n, failure), isNot(l10n.aiErrorGeneric));
      expect(voiceFailureText(l10n, failure), l10n.aiErrorEngineUnavailable);
    });

    test('a CLI that would not start says so', () {
      const AiProcessFailure failure = AiProcessFailure(
        'GitHub Copilot CLI could not be started — is it installed?',
      );

      expect(meetingFailureText(l10n, failure), l10n.aiErrorEngineNotInstalled);
      expect(voiceFailureText(l10n, failure), l10n.aiErrorEngineNotInstalled);
    });

    test('the watchdog reads differently from a network timeout', () {
      const AiTimeoutFailure watchdog = AiTimeoutFailure('stopped at 30s');

      expect(meetingFailureText(l10n, watchdog), l10n.aiErrorEngineTooSlow);
      // Distinct from the remote engine's timeout on purpose: the app ended
      // this one itself, and saying so is what makes the suggested retry sound
      // reasonable rather than hopeful.
      expect(
        meetingFailureText(l10n, watchdog),
        isNot(meetingFailureText(l10n, const TimeoutFailure())),
      );
      expect(voiceFailureText(l10n, watchdog), l10n.aiErrorEngineTooSlow);
    });

    test('none of the three is still falling through to the generic text', () {
      // One assertion covering the whole class of regression: adding a failure
      // to the domain and forgetting the label is the mistake this catches.
      for (final Failure failure in <Failure>[
        const AiUnavailableFailure('x', tried: <String>[]),
        const AiProcessFailure('x'),
        const AiTimeoutFailure('x'),
      ]) {
        expect(
          meetingFailureText(l10n, failure),
          isNot(l10n.aiErrorGeneric),
          reason: '${failure.runtimeType}',
        );
        expect(
          voiceFailureText(l10n, failure),
          isNot(l10n.aiErrorGeneric),
          reason: '${failure.runtimeType}',
        );
      }
    });
  });
}
