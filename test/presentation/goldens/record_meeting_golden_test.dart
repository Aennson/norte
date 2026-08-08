import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/transcribe_meeting_audio.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/meetings/meeting_recorder_providers.dart';
import 'package:norte/presentation/meetings/record_meeting_screen.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';

import '../../support/platform_goldens.dart';
import '../../support/test_fonts.dart';

/// Pins [MeetingRecorderState] to whatever the golden is about.
///
/// The screen renders from one immutable state object, so the goldens can be
/// driven by substituting it rather than by racing a real recorder to the
/// right millisecond. That is what makes them stable: a timer that ticked
/// during `pumpAndSettle` would produce a different image every run.
class _PinnedRecorder extends MeetingRecorder {
  _PinnedRecorder(this._state);

  final MeetingRecorderState _state;

  @override
  MeetingRecorderState build() => _state;
}

/// S04-GT-01 — the recording screen, dark and light.
///
/// The states worth pinning are the ones a user is looking at while something
/// irreversible is happening: a live recording they believe is capturing, a
/// pipeline they are waiting on, and a failure that has to say the audio
/// survived. A change that quietly stopped saying so would pass every other
/// test in the suite.
void main() {
  setUpAll(() async {
    usePlatformGoldens();
    await loadNorteFonts();
  });

  const Size desktop = Size(1000, 900);

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required ThemeData theme,
    required MeetingRecorderState state,
  }) async {
    await tester.binding.setSurfaceSize(desktop);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          meetingRecorderProvider.overrideWith(() => _PinnedRecorder(state)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RecordMeetingScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }

  final Map<String, MeetingRecorderState> states =
      <String, MeetingRecorderState>{
        'idle': const MeetingRecorderState(),
        'recording': const MeetingRecorderState(
          status: MeetingRecorderStatus.recording,
          elapsed: Duration(minutes: 12, seconds: 34),
          level: 0.65,
        ),
        'paused': const MeetingRecorderState(
          status: MeetingRecorderStatus.paused,
          elapsed: Duration(minutes: 12, seconds: 34),
        ),
        'recorded': const MeetingRecorderState(
          status: MeetingRecorderStatus.recorded,
          elapsed: Duration(minutes: 41, seconds: 8),
          audioPath: '/tmp/norte_recordings/meeting_1.m4a',
        ),
        'uploading': const MeetingRecorderState(
          status: MeetingRecorderStatus.processing,
          stage: TranscriptionStage.uploading,
          audioPath: '/tmp/norte_recordings/meeting_1.m4a',
        ),
        'transcribing': const MeetingRecorderState(
          status: MeetingRecorderStatus.processing,
          stage: TranscriptionStage.transcribing,
          audioPath: '/tmp/norte_recordings/meeting_1.m4a',
        ),
        // The failure state carries `audioPath`, which is the assertion the
        // image is really making: the retry button and the "recording kept"
        // line are both conditional on it.
        'failed': const MeetingRecorderState(
          status: MeetingRecorderStatus.failed,
          failure: TranscriptionFailure(),
          audioPath: '/tmp/norte_recordings/meeting_1.m4a',
        ),
        'permission': const MeetingRecorderState(
          status: MeetingRecorderStatus.permissionDenied,
        ),
        // Permanently denied drops the "allow" button, because tapping it
        // would produce no prompt.
        'permission_permanent': const MeetingRecorderState(
          status: MeetingRecorderStatus.permissionDenied,
          isPermanentlyDenied: true,
        ),
        'interrupted': const MeetingRecorderState(
          status: MeetingRecorderStatus.paused,
          elapsed: Duration(minutes: 7, seconds: 2),
          wasInterrupted: true,
        ),
      };

  for (final (String themeName, ThemeData theme) in themes) {
    for (final MapEntry<String, MeetingRecorderState> entry in states.entries) {
      testWidgets('S04-GT-01: record screen — ${entry.key} ($themeName)', (
        WidgetTester tester,
      ) async {
        await pump(tester, theme: theme, state: entry.value);

        await expectLater(
          find.byType(RecordMeetingScreen),
          matchesGoldenFile('images/record_${entry.key}_$themeName.png'),
        );
      });
    }
  }

  testWidgets('S04-GT-01: the timer is rendered in the mono font', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      theme: NorteTheme.dark,
      state: const MeetingRecorderState(
        status: MeetingRecorderStatus.recording,
        elapsed: Duration(minutes: 12, seconds: 34),
        level: 0.65,
      ),
    );

    final Text timer = tester.widget<Text>(
      find.byKey(RecordMeetingScreen.timerKey),
    );

    // The exit criterion, asserted rather than left to the eye: an image can
    // be regenerated around a font regression, a matcher cannot.
    expect(timer.style!.fontFamily, 'JetBrainsMono');
    expect(timer.data, '12:34');
  });

  testWidgets('S04-GT-01: past an hour the timer grows an hours field', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      theme: NorteTheme.dark,
      state: const MeetingRecorderState(
        status: MeetingRecorderStatus.recording,
        elapsed: Duration(hours: 1, minutes: 5, seconds: 9),
      ),
    );

    expect(
      tester.widget<Text>(find.byKey(RecordMeetingScreen.timerKey)).data,
      '1:05:09',
    );
  });
}
