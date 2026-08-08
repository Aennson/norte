import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/usecases/transcribe_meeting_audio.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/audio_recorder.dart';
import 'meeting_providers.dart';

/// What the recording screen is showing.
enum MeetingRecorderStatus {
  /// Before the first tap — and after a discard.
  idle,

  /// The microphone was refused. A state rather than an error, because there
  /// is nothing to retry until the user changes something outside the app.
  permissionDenied,

  recording,
  paused,

  /// Recorded, not yet transcribed: the point at which the audio exists on
  /// disk and the user can still throw it away.
  recorded,

  /// Uploading, transcribing or summarizing — [MeetingRecorderState.stage]
  /// says which.
  processing,

  /// Something failed. **The audio is still on disk**, which is what makes the
  /// retry a retry (S04-UT-02).
  failed,

  /// A summary exists and the screen is about to hand over to the summary
  /// screen.
  summarized,
}

/// State of the record → transcribe → summarize flow.
class MeetingRecorderState {
  const MeetingRecorderState({
    this.status = MeetingRecorderStatus.idle,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.stage,
    this.audioPath,
    this.failure,
    this.isPermanentlyDenied = false,
    this.wasInterrupted = false,
  });

  final MeetingRecorderStatus status;

  /// Captured audio so far, excluding paused time.
  final Duration elapsed;

  /// Input level, `0.0..1.0`, for the meter.
  final double level;

  /// Which stage the pipeline is in while [status] is
  /// [MeetingRecorderStatus.processing].
  final TranscriptionStage? stage;

  /// Where the recording is, once there is one.
  final String? audioPath;

  final Failure? failure;

  /// `true` when the platform will no longer prompt, so the screen offers the
  /// settings route instead of an "allow" button that would do nothing.
  final bool isPermanentlyDenied;

  /// `true` when the pause came from the platform rather than the user — a
  /// call, or the app being backgrounded. The screen says so, because a pause
  /// nobody pressed is otherwise indistinguishable from a bug.
  final bool wasInterrupted;

  /// Whether there is audio on disk that the user could discard or retry with.
  bool get hasAudio => audioPath != null;

  MeetingRecorderState copyWith({
    MeetingRecorderStatus? status,
    Duration? elapsed,
    double? level,
    TranscriptionStage? stage,
    String? audioPath,
    Failure? failure,
    bool? isPermanentlyDenied,
    bool? wasInterrupted,
    bool clearFailure = false,
    bool clearStage = false,
    bool clearAudio = false,
  }) => MeetingRecorderState(
    status: status ?? this.status,
    elapsed: elapsed ?? this.elapsed,
    level: level ?? this.level,
    stage: clearStage ? null : stage ?? this.stage,
    audioPath: clearAudio ? null : audioPath ?? this.audioPath,
    failure: clearFailure ? null : failure ?? this.failure,
    isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
    wasInterrupted: wasInterrupted ?? this.wasInterrupted,
  );
}

/// Drives the recording screen.
///
/// **The summarized meeting is handed to [MeetingComposer]**, not held here.
/// Both input flows converge on the same summary screen, the same save path
/// and the same BR-03 gate — which is the sprint's "no duplicated code" rule
/// applied to the presentation layer as well as to the use cases.
class MeetingRecorder extends Notifier<MeetingRecorderState> {
  StreamSubscription<RecordingProgress>? _progress;

  @override
  MeetingRecorderState build() {
    ref.onDispose(() => unawaited(_progress?.cancel()));
    return const MeetingRecorderState();
  }

  /// Starts a take, asking for the microphone if it has not been granted.
  Future<void> start() async {
    final AudioRecorder recorder = ref.read(audioRecorderProvider);

    final String path;
    try {
      path = await ref.read(audioStoreProvider).newRecordingPath();
    } on Failure catch (failure) {
      state = state.copyWith(
        status: MeetingRecorderStatus.failed,
        failure: failure,
      );
      return;
    }

    try {
      await recorder.start(path: path, limit: ref.read(recordingLimitProvider));
    } on MicrophonePermissionFailure catch (failure) {
      state = state.copyWith(
        status: MeetingRecorderStatus.permissionDenied,
        isPermanentlyDenied: failure.isPermanentlyDenied,
        failure: failure,
      );
      return;
    } on Failure catch (failure) {
      state = state.copyWith(
        status: MeetingRecorderStatus.failed,
        failure: failure,
      );
      return;
    }

    await _progress?.cancel();
    _progress = recorder.progress.listen(_onProgress);

    state = state.copyWith(
      status: MeetingRecorderStatus.recording,
      audioPath: path,
      elapsed: Duration.zero,
      level: 0,
      clearFailure: true,
      clearStage: true,
      wasInterrupted: false,
    );
  }

