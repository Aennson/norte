import 'dart:async';

import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/audio_recorder.dart';

/// Scriptable [AudioRecorder] (`docs/testing-strategy.md` §3).
///
/// No microphone is opened and no file is written: the fake produces a path
/// and a duration, which is everything the layers above a recorder actually
/// depend on. [permissionStatus] is the switch S04-E2E-02 flips.
class FakeAudioRecorder implements AudioRecorder {
  FakeAudioRecorder({
    this.permissionStatus = MicrophonePermission.granted,
    this.recordedDuration = const Duration(minutes: 3),
  });

  /// What the platform is pretending to say about the microphone.
  MicrophonePermission permissionStatus;

  /// Duration reported by [stop].
  Duration recordedDuration;

  /// When set, [start] throws it instead of recording.
  Failure? failStartWith;

  /// `true` once [openSettings] has been called — the assertion S04-E2E-02
  /// makes about the permission screen's action.
  bool settingsOpened = false;

  /// Every permission prompt this fake was asked to show.
  int prompts = 0;

  /// Path passed to the last [start].
  String? startedPath;

  /// Limit passed to the last [start].
  Duration? startedLimit;

  final StreamController<RecordingProgress> _progress =
      StreamController<RecordingProgress>.broadcast();

  RecordingState _state = RecordingState.idle;
  Duration _elapsed = Duration.zero;

  /// The recorder's current state, for a test that wants to assert it directly.
  RecordingState get state => _state;

  @override
  Stream<RecordingProgress> get progress => _progress.stream;

  @override
  Future<MicrophonePermission> permission() async => permissionStatus;

  @override
  Future<MicrophonePermission> requestPermission() async {
    prompts++;
    return permissionStatus;
  }

  @override
  Future<void> openSettings() async {
    settingsOpened = true;
  }

  @override
  Future<void> start({required String path, required Duration limit}) async {
    final Failure? failure = failStartWith;
    if (failure != null) throw failure;

    // The real adapter asks before it opens the microphone, and the permission
    // screen exists because of what it throws here (S04-E2E-02).
    final MicrophonePermission granted = await requestPermission();
    if (granted != MicrophonePermission.granted) {
      throw MicrophonePermissionFailure(
        isPermanentlyDenied: granted == MicrophonePermission.permanentlyDenied,
      );
    }

    startedPath = path;
    startedLimit = limit;
    _state = RecordingState.recording;
    _elapsed = Duration.zero;
    _emit();
  }

  @override
  Future<void> pause() async {
    if (_state != RecordingState.recording) return;
    _state = RecordingState.paused;
    _emit();
  }

  @override
  Future<void> resume() async {
    if (_state != RecordingState.paused) return;
    _state = RecordingState.recording;
    _emit();
  }

  @override
  Future<AudioRecording> stop() async {
    if (_state == RecordingState.idle) {
      throw const RecordingFailure('there is no recording to stop');
    }
    _state = RecordingState.stopped;
    _elapsed = recordedDuration;
    _emit();
    return AudioRecording(path: startedPath!, duration: recordedDuration);
  }

  /// Drives the indicator, so a widget test can render a recording mid-flight.
  void tick({required Duration elapsed, double level = 0.4}) {
    _elapsed = elapsed;
    _progress.add(
      RecordingProgress(state: _state, elapsed: elapsed, level: level),
    );
  }

  /// Simulates the platform pausing underneath the app — an incoming call, or
  /// the app being backgrounded (`sprint-04` validation rules).
  void interrupt() {
    _state = RecordingState.paused;
    _emit();
  }

  /// Closes the progress stream. Call from `addTearDown`.
  Future<void> dispose() => _progress.close();

  void _emit() {
    if (_progress.isClosed) return;
    _progress.add(
      RecordingProgress(
        state: _state,
        elapsed: _elapsed,
        level: _state == RecordingState.recording ? 0.4 : 0,
      ),
    );
  }
}
