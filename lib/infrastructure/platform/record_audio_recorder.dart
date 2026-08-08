import 'dart:async';

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart' as rec;

import '../../domain/failures/failure.dart';
import '../../domain/ports/audio_recorder.dart';
import '../../domain/ports/clock.dart';

/// [AudioRecorder] over the `record` package (`docs/architecture.md` §2.1),
/// with `permission_handler` for the part `record` does not model (DEC-022).
///
/// **Elapsed time excludes paused time.** The adapter accumulates the closed
/// segments and adds the open one, rather than subtracting a start instant from
/// now. The difference is the whole behaviour of a pause: a user who pauses for
/// ten minutes has not recorded ten minutes of silence, the limit must not
/// consume them, and the timer on screen must not count them.
///
/// **The platform can pause underneath us.** An incoming call or the app going
/// to the background suspends capture without asking, so the adapter follows
/// `record`'s own state stream rather than trusting its last instruction. That
/// is what makes an interrupted recording resumable instead of a take the user
/// discovers was empty (`sprint-04` validation rules).
class RecordAudioRecorder implements AudioRecorder {
  RecordAudioRecorder({
    required this.clock,
    rec.AudioRecorder? recorder,
    ph.Permission permission = ph.Permission.microphone,
    Future<bool> Function()? openAppSettings,
    this.tick = const Duration(milliseconds: 200),
  }) : micPermission = permission,
       _recorder = recorder ?? rec.AudioRecorder(),
       _openAppSettings = openAppSettings ?? ph.openAppSettings;

  final Clock clock;
  final rec.AudioRecorder _recorder;
  final ph.Permission micPermission;
  final Future<bool> Function() _openAppSettings;

  /// How often the indicator updates. Fast enough that the level meter moves
  /// with the speaker, slow enough that a ninety-minute meeting does not spend
  /// its battery on a timer.
  final Duration tick;

  /// Quietest input the meter distinguishes. Below roughly -45 dBFS everything
  /// is room tone, and a meter that swung on room tone would tell the user
  /// their microphone is working when it is picking up nothing but the fan.
  static const double _silenceFloorDb = -45;

  final StreamController<RecordingProgress> _progress =
      StreamController<RecordingProgress>.broadcast();

  StreamSubscription<rec.RecordState>? _states;
  Timer? _ticker;
  Timer? _limit;

  /// Audio captured in segments already closed by a pause.
  Duration _closed = Duration.zero;

  /// When the currently open segment began, or `null` while paused.
  DateTime? _segmentStart;

  RecordingState _state = RecordingState.idle;
  double _level = 0;
  String? _path;

  @override
  Stream<RecordingProgress> get progress => _progress.stream;

  @override
  Future<MicrophonePermission> permission() async {
    final ph.PermissionStatus status = await micPermission.status;
    return _translate(status);
  }

  @override
  Future<MicrophonePermission> requestPermission() async =>
      _translate(await micPermission.request());

  @override
  Future<void> openSettings() async {
    await _openAppSettings();
  }