  /// Opens the system settings, for a permission the prompt will not ask for
  /// again.
  Future<void> openSettings() => ref.read(audioRecorderProvider).openSettings();

  Future<void> pause() async {
    await ref.read(audioRecorderProvider).pause();
    state = state.copyWith(
      status: MeetingRecorderStatus.paused,
      wasInterrupted: false,
    );
  }

  Future<void> resume() async {
    await ref.read(audioRecorderProvider).resume();
    state = state.copyWith(
      status: MeetingRecorderStatus.recording,
      wasInterrupted: false,
    );
  }

  /// Ends the take. The audio stays on disk until it is transcribed or
  /// discarded.
  Future<void> stop() async {
    try {
      final AudioRecording recording = await ref
          .read(audioRecorderProvider)
          .stop();
      await _progress?.cancel();
      _progress = null;
      state = state.copyWith(
        status: MeetingRecorderStatus.recorded,
        audioPath: recording.path,
        elapsed: recording.duration,
        level: 0,
      );
    } on Failure catch (failure) {
      state = state.copyWith(
        status: MeetingRecorderStatus.failed,
        failure: failure,
      );
    }
  }

  /// Transcribes and summarizes the recording, under the composer's template
  /// and the composer's BR-03 choice.
  Future<void> transcribe({required String title}) async {
    final String? path = state.audioPath;
    final MeetingComposerState composer = ref.read(meetingComposerProvider);
    final MeetingTemplate? template = composer.template;
    if (path == null || template == null) return;

    state = state.copyWith(
      status: MeetingRecorderStatus.processing,
      stage: TranscriptionStage.uploading,
      clearFailure: true,
    );

    final Result<Meeting> result =
        await ref.read(transcribeMeetingAudioProvider)(
          audioPath: path,
          template: template,
          title: title,
          retention: composer.retention,
          onStage: (TranscriptionStage stage) {
            if (stage != TranscriptionStage.done) {
              state = state.copyWith(stage: stage);
            }
          },
        );

    switch (result) {
      case Ok<Meeting>(:final Meeting value):
        // Handing the meeting to the composer is what puts both input flows on
        // the same summary screen and the same save path.
        ref.read(meetingComposerProvider.notifier).adopt(value);
        state = state.copyWith(
          status: MeetingRecorderStatus.summarized,
          clearStage: true,
          // The audio is gone: the use case deleted it on success.
          clearAudio: true,
        );
      case Err<Meeting>(:final Failure failure):
        // The audio deliberately stays in `audioPath`, so the retry below
        // needs no new recording.
        state = state.copyWith(
          status: MeetingRecorderStatus.failed,
          failure: failure,
          clearStage: true,
        );
    }
  }

  /// Deletes the recording without transcribing it (S04-UT-03 scenario B).
  Future<void> discard() async {
    final String? path = state.audioPath;
    await _progress?.cancel();
    _progress = null;
    if (path != null) {
      await ref.read(transcribeMeetingAudioProvider).discard(path);
    }
    state = const MeetingRecorderState();
  }

  /// Clears the screen without touching the file — used when leaving after a
  /// successful run, where the audio is already gone.
  void reset() {
    unawaited(_progress?.cancel());
    _progress = null;
    state = const MeetingRecorderState();
  }

  void _onProgress(RecordingProgress progress) {
    // The platform can pause underneath the app. Following the recorder rather
    // than our own last instruction is what makes an interruption recoverable
    // instead of a take that silently stopped (`sprint-04` validation rules).
    final bool interrupted =
        progress.state == RecordingState.paused &&
        state.status == MeetingRecorderStatus.recording;

    state = state.copyWith(
      status: switch (progress.state) {
        RecordingState.recording => MeetingRecorderStatus.recording,
        RecordingState.paused => MeetingRecorderStatus.paused,
        // `stop` and `discard` own those transitions; a tick must not race
        // them into a state the screen has already left.
        RecordingState.idle || RecordingState.stopped => state.status,
      },
      elapsed: progress.elapsed,
      level: progress.level,
      wasInterrupted: interrupted ? true : null,
    );
  }
}

final NotifierProvider<MeetingRecorder, MeetingRecorderState>
meetingRecorderProvider =
    NotifierProvider<MeetingRecorder, MeetingRecorderState>(
      MeetingRecorder.new,
    );
