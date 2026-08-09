import 'dart:typed_data';

import 'audio_recorder.dart';

/// The microphone as a live stream of bytes (`docs/architecture.md` §6.1).
///
/// Separate from [AudioRecorder], which captures a meeting **to a file** for
/// batch transcription. This one never produces a file at all: it hands PCM
/// frames straight to `RealtimeTranscription`, and BR-06 is the reason the two
/// are different ports rather than one port with a flag. A recorder whose
/// output happened to be a stream would still be a recorder, and the guarantee
/// that voice-command audio never reaches disk would rest on remembering to
/// pass the right flag.
///
/// **Contract**
/// * [open] emits **PCM 16 kHz mono, signed 16-bit little-endian** — the
///   format `ScribeRealtimeEngine` requires (§9.3). Chunk size is the
///   platform's; a consumer must not assume frames align to anything.
/// * [open] throws `MicrophonePermissionFailure` when access was not granted
///   and `RecordingFailure` when the device could not be opened. As with
///   [AudioRecorder], the permission queries themselves never throw: a refusal
///   is an answer.
/// * The stream closes when [close] is called, and never on its own except
///   when the platform ends the session.
/// * [close] is idempotent and safe with no session open.
abstract interface class Microphone {
  /// The current permission state, without prompting.
  Future<MicrophonePermission> permission();

  /// Prompts if the platform will, and reports where that left things.
  Future<MicrophonePermission> requestPermission();

  /// Opens the system settings page for this app.
  Future<void> openSettings();

  /// Starts capture and streams the frames.
  Stream<Uint8List> open();

  /// Stops capture and closes the stream.
  Future<void> close();
}