  @override
  Future<void> start({required String path, required Duration limit}) async {
    // Asking rather than checking: this is the moment the user tried to
    // record, which is the only moment at which a prompt is not an ambush.
    final MicrophonePermission granted = await requestPermission();
    if (granted != MicrophonePermission.granted) {
      throw MicrophonePermissionFailure(
        isPermanentlyDenied: granted == MicrophonePermission.permanentlyDenied,
      );
    }

    try {
      await _recorder.start(
        const rec.RecordConfig(
          encoder: rec.AudioEncoder.aacLc,
          // 32 kbps mono at 16 kHz: speech-grade, which is what Whisper wants
          // anyway, and about 20 MB for a ninety-minute meeting.
          bitRate: 32000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
    } on Failure {
      rethrow;
    } catch (_) {
      throw const RecordingFailure('the microphone could not be opened');
    }

    _path = path;
    _closed = Duration.zero;
    _segmentStart = clock.now();
    _state = RecordingState.recording;

    _states = _recorder.onStateChanged().listen(_onPlatformState);
    _ticker = Timer.periodic(tick, (_) => _emitTick());
    // Measured against captured audio, so a pause genuinely buys time rather
    // than merely deferring the cut-off.
    _limit0 = limit;
    _limit = Timer(limit, _stopAtLimit);
    _emit();
  }

  @override
  Future<void> pause() async {
    if (_state != RecordingState.recording) return;
    try {
      await _recorder.pause();
    } catch (_) {
      throw const RecordingFailure('the recording could not be paused');
    }
    _closeSegment();
    _state = RecordingState.paused;
    _emit();
  }

  @override
  Future<void> resume() async {
    if (_state != RecordingState.paused) return;
    try {
      await _recorder.resume();
    } catch (_) {
      throw const RecordingFailure('the recording could not be resumed');
    }
    _segmentStart = clock.now();
    _state = RecordingState.recording;
    _rearmLimit();
    _emit();
  }

  @override
  Future<AudioRecording> stop() async {
    if (_state == RecordingState.idle) {
      throw const RecordingFailure('there is no recording to stop');
    }

    _closeSegment();
    final Duration duration = _closed;
    final String? path = _path;

    await _teardown();

    try {
      final String? written = await _recorder.stop();
      _state = RecordingState.stopped;
      _emit();
      // `record` reports where it actually wrote; trust it over the path we
      // asked for, because a platform that substituted a container extension
      // would otherwise leave the caller deleting a file that is not there.
      return AudioRecording(path: written ?? path!, duration: duration);
    } catch (_) {
      throw const RecordingFailure('the recording could not be finalised');
    }
  }

  /// Releases the platform recorder. Call when the screen is disposed.
  Future<void> dispose() async {
    await _teardown();
    await _progress.close();
    await _recorder.dispose();
  }

  // --- internals ---------------------------------------------------------

  MicrophonePermission _translate(
    ph.PermissionStatus status,
  ) => switch (status) {
    ph.PermissionStatus.granted ||
    ph.PermissionStatus.limited ||
    ph.PermissionStatus.provisional => MicrophonePermission.granted,
    ph.PermissionStatus.permanentlyDenied ||
    // "Restricted" is a parental or corporate policy: the user cannot grant it
    // from the prompt either, so the honest screen is the same one.
    ph.PermissionStatus.restricted => MicrophonePermission.permanentlyDenied,
    ph.PermissionStatus.denied => MicrophonePermission.denied,
  };

  /// The platform changed the recording state without being asked.
  void _onPlatformState(rec.RecordState state) {
    switch (state) {
      case rec.RecordState.pause:
        if (_state == RecordingState.recording) {
          _closeSegment();
          _state = RecordingState.paused;
          _emit();
        }
      case rec.RecordState.record:
        if (_state == RecordingState.paused) {
          _segmentStart = clock.now();
          _state = RecordingState.recording;
          _rearmLimit();
          _emit();
        }
      case rec.RecordState.stop:
        break;
    }
  }

  Future<void> _emitTick() async {
    if (_state == RecordingState.recording) {
      _level = await _readLevel();
    }
    _emit();
  }

  /// Input level as `0.0..1.0`, from the platform's dBFS reading.
  Future<double> _readLevel() async {
    try {
      final rec.Amplitude amplitude = await _recorder.getAmplitude();
      final double db = amplitude.current;
      if (!db.isFinite) return 0;
      return ((db - _silenceFloorDb) / -_silenceFloorDb).clamp(0.0, 1.0);
    } catch (_) {
      // A meter that cannot be read is not a failed recording. The audio is
      // still being captured; only the animation is missing.
      return 0;
    }
  }

  void _closeSegment() {
    final DateTime? start = _segmentStart;
    if (start != null) _closed += clock.now().difference(start);
    _segmentStart = null;
  }

  Duration get _elapsed {
    final DateTime? start = _segmentStart;
    return start == null ? _closed : _closed + clock.now().difference(start);
  }

  /// Re-arms the ceiling against the audio still owing, so paused minutes are
  /// not charged against it.
  void _rearmLimit() {
    if (_limit == null) return;
    _limit!.cancel();
    final Duration remaining = _limit0 - _elapsed;
    _limit = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      _stopAtLimit,
    );
  }

  /// The configured ceiling, kept so [_rearmLimit] can measure what is left of
  /// it after a pause.
  Duration _limit0 = Duration.zero;

  void _stopAtLimit() {
    // Stopping at the limit keeps the audio: the take is finished, exactly as
    // if the user had pressed stop. Discarding it would punish them for the
    // app's ceiling, and a meeting that ran long is precisely the one worth
    // summarizing.
    unawaited(stop().catchError((_) => _emptyRecording));
  }

  static const AudioRecording _emptyRecording = AudioRecording(
    path: '',
    duration: Duration.zero,
  );

  void _emit() {
    if (_progress.isClosed) return;
    _progress.add(
      RecordingProgress(
        state: _state,
        elapsed: _elapsed,
        level: _state == RecordingState.recording ? _level : 0,
      ),
    );
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    _limit?.cancel();
    _limit = null;
    await _states?.cancel();
    _states = null;
  }
}
