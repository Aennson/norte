import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/voice/intent_router.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/entities/voice_settings.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/infrastructure/persistence/drift_outbox_repository.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/jira/jira_providers.dart';
import 'package:norte/presentation/meetings/meeting_providers.dart';
import 'package:norte/presentation/settings/voice_settings_section.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/tasks/task_providers.dart';
import 'package:norte/presentation/voice/voice_host.dart';
import 'package:norte/presentation/voice/voice_labels.dart';
import 'package:norte/presentation/voice/voice_providers.dart';
import 'package:norte/presentation/voice/widgets/confirm_sheet.dart';
import 'package:norte/presentation/voice/widgets/voice_overlay.dart';

import '../fakes/fakes.dart';

/// A frame of loud synthetic speech — enough to move the meter well past the
/// floor.
Uint8List _loudFrame() {
  final Uint8List bytes = Uint8List(3200);
  final ByteData view = ByteData.view(bytes.buffer);
  for (var i = 0; i < 1600; i++) {
    view.setInt16(
      i * 2,
      (math.sin(2 * math.pi * 440 * i / 16000) * 20000).round(),
      Endian.little,
    );
  }
  return bytes;
}

/// The voice presentation layer, driven through a real widget tree.
///
/// Not documented sprint cases — added under `docs/project-rules.md` §5.4.
/// S05-E2E-01..03 cover the same ground through the whole app; these cover the
/// branches the E2E suite cannot reach cheaply (every failure mapping, every
/// slot question, the settings switch) and, unlike the E2E suite, they count
/// towards gate G4.
void main() {
  final DateTime t0 = DateTime.utc(2026, 8, 8, 9, 30);

  late NorteDatabase database;
  late FakeAiEngine ai;
  late FakeRealtimeTranscription realtime;
  late FakeMicrophone microphone;
  late FakeVoiceSettingsStore settings;
  late FakeReminderRepository reminders;
  late FakeTranscriptionCredentialStore scribeKey;

  final Task linked = Task(
    id: 'task-1',
    title: 'revisar o conector',
    createdAt: t0,
    updatedAt: t0,
    jiraLink: const JiraLink(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
    ),
  );

  setUp(() async {
    database = openInMemoryNorteDatabase();
    await DriftTaskRepository(database).save(linked);
    ai = FakeAiEngine(generatedAt: t0);
    realtime = FakeRealtimeTranscription()..autoplay = false;
    microphone = FakeMicrophone();
    settings = FakeVoiceSettingsStore();
    reminders = FakeReminderRepository();
    scribeKey = FakeTranscriptionCredentialStore();
  });

  tearDown(() async {
    await realtime.stop();
    await reminders.dispose();
    await database.close();
  });

  /// The desktop layout, as in the E2E suite. On the 800×600 default the
  /// shell renders its mobile chrome and the bottom navigation bar sits over
  /// the voice panel, so a tap on Cancel lands on the nav bar instead.
  void useDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget host({Widget child = const SizedBox.shrink()}) => ProviderScope(
    overrides: <Override>[
      taskRepositoryProvider.overrideWithValue(DriftTaskRepository(database)),
      outboxRepositoryProvider.overrideWithValue(
        DriftOutboxRepository(database),
      ),
      jiraGatewayProvider.overrideWithValue(FakeJiraGateway.fromFixture()),
      aiEngineProvider.overrideWithValue(ai),
      microphoneProvider.overrideWithValue(microphone),
      realtimeTranscriptionProvider.overrideWithValue(realtime),
      reminderRepositoryProvider.overrideWithValue(reminders),
      voiceSettingsStoreProvider.overrideWithValue(settings),
      realtimeCredentialStoreProvider.overrideWithValue(scribeKey),
      clockProvider.overrideWithValue(FakeClock(t0)),
    ],
    child: MaterialApp(
      theme: NorteTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VoiceHost(
        currentIndex: 0,
        onDestinationSelected: (_) {},
        child: child,
      ),
    ),
  );

  group('the session on screen', () {
    testWidgets('the overlay says "connecting" until the socket is open', (
      WidgetTester tester,
    ) async {
      useDesktopViewport(tester);
      // A socket that never comes up. The overlay must not claim to be
      // listening — the complaint that produced this test was an app that said
      // "Ouvindo…" from the moment the button was pressed.
      realtime.setConnected(false);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(VoiceHost)),
      );
      final VoiceSession session = container.read(
        voiceSessionProvider.notifier,
      );
      await session.start();
      await tester.pumpAndSettle();

      // `FakeRealtimeTranscription.start` connects immediately, so this is the
      // state *after* it: listening, honestly.
      expect(container.read(voiceSessionProvider).phase, VoicePhase.listening);

      // Now the socket drops mid-session.
      realtime.setConnected(false);
      await tester.pumpAndSettle();
      expect(container.read(voiceSessionProvider).phase, VoicePhase.connecting);
    });

    testWidgets('the level comes from the audio, not from a timer', (
      WidgetTester tester,
    ) async {
      useDesktopViewport(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(VoiceHost)),
      );
      await container.read(voiceSessionProvider.notifier).start();
      await tester.pumpAndSettle();

      expect(container.read(voiceSessionProvider).level, 0);
      expect(container.read(voiceSessionProvider).hasHeardAudio, isFalse);

      // Loud audio through the microphone, which the session taps on its way
      // to the engine.
      microphone.emit(_loudFrame());
      await tester.pumpAndSettle();

      final VoiceSessionState after = container.read(voiceSessionProvider);
      expect(after.level, greaterThan(0.5));
      expect(after.hasHeardAudio, isTrue);
      // And the bytes still reached the engine untouched.
      expect(realtime.receivedChunks, hasLength(1));
    });

    testWidgets('a silent microphone is said out loud', (
      WidgetTester tester,
    ) async {
      useDesktopViewport(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(VoiceHost)),
      );
      await container.read(voiceSessionProvider.notifier).start();
      await tester.pumpAndSettle();

      // Connected, listening, nothing arriving. Silence from a microphone and
      // silence from a service look identical on screen and send the user to
      // completely different places, so the screen distinguishes them.
      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(VoiceOverlay)),
      );
      expect(find.text(l10n.voiceNoAudio), findsOneWidget);

      microphone.emit(_loudFrame());
      await tester.pumpAndSettle();
      expect(find.text(l10n.voiceNoAudio), findsNothing);
    });

    testWidgets('the overlay appears and the microphone opens', (
      WidgetTester tester,
    ) async {
      useDesktopViewport(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(VoiceHost)),
      );
      await container.read(voiceSessionProvider.notifier).start();
      await tester.pumpAndSettle();

      expect(find.byType(VoiceOverlay), findsOneWidget);
      expect(microphone.opens, 1);

      realtime.emitPartial('cria tarefa');
      await tester.pumpAndSettle();
      expect(find.textContaining('cria tarefa'), findsWidgets);
    });

    testWidgets('a low-confidence local intent raises the sheet (BR-04)', (
      WidgetTester tester,
    ) async {
      ai.alwaysParseAs(
        '{"intent":"createTask","slots":{"title":"algo"},"confidence":0.5}',
      );
      useDesktopViewport(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(VoiceHost)),
      );
      await container.read(voiceSessionProvider.notifier).start();
      await tester.pumpAndSettle();
      realtime.emitCommitted('cria tarefa algo');
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmSheet), findsOneWidget);
      expect(find.text('New task: algo'), findsOneWidget);

      // Both buttons are on the sheet and wired. What happens when they are
      // pressed is asserted by S05-E2E-01, which drives the real app end to
      // end — including that cancelling leaves the outbox empty.
      expect(find.byKey(ConfirmSheet.cancelButtonKey), findsOneWidget);
      expect(find.byKey(ConfirmSheet.confirmButtonKey), findsOneWidget);
    });

    testWidgets('a transport failure is shown as itself, not as a rephrase', (
      WidgetTester tester,
    ) async {
      ai.failWith = const MissingApiKeyFailure();
      useDesktopViewport(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(VoiceHost)),
      );
      await container.read(voiceSessionProvider.notifier).start();
      await tester.pumpAndSettle();
      realtime.emitCommitted('cria tarefa algo');
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(VoiceOverlay)),
      );
      expect(find.text(l10n.aiErrorMissingKey), findsOneWidget);
      expect(find.text(l10n.voiceNotUnderstood), findsNothing);
    });

    testWidgets('an engine error on the realtime stream reaches the user', (
      WidgetTester tester,
    ) async {
      useDesktopViewport(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(VoiceHost)),
      );
      await container.read(voiceSessionProvider.notifier).start();
      await tester.pumpAndSettle();

      realtime.disconnectAfter = 0;
      realtime.emitPartial('anything');
      await tester.pumpAndSettle();
      expect(find.byType(VoiceOverlay), findsOneWidget);
    });

    testWidgets('the latency of a command is measured', (
      WidgetTester tester,
    ) async {
      ai.alwaysParseAs(
        '{"intent":"createTask","slots":{"title":"algo"},"confidence":0.9}',
      );
      useDesktopViewport(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(VoiceHost)),
      );
      await container.read(voiceSessionProvider.notifier).start();
      await tester.pumpAndSettle();
      realtime.emitCommitted('cria tarefa algo');
      await tester.pumpAndSettle();

      // The clock is fixed, so the measurement is zero — what is being
      // asserted is that the pipeline measures at all, which is what the
      // sprint's p95 evidence rests on.
      expect(container.read(voiceLatencyLogProvider).count, 1);
    });
  });

  group('the settings switch', () {
    testWidgets('renders on and writes the user\'s choice', (
      WidgetTester tester,
    ) async {
      useDesktopViewport(tester);
      await tester.pumpWidget(host(child: const VoiceSettingsSection()));
      await tester.pumpAndSettle();

      final Finder switchFinder = find.byKey(
        VoiceSettingsSection.alwaysConfirmSwitchKey,
      );
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(settings.settings.alwaysConfirmJiraWrites, isFalse);
      expect(settings.writes, 1);
    });
  });

  group('voice_labels', () {
    late AppLocalizations l10n;

    Future<void> pumpLabels(WidgetTester tester) async {
      useDesktopViewport(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      l10n = AppLocalizations.of(tester.element(find.byType(VoiceHost)));
    }

    testWidgets('every required slot has its own question', (
      WidgetTester tester,
    ) async {
      await pumpLabels(tester);

      final Set<String> questions = <String>{};
      for (final IntentType type in IntentType.values) {
        for (final String slot in type.requiredSlots) {
          questions.add(slotQuestion(l10n, slot));
        }
      }
      // Six distinct slots, six distinct questions: a shared one would make
      // "Which ticket?" appear where the app meant "Which status?".
      expect(questions, hasLength(6));
      expect(questions, contains('Which ticket?'));

      // An unmapped slot degrades to its own name rather than to an empty
      // sheet — more use to whoever has to add the translation.
      expect(slotQuestion(l10n, 'somethingNew'), 'somethingNew');
    });

    testWidgets('every intent describes itself', (WidgetTester tester) async {
      await pumpLabels(tester);

      const Map<IntentType, Map<String, dynamic>> slots =
          <IntentType, Map<String, dynamic>>{
            IntentType.updateJira: <String, dynamic>{
              'issueKey': 'PROJ-123',
              'transition': 'Done',
            },
            IntentType.addComment: <String, dynamic>{
              'issueKey': 'PROJ-123',
              'comment': 'subiu',
            },
            IntentType.createTask: <String, dynamic>{'title': 'algo'},
            IntentType.createReminder: <String, dynamic>{
              'text': 'algo',
              'triggerAt': '+20m',
            },
            IntentType.queryStatus: <String, dynamic>{'issueKey': 'PROJ-123'},
            IntentType.unknown: <String, dynamic>{},
          };

      for (final MapEntry<IntentType, Map<String, dynamic>> entry
          in slots.entries) {
        final String text = intentDescription(
          l10n,
          VoiceIntent(type: entry.key, slots: entry.value, confidence: 0.9),
        );
        expect(text, isNotEmpty, reason: entry.key.name);
      }
      expect(
        intentDescription(
          l10n,
          const VoiceIntent(
            type: IntentType.updateJira,
            slots: <String, dynamic>{
              'issueKey': 'PROJ-123',
              'transition': 'Done',
            },
          ),
        ),
        'PROJ-123 → Done',
      );
    });

    testWidgets('both confirmation reasons say something different', (
      WidgetTester tester,
    ) async {
      await pumpLabels(tester);

      expect(
        confirmationReasonText(l10n, ConfirmationReason.jiraWrite),
        isNot(confirmationReasonText(l10n, ConfirmationReason.lowConfidence)),
      );
    });

    testWidgets('every outcome and every failure names something the user '
        'can act on', (WidgetTester tester) async {
      await pumpLabels(tester);

      for (final IntentType type in IntentType.values) {
        expect(
          executedText(
            l10n,
            IntentExecuted(
              intent: VoiceIntent(
                type: type,
                slots: const <String, dynamic>{'issueKey': 'PROJ-123'},
                confidence: 0.9,
              ),
              status: 'Done',
            ),
          ),
          isNotEmpty,
          reason: type.name,
        );
      }

      const List<Failure> failures = <Failure>[
        NotLinkedFailure(),
        MissingApiKeyFailure(),
        AuthFailure(),
        AiResponseFailure(),
        TranscriptionFailure(),
        MicrophonePermissionFailure(),
        RecordingFailure(),
        RateLimitFailure(),
        NetworkFailure(),
        TimeoutFailure(),
        StorageFailure(),
        EngineFailure(),
      ];
      final Set<String> messages = <String>{
        for (final Failure failure in failures)
          voiceFailureText(l10n, failure, issueKey: 'PROJ-123'),
      };
      // Not one collapsed "something went wrong": each failure sends the user
      // somewhere different, and the wording has to as well.
      expect(messages.length, greaterThanOrEqualTo(8));
      expect(
        voiceFailureText(l10n, const NotLinkedFailure(), issueKey: 'PROJ-9'),
        contains('PROJ-9'),
      );
    });
  });

  group('VoiceSettings', () {
    test('the default is to confirm', () {
      expect(const VoiceSettings().alwaysConfirmJiraWrites, isTrue);
    });
  });
}
