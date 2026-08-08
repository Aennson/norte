import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../application/usecases/transcribe_meeting_audio.dart';
import '../../domain/failures/failure.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_card.dart';
import '../shared/widgets/norte_screen.dart';
import 'meeting_labels.dart';
import 'meeting_providers.dart';
import 'meeting_recorder_providers.dart';
import 'summary_screen.dart';

/// Records a meeting and feeds it to the Sprint 03 pipeline
/// (`docs/architecture.md` §5.1 — the second input flow).
///
/// **A refused microphone is a screen, not an error.** There is nothing to
/// retry until the user changes something outside the app, so the screen
/// explains why the permission is wanted and offers the only two routes that
/// exist: ask again, or open the system settings when asking would no longer
/// prompt (S04-E2E-02).
///
/// **A failure keeps the recording.** The error is rendered in place with the
/// audio still on disk and a **Try again** button, because a user who has just
/// recorded an hour of meeting must not be asked to hold it again
/// (S04-UT-02).
class RecordMeetingScreen extends ConsumerStatefulWidget {
  const RecordMeetingScreen({super.key});

  /// Route path, nested under the meetings branch.
  static const String routePath = '/meetings/record';

  /// Keys the tests and the E2E suite drive this screen by.
  static const Key startKey = Key('record.start');
  static const Key pauseKey = Key('record.pause');
  static const Key resumeKey = Key('record.resume');
  static const Key stopKey = Key('record.stop');
  static const Key transcribeKey = Key('record.transcribe');
  static const Key discardKey = Key('record.discard');
  static const Key retryKey = Key('record.retry');
  static const Key timerKey = Key('record.timer');
  static const Key levelKey = Key('record.level');
  static const Key permissionAllowKey = Key('record.permission.allow');
  static const Key permissionSettingsKey = Key('record.permission.settings');

  @override
  ConsumerState<RecordMeetingScreen> createState() =>
      _RecordMeetingScreenState();
}

class _RecordMeetingScreenState extends ConsumerState<RecordMeetingScreen> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final MeetingRecorderState recorder = ref.watch(meetingRecorderProvider);

    // Leaving discards, exactly as the paste flow does (BR-03). Here it also
    // deletes the audio: an abandoned recording is a file the user believes
    // is gone.
    return PopScope<Object?>(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) return;
        final MeetingRecorder notifier = ref.read(
          meetingRecorderProvider.notifier,
        );
        if (recorder.hasAudio) {
          notifier.discard();
        } else {
          notifier.reset();
        }
      },
      child: NorteScreen(
        title: l10n.recordMeetingTitle,
        onBack: () => context.pop(),
        child: switch (recorder.status) {
          MeetingRecorderStatus.permissionDenied => _PermissionState(
            isPermanentlyDenied: recorder.isPermanentlyDenied,
          ),
          MeetingRecorderStatus.processing => _ProcessingState(
            stage: recorder.stage ?? TranscriptionStage.uploading,
          ),
          MeetingRecorderStatus.failed => _FailedState(
            failure: recorder.failure,
            hasAudio: recorder.hasAudio,
            onRetry: _transcribe,
            onDiscard: _discard,
          ),
          _ => _CaptureState(
            state: recorder,
            onStart: () => ref.read(meetingRecorderProvider.notifier).start(),
            onPause: () => ref.read(meetingRecorderProvider.notifier).pause(),
            onResume: () => ref.read(meetingRecorderProvider.notifier).resume(),
            onStop: () => ref.read(meetingRecorderProvider.notifier).stop(),
            onTranscribe: _transcribe,
            onDiscard: _discard,
          ),
        },
      ),
    );
  }

  Future<void> _transcribe() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final MeetingComposerState composer = ref.read(meetingComposerProvider);
    // The title the paste flow pre-fills from the template, produced the same
    // way so a pt-BR device never stores an English literal (BR-11).
    final String title = composer.template == null
        ? l10n.meetingTypeCustom
        : meetingTypeLabel(l10n, composer.template!.type);

    await ref.read(meetingRecorderProvider.notifier).transcribe(title: title);

    if (!mounted) return;
    if (ref.read(meetingRecorderProvider).status ==
        MeetingRecorderStatus.summarized) {
      await context.push(SummaryScreen.routePath);
    }
  }

  Future<void> _discard() =>
      ref.read(meetingRecorderProvider.notifier).discard();
}

