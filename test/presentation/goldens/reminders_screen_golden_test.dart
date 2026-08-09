import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/reminder.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/reminders/reminder_capture.dart';
import 'package:norte/presentation/reminders/reminder_providers.dart';
import 'package:norte/presentation/reminders/reminders_screen.dart';
import 'package:norte/presentation/reminders/widgets/push_to_talk_bar.dart';
import 'package:norte/presentation/shared/theme/norte_colors.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/shared/widgets/empty_state.dart';
import 'package:norte/presentation/shared/widgets/error_state.dart';
import 'package:norte/presentation/shared/widgets/loading_skeleton.dart';
import 'package:norte/presentation/shared/widgets/norte_card.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

import '../../fakes/fakes.dart';
import '../../support/platform_goldens.dart';
import '../../support/test_fonts.dart';

/// The clock every reminder fixture is placed around — `FakeClock.fixed()`,
/// so the goldens do not move.
final DateTime _now = DateTime.utc(2026, 1, 1, 9);

/// Two upcoming and one past, which is what makes both section headers and
/// both text colours appear in a single frame.
final List<Reminder> goldenReminders = <Reminder>[
  Reminder(
    id: 'reminder-1',
    text: 'responder o e-mail do cliente',
    triggerAt: _now.add(const Duration(minutes: 20)),
    createdAt: _now,
  ),
  Reminder(
    id: 'reminder-2',
    text: 'revisar o PR do conector',
    triggerAt: _now.add(const Duration(days: 1)),
    createdAt: _now,
  ),
  Reminder(
    id: 'reminder-3',
    text: 'ligar para a Samara',
    triggerAt: _now.subtract(const Duration(hours: 2)),
    createdAt: _now.subtract(const Duration(days: 1)),
    isFired: true,
  ),
];

/// S06-GT-01 — the reminders screen in its four states plus push-to-talk,
/// dark and light, mobile and desktop.
void main() {
  setUpAll(() async {
    usePlatformGoldens();
    await loadNorteFonts();
  });

  const Size mobile = Size(390, 844);
  const Size desktop = Size(1280, 800);

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];
  final List<(String, Size)> viewports = <(String, Size)>[
    ('mobile', mobile),
    ('desktop', desktop),
  ];

  /// Renders the real screen with the repository — and, for the recording
  /// state, the capture notifier — replaced at the same override points the
  /// composition root uses.
  Future<void> pump(
    WidgetTester tester, {
    required ThemeData theme,
    required Size size,
    required FakeReminderRepository repository,
    ReminderCaptureState? capture,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          reminderRepositoryProvider.overrideWithValue(repository),
          notificationSchedulerProvider.overrideWithValue(
            FakeNotificationScheduler(),
          ),
          clockProvider.overrideWithValue(FakeClock.fixed()),
          if (capture != null)
            reminderCaptureProvider.overrideWith(() => _FrozenCapture(capture)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RemindersScreen()),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  for (final (String themeName, ThemeData theme) in themes) {
    for (final (String sizeName, Size size) in viewports) {
      final String suffix = '${sizeName}_$themeName';

      testWidgets('S06-GT-01: reminders — content ($suffix)', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeReminderRepository(goldenReminders),
        );

        expect(find.byType(NorteCard), findsNWidgets(goldenReminders.length));
        // Both sections, which is what the past/upcoming split is for.
        expect(find.text('Upcoming'), findsOneWidget);
        expect(find.text('Past'), findsOneWidget);
        await expectLater(
          find.byType(RemindersScreen),
          matchesGoldenFile('images/reminders_content_$suffix.png'),
        );
      });

      testWidgets('S06-GT-01: reminders — empty ($suffix)', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeReminderRepository(),
        );

        expect(find.byType(EmptyState), findsOneWidget);
        await expectLater(
          find.byType(RemindersScreen),
          matchesGoldenFile('images/reminders_empty_$suffix.png'),
        );
      });

      testWidgets('S06-GT-01: reminders — error ($suffix)', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeReminderRepository.failing(),
        );

        expect(find.byType(ErrorState), findsOneWidget);
        await expectLater(
          find.byType(RemindersScreen),
          matchesGoldenFile('images/reminders_error_$suffix.png'),
        );
      });

      testWidgets('S06-GT-01: reminders — loading ($suffix)', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeReminderRepository.pending(),
          settle: false,
        );

        expect(find.byType(LoadingSkeletonList), findsOneWidget);
        await expectLater(
          find.byType(RemindersScreen),
          matchesGoldenFile('images/reminders_loading_$suffix.png'),
        );
      });

      testWidgets('S06-GT-01: reminders — recording with countdown ($suffix)', (
        WidgetTester tester,
      ) async {
        // Seven seconds in, mid-sentence: the state a user actually sees, and
        // the one where the 15s limit has to be visible rather than implied.
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeReminderRepository(goldenReminders),
          capture: const ReminderCaptureState(
            isCapturing: true,
            secondsLeft: 8,
            partial: 'me lembra em vinte minutos de',
          ),
        );

        expect(find.byType(PushToTalkBar), findsOneWidget);
        expect(find.text('8s left'), findsOneWidget);
        await expectLater(
          find.byType(RemindersScreen),
          matchesGoldenFile('images/reminders_recording_$suffix.png'),
        );
      });
    }
  }

  testWidgets('S06-GT-01: a past reminder is drawn muted, an upcoming one is '
      'not', (WidgetTester tester) async {
    // The golden files carry this, but a pixel difference is not a reason —
    // this says *why* the two rows differ, so a future change that dims both
    // fails with a sentence instead of a diff.
    await pump(
      tester,
      theme: NorteTheme.dark,
      size: mobile,
      repository: FakeReminderRepository(goldenReminders),
    );

    final TextStyle upcoming = tester
        .widget<Text>(find.text('responder o e-mail do cliente'))
        .style!;
    final TextStyle past = tester
        .widget<Text>(find.text('ligar para a Samara'))
        .style!;

    expect(past.color, isNot(upcoming.color));
    expect(past.color, NorteTheme.dark.extension<NorteColors>()!.textMuted);
  });
}

/// A [ReminderCapture] frozen in one state, so the recording golden does not
/// need a microphone.
class _FrozenCapture extends ReminderCapture {
  _FrozenCapture(this._state);

  final ReminderCaptureState _state;

  @override
  ReminderCaptureState build() => _state;
}
