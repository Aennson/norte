/// What the platform says about microphone access.
enum MicrophonePermission {
  granted,

  /// Refused, but the platform will still show its prompt if asked again.
  denied,

  /// Refused for good — asking again does nothing, and the only route left is
  /// the system settings. Android and iOS both reach this state after the user
  /// has refused once too often, and telling the user to "allow the prompt"
  /// when no prompt will ever appear is the worst version of this screen.
  permanentlyDenied,
}

/// What a recording is doing right now.
enum RecordingState {
  idle,
  recording,

  /// Paused by the user, or by the platform: a phone call or the app going to
  /// the background pauses rather than ends the take, because the alternative
  /// is losing a meeting to an interruption nobody chose
  /// (`sprint-04` validation rules).
  paused,
  stopped,
}

/// A tick of the recording indicator.
class RecordingProgress {
  const RecordingProgress({
    required this.state,
    required this.elapsed,
    required this.level,
  });

  final RecordingState state;

  /// Time captured so far. **Paused time does not count** — it is the length
  /// of the audio, not of the sitting, and it is what the limit is measured
  /// against.
  final Duration elapsed;

  /// Input level in `0.0..1.0`, for the meter beside the timer.
  ///
  /// Normalised by the adapter, because "how loud is loud" is a property of
  /// the platform's dBFS scale and not something the UI should have to know.
  final double level;

  @override
  bool operator ==(Object other) =>
      other is RecordingProgress &&
      other.state == state &&
      other.elapsed == elapsed &&
      other.level == level;

  @override
  int get hashCode => Object.hash(state, elapsed, level);
}

/// A finished recording.
class AudioRecording {
  const AudioRecording({required this.path, required this.duration});

  /// Where the audio is — always inside the `AudioStore`'s temp directory.
  final String path;

  /// How much audio was captured, excluding paused time.
  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is AudioRecording &&
      other.path == path &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(path, duration);
}

/// Captures meeting audio from the microphone (`docs/architecture.md` §2.1,
/// via the `record` package).
///
/// **Contract**
/// * [permission] and [requestPermission] never throw: a refusal is an answer,
///   not an error. [start] is the one that fails, with
///   `MicrophonePermissionFailure`, because that is the point at which the
///   user was trying to do something.
/// * [start] writes to [path] — supplied by `AudioStore`, so the recorder
///   never decides where audio lives.
/// * [limit] stops the recording as if the user had pressed stop: the audio up
///   to that point is kept and usable. A limit that discarded the take would
///   punish the user for the app's own ceiling.
/// * [pause] and [resume] are idempotent, and both are safe to call in any
///   state — the platform may pause a recording underneath the app, so the UI
///   cannot be the only thing that knows.
/// * [stop] returns the [AudioRecording] and leaves the file **on disk**. The
///   caller decides when it dies; see `AudioStore`.
/// * [progress] is a broadcast stream that closes when the recording stops.
/// * Failures surface as `MicrophonePermissionFailure` or `RecordingFailure`.
abstract interface class AudioRecorder {
  /// The current permission state, without prompting.
  Future<MicrophonePermission> permission();

  /// Prompts if the platform will, and reports where that left things.
  Future<MicrophonePermission> requestPermission();

  /// Opens the system settings page for this app, so the user can grant the
  /// permission the prompt will no longer ask for.
  Future<void> openSettings();

  /// Starts capturing into [path], stopping by itself after [limit].
  Future<void> start({required String path, required Duration limit});

  /// Pauses capture, keeping what has been recorded.
  Future<void> pause();

  /// Resumes a paused capture into the same file.
  Future<void> resume();

  /// Stops and finalises the file.
  Future<AudioRecording> stop();

  /// Ticks of state, elapsed time and input level.
  Stream<RecordingProgress> get progress;
}