/// Idle, recording, paused and recorded — the states in which the user is
/// holding a microphone rather than waiting on a service.
class _CaptureState extends StatelessWidget {
  const _CaptureState({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onTranscribe,
    required this.onDiscard,
  });

  final MeetingRecorderState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onTranscribe;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final bool isRecording = state.status == MeetingRecorderStatus.recording;
    final bool isPaused = state.status == MeetingRecorderStatus.paused;
    final bool isRecorded = state.status == MeetingRecorderStatus.recorded;

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        NorteCard(
          child: Column(
            children: <Widget>[
              _StatusLine(
                label: switch (state.status) {
                  MeetingRecorderStatus.recording =>
                    l10n.recordMeetingRecording,
                  MeetingRecorderStatus.paused => l10n.recordMeetingPaused,
                  _ => l10n.recordMeetingReady,
                },
                isLive: isRecording,
              ),
              const SizedBox(height: NorteSpacing.lg),
              Text(
                key: RecordMeetingScreen.timerKey,
                _format(state.elapsed),
                // Mono, because it is a measurement whose digits must not
                // shuffle sideways every time a 1 becomes an 8
                // (`docs/design-system.md` §3).
                style: NorteTypography.display.copyWith(
                  color: colors.textPrimary,
                  fontFamily: NorteTypography.mono.fontFamily,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: NorteSpacing.lg),
              _LevelMeter(level: state.level, isLive: isRecording),
            ],
          ),
        ),
        if (state.wasInterrupted) ...<Widget>[
          const SizedBox(height: NorteSpacing.lg),
          _Notice(
            icon: LucideIcons.pause,
            message: l10n.recordMeetingInterrupted,
            color: colors.textSecondary,
          ),
        ],
        const SizedBox(height: NorteSpacing.xl),
        if (isRecorded) ...<Widget>[
          NorteButton(
            key: RecordMeetingScreen.transcribeKey,
            label: l10n.recordMeetingStop,
            icon: LucideIcons.sparkles,
            onPressed: onTranscribe,
          ),
          const SizedBox(height: NorteSpacing.md),
          NorteButton(
            key: RecordMeetingScreen.discardKey,
            label: l10n.recordMeetingDiscard,
            variant: NorteButtonVariant.destructive,
            onPressed: onDiscard,
          ),
        ] else if (isRecording || isPaused) ...<Widget>[
          NorteButton(
            key: isPaused
                ? RecordMeetingScreen.resumeKey
                : RecordMeetingScreen.pauseKey,
            label: isPaused
                ? l10n.recordMeetingResume
                : l10n.recordMeetingPause,
            icon: isPaused ? LucideIcons.play : LucideIcons.pause,
            variant: NorteButtonVariant.secondary,
            onPressed: isPaused ? onResume : onPause,
          ),
          const SizedBox(height: NorteSpacing.md),
          NorteButton(
            key: RecordMeetingScreen.stopKey,
            label: l10n.recordMeetingStop,
            icon: LucideIcons.square,
            onPressed: onStop,
          ),
        ] else
          NorteButton(
            key: RecordMeetingScreen.startKey,
            label: l10n.recordMeetingStart,
            icon: LucideIcons.mic,
            onPressed: onStart,
          ),
      ],
    );
  }

  /// `mm:ss`, or `h:mm:ss` once a meeting has run past the hour.
  static String _format(Duration elapsed) {
    final int hours = elapsed.inHours;
    final String minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return hours == 0 ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }
}

