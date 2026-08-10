import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/reminder.dart';
import 'package:norte/domain/ports/notification_scheduler.dart';
import 'package:norte/domain/ports/time_zone.dart';
import 'package:norte/infrastructure/persistence/drift_reminder_repository.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/drift_voice_settings_store.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/app/norte_router.dart';
import 'package:norte/presentation/meetings/meeting_providers.dart';
import 'package:norte/presentation/reminders/reminder_detail_screen.dart';
import 'package:norte/presentation/reminders/reminder_providers.dart';
import 'package:norte/presentation/reminders/reminders_screen.dart';
import 'package:norte/presentation/reminders/widgets/push_to_talk_bar.dart';
import 'package:norte/presentation/tasks/task_providers.dart';
import 'package:norte/presentation/voice/voice_providers.dart';

import '../test/fakes/fake_ai_engine.dart';
import '../test/fakes/fake_clock.dart';
import '../test/fakes/fake_microphone.dart';
import '../test/fakes/fake_notification_scheduler.dart';
import '../test/fakes/fake_realtime_transcription.dart';

/// S06-E2E-01 and S06-E2E-02 — Pillar 5, through the real UI.
///
/// The real composition root with the microphone, the realtime engine, the AI
/// engine and the notification platform replaced
/// (`docs/testing-strategy.md` §4.2). The database, the router, the screens
/// and every use case are the app's own — which is what makes the deep link
/// below a real `go_router` navigation rather than a `setState`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 2026-08-08, 14:00 in São Paulo. The zone is pinned so "15:00" means the
  /// same thing on the Developer's machine and on `ubuntu-latest`.
  final DateTime t0 = DateTime.utc(2026, 8, 8, 17);
  const TimeZone saoPaulo = FixedOffsetTimeZone(
    'America/Sao_Paulo',
    Duration(hours: -3),
  );

  late NorteDatabase database;
  late DriftReminderRepository reminders;
  late DriftTaskRepository tasks;
  late DriftVoiceSettingsStore voiceSettings;
  late FakeAiEngine ai;
  late FakeRealtimeTranscription realtime;
  late FakeMicrophone microphone;
  late FakeNotificationScheduler scheduler;

  setUp(() async {
    database = openInMemoryNorteDatabase();
    reminders = DriftReminderRepository(database);
    tasks = DriftTaskRepository(database);
    voiceSettings = DriftVoiceSettingsStore(database);

    ai = FakeAiEngine(generatedAt: t0);
    realtime = FakeRealtimeTranscription()..autoplay = false;
    microphone = FakeMicrophone();
    scheduler = FakeNotificationScheduler();
  });

  tearDown(() async {
    await realtime.stop();
    await database.close();
  });

  Future<void> bootApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          taskRepositoryProvider.overrideWithValue(tasks),
          reminderRepositoryProvider.overrideWithValue(reminders),
          notificationSchedulerProvider.overrideWithValue(scheduler),
          timeZoneProvider.overrideWithValue(saoPaulo),
          aiEngineProvider.overrideWithValue(ai),
          microphoneProvider.overrideWithValue(microphone),
          realtimeTranscriptionProvider.overrideWithValue(realtime),
          voiceSettingsStoreProvider.overrideWithValue(voiceSettings),
          clockProvider.overrideWithValue(FakeClock(t0)),
        ],
        child: NorteApp(
          router: buildNorteRouter(initialLocation: NorteRoutes.reminders),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Presses push-to-talk and lets the capture open.
  Future<void> pressToTalk(WidgetTester tester) async {
    await tester.tap(find.byKey(PushToTalkBar.recordKey));
    await tester.pumpAndSettle();
  }

  group('S06-E2E-01: "me lembra às três da tarde de responder o e-mail"', () {
    const String utterance = 'me lembra às três da tarde de responder o e-mail';

    void scriptReminder() {
      ai.alwaysParseAs(
        '{"intent":"createReminder","slots":{"text":"responder o e-mail",'
        '"triggerAt":"today 15:00"},"confidence":0.9}',
      );
    }

    testWidgets(
      'S06-E2E-01: the spoken reminder is listed for 15:00, the notification '
      'deep-links to it, and it then reads as past',
      (WidgetTester tester) async {
        scriptReminder();
        await bootApp(tester);

        expect(find.byType(RemindersScreen), findsOneWidget);
        expect(await reminders.listAll(), isEmpty);

        await pressToTalk(tester);
        expect(microphone.opens, 1);

        realtime.emitPartial('me lembra às três');
        await tester.pumpAndSettle();
        realtime.emitCommitted(utterance);
        await tester.pumpAndSettle();

        // Confidence 0.9, a local mutating intent — it executes directly, with
        // no confirmation (BR-04).
        final List<Reminder> stored = await reminders.listAll();
        expect(stored.length, 1);
        final Reminder reminder = stored.single;
        expect(reminder.text, 'responder o e-mail');
        // 15:00 in São Paulo is 18:00 UTC, one hour after `t0`.
        expect(reminder.triggerAt, DateTime.utc(2026, 8, 8, 18));

        // Push-to-talk, not a session: the microphone closed when the sentence
        // did.
        expect(microphone.closes, greaterThan(0));

        // The list shows it as upcoming.
        await tester.pumpAndSettle();
        expect(find.text('responder o e-mail'), findsOneWidget);
        expect(find.text('Upcoming'), findsOneWidget);
        expect(find.text('Past'), findsNothing);

        // The platform was asked, under the row's own id.
        final ScheduledNotification? scheduled =
            scheduler.scheduled[reminder.id];
        expect(scheduled, isNotNull);
        expect(scheduled!.triggerAt, reminder.triggerAt);
        // Localized before it left the app (BR-11) — English, per the locale
        // this test boots in.
        expect(scheduled.title, 'Reminder');

        // "Fire" it by hand, as the platform would, and let the tap through.
        final ScheduledNotification fired = scheduler.fire(reminder.id)!;
        expect(fired.id, reminder.id);

        // The platform's tap callback, exactly as the composition root wires
        // it: the scheduler posts the id and the app navigates.
        ProviderScope.containerOf(
          tester.element(find.byType(RemindersScreen)),
          listen: false,
        ).read(reminderDeepLinkProvider.notifier).open(reminder.id);
        await tester.pumpAndSettle();

        // The deep link landed on the reminder's own screen.
        expect(find.byType(ReminderDetailScreen), findsOneWidget);
        expect(find.text('responder o e-mail'), findsOneWidget);
        // …and it is the reminder's own screen, not the list scrolled to it:
        // the detail screen carries the cancel action for a future reminder.
        expect(find.byKey(const Key('reminder-detail-cancel')), findsOneWidget);
      },
    );

    testWidgets(
      'S06-E2E-01: once its time has passed the reminder moves to Past',
      (WidgetTester tester) async {
        // The second half of S06-E2E-01, as its own case: what makes a
        // reminder "past" is the clock, and a single test cannot hold two
        // clocks. Seeded rather than spoken, because the speaking half is
        // asserted above and this half is about the reading.
        await reminders.save(
          Reminder(
            id: 'reminder-past',
            text: 'responder o e-mail',
            triggerAt: t0.subtract(const Duration(minutes: 30)),
            createdAt: t0.subtract(const Duration(hours: 2)),
            isFired: true,
          ),
        );

        await bootApp(tester);

        expect(find.text('Past'), findsOneWidget);
        expect(find.text('Upcoming'), findsNothing);
        expect(find.text('Delivered'), findsOneWidget);
      },
    );
  });

  group('S06-E2E-02: the missing time slot', () {
    testWidgets(
      'S06-E2E-02: the app asks for when, and nothing is stored until it is '
      'answered',
      (WidgetTester tester) async {
        ai.alwaysParseAs(
          '{"intent":"createReminder","slots":{"text":"pagar a conta",'
          '"triggerAt":null},"confidence":0.9}',
        );
        await bootApp(tester);

        await pressToTalk(tester);
        realtime.emitCommitted('me lembra de pagar a conta');
        await tester.pumpAndSettle();

        // The question is on screen, and it asks about the **time alone**.
        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(RemindersScreen)),
        );
        expect(find.text(l10n.voiceAskTriggerAt), findsOneWidget);

        // **Nothing has been persisted.** A reminder saved without a time is
        // one that never fires, which is worse than no reminder at all.
        expect(await reminders.listAll(), isEmpty);
        expect(scheduler.scheduled, isEmpty);

        // Answering completes the slot, and only then is it stored. The time
        // is **chosen, never typed**: the grammar `TriggerTime` reads is what
        // the model emits after hearing speech, not something a person should
        // have to learn — the first version of this sheet asked for it as free
        // text and the Developer met a field hinting a phrase it refused.
        await tester.tap(find.byKey(const Key('reminder-time.+20m')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reminder-answer-time-button')));
        await tester.pumpAndSettle();

        final List<Reminder> stored = await reminders.listAll();
        expect(stored.length, 1);
        expect(stored.single.text, 'pagar a conta');
        expect(stored.single.triggerAt, t0.add(const Duration(minutes: 20)));
        expect(scheduler.scheduled[stored.single.id], isNotNull);
      },
    );

    testWidgets(
      'S06-E2E-02: the typed fallback creates a reminder without a microphone',
      (WidgetTester tester) async {
        await bootApp(tester);

        await tester.tap(find.byKey(const Key('reminder-type-instead')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reminder-text-field')),
          'levar o carro na revisão',
        );
        await tester.tap(find.byKey(const Key('reminder-time.tomorrow')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reminder-create-button')));
        await tester.pumpAndSettle();

        final List<Reminder> stored = await reminders.listAll();
        expect(stored.single.text, 'levar o carro na revisão');
        // 09:00 the next day in São Paulo — 12:00 UTC.
        expect(stored.single.triggerAt, DateTime.utc(2026, 8, 9, 12));
        expect(microphone.opens, 0, reason: 'no microphone was involved');
      },
    );
  });
}