/// The dot and the word beside it.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.isLive});

  final String label;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // `accent` while live, as the sprint's golden criterion requires;
            // a muted border colour otherwise, so the dot reads as off rather
            // than as a second kind of on.
            color: isLive ? colors.accent : colors.border,
          ),
        ),
        const SizedBox(width: NorteSpacing.sm),
        Text(
          label,
          style: NorteTypography.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

/// Twenty bars that fill with the input level.
///
/// Bars rather than a waveform: a waveform implies the audio is being drawn,
/// and this is a level meter reading one number. It answers exactly one
/// question — is the microphone hearing anything — which is the question a
/// person about to record an hour of meeting actually has.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level, required this.isLive});

  final double level;
  final bool isLive;

  static const int _bars = 20;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);
    final int lit = isLive ? (level.clamp(0.0, 1.0) * _bars).round() : 0;

    return Row(
      key: RecordMeetingScreen.levelKey,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < _bars; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: i < lit ? colors.accent : colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Uploading, transcribing, summarizing — with the stage named.
class _ProcessingState extends StatelessWidget {
  const _ProcessingState({required this.stage});

  final TranscriptionStage stage;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        NorteCard(
          child: Column(
            children: <Widget>[
              for (final TranscriptionStage each in <TranscriptionStage>[
                TranscriptionStage.uploading,
                TranscriptionStage.transcribing,
                TranscriptionStage.summarizing,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: NorteSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: each == stage
                            ? CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.accent,
                              )
                            : Icon(
                                each.index < stage.index
                                    ? LucideIcons.check
                                    : LucideIcons.circle,
                                size: 16,
                                color: each.index < stage.index
                                    ? colors.accent
                                    : colors.border,
                              ),
                      ),
                      const SizedBox(width: NorteSpacing.md),
                      Text(
                        transcriptionStageLabel(l10n, each),
                        style: NorteTypography.body.copyWith(
                          color: each.index <= stage.index
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A failed run, with the recording still on disk behind it.
class _FailedState extends StatelessWidget {
  const _FailedState({
    required this.failure,
    required this.hasAudio,
    required this.onRetry,
    required this.onDiscard,
  });

  final Failure? failure;
  final bool hasAudio;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _Notice(
          icon: LucideIcons.circleAlert,
          message: failure == null
              ? l10n.aiErrorGeneric
              : meetingFailureText(l10n, failure!),
          color: colors.error,
        ),
        if (hasAudio) ...<Widget>[
          const SizedBox(height: NorteSpacing.md),
          // The sentence the rule is for: the audio survived, so trying again
          // costs a tap rather than an hour.
          _Notice(
            icon: LucideIcons.hardDrive,
            message: l10n.recordMeetingKeepAudio,
            color: colors.textSecondary,
          ),
        ],
        const SizedBox(height: NorteSpacing.xl),
        if (hasAudio) ...<Widget>[
          NorteButton(
            key: RecordMeetingScreen.retryKey,
            label: l10n.actionRetry,
            icon: LucideIcons.refreshCw,
            onPressed: onRetry,
          ),
          const SizedBox(height: NorteSpacing.md),
          NorteButton(
            key: RecordMeetingScreen.discardKey,
            label: l10n.recordMeetingDiscard,
            variant: NorteButtonVariant.destructive,
            onPressed: onDiscard,
          ),
        ],
      ],
    );
  }
}

/// The microphone was refused.
class _PermissionState extends ConsumerWidget {
  const _PermissionState({required this.isPermanentlyDenied});

  final bool isPermanentlyDenied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Icon(LucideIcons.micOff, size: 32, color: colors.textSecondary),
        const SizedBox(height: NorteSpacing.lg),
        Text(
          l10n.recordMeetingPermissionTitle,
          style: NorteTypography.title.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: NorteSpacing.sm),
        Text(
          l10n.recordMeetingPermissionBody,
          style: NorteTypography.body.copyWith(color: colors.textSecondary),
        ),
        if (isPermanentlyDenied) ...<Widget>[
          const SizedBox(height: NorteSpacing.md),
          Text(
            l10n.recordMeetingPermissionPermanent,
            style: NorteTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: NorteSpacing.xl),
        // Only offered when the prompt would actually appear. An "allow"
        // button that silently does nothing is worse than no button.
        if (!isPermanentlyDenied) ...<Widget>[
          NorteButton(
            key: RecordMeetingScreen.permissionAllowKey,
            label: l10n.recordMeetingPermissionAllow,
            icon: LucideIcons.mic,
            onPressed: () => ref.read(meetingRecorderProvider.notifier).start(),
          ),
          const SizedBox(height: NorteSpacing.md),
        ],
        NorteButton(
          key: RecordMeetingScreen.permissionSettingsKey,
          label: l10n.recordMeetingPermissionSettings,
          icon: LucideIcons.settings,
          variant: NorteButtonVariant.secondary,
          onPressed: () =>
              ref.read(meetingRecorderProvider.notifier).openSettings(),
        ),
      ],
    );
  }
}

/// An icon and a sentence, used for both the error and the reassurance.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => NorteCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: NorteSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: NorteTypography.body.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
