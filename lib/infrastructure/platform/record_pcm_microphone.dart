import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart' as rec;

import '../../domain/failures/failure.dart';
import '../../domain/ports/audio_recorder.dart';
import '../../domain/ports/microphone.dart';

/// [Microphone] over the `record` package's streaming mode
/// (`docs/architecture.md` §2.1, §12).
///
/// **Nothing here touches the filesystem, and that is the design.** `record`
/// offers `start(path:)` and `startStream()`; this adapter can only call the
/// second one, because it never learns a path. BR-06 then holds by
/// construction rather than by discipline — there is no branch that could
/// write audio to disk, so no future edit can accidentally take it.
///
/// **PCM 16 kHz mono, 16-bit.** Not a preference: it is what Scribe Realtime
/// accepts (§9.3), and resampling in the app would spend battery to arrive at
/// the format the device could have produced directly.
class RecordPcmMicrophone implements Microphone {
  RecordPcmMicrophone({
    rec.AudioRecorder? recorder,
    ph.Permission permission = ph.Permission.microphone,
    Future<bool> Function()? openAppSettings,
    this.log,
  }) : micPermission = permission,
       _recorder = recorder ?? rec.AudioRecorder(),
       _openAppSettings = openAppSettings ?? ph.openAppSettings;

  final rec.AudioRecorder _recorder;
  final ph.Permission micPermission;
  final Future<bool> Function() _openAppSettings;

  /// Diagnostics sink for what the platform actually said.
  ///
  /// The user is told "the recording could not be made", which is all they can
  /// act on. This is where the reason goes — the `PlatformException`, the
  /// HRESULT behind it, the permission the platform reported. The first draft
  /// caught the exception and dropped it, so the app knew exactly why the
  /// microphone would not open and told nobody. That is the difference between
  /// a bug report of "it does not work" and one that names the cause.
  final void Function(String line)? log;

  /// Sample rate Scribe Realtime expects.
  static const int sampleRate = 16000;

  /// Mono. A second channel would double the bytes on the wire for speech
  /// that carries no stereo information.
  static const int channels = 1;

  StreamController<Uint8List>? _session;
  StreamSubscription<Uint8List>? _frames;

  @override
  Future<MicrophonePermission> permission() async =>
      _translate(await micPermission.status);

  @override
  Future<MicrophonePermission> requestPermission() async =>
      _translate(await micPermission.request());

  @override
  Future<void> openSettings() async {
    await _openAppSettings();
  }

  @override
  Stream<Uint8List> open() {
    final StreamController<Uint8List> session = StreamController<Uint8List>();
    _session = session;
    unawaited(_start(session));
    return session.stream;
  }

  @override
  Future<void> close() async {
    await _frames?.cancel();
    _frames = null;
    try {
      await _recorder.stop();
    } catch (_) {
      // Closing a session that the platform already ended is not a failure
      // the user can act on, and `close` is documented idempotent.
    }
    final StreamController<Uint8List>? session = _session;
    _session = null;
    if (session != null && !session.isClosed) await session.close();
  }

  /// Releases the platform recorder. Call when the app shuts the pipeline down.
  Future<void> dispose() async {
    await close();
    await _recorder.dispose();
  }

  Future<void> _start(StreamController<Uint8List> session) async {
    // Asking rather than checking: this is the moment the user pressed the
    // voice button, which is the only moment at which a prompt is not an
    // ambush.
    final MicrophonePermission granted;
    try {
      granted = await requestPermission();
    } catch (error) {
      // `permission_handler` is not implemented on every desktop platform, and
      // a plugin that throws here would otherwise read as a refusal — sending
      // the user to a settings page for a permission that was never the
      // problem.
      log?.call('permission check failed: $error');
      session.addError(
        const RecordingFailure('the microphone permission could not be read'),
      );
      await session.close();
      return;
    }

    log?.call('permission: ${granted.name}');
    if (granted != MicrophonePermission.granted) {
      session.addError(
        MicrophonePermissionFailure(
          isPermanentlyDenied:
              granted == MicrophonePermission.permanentlyDenied,
        ),
      );
      await session.close();
      return;
    }

    final Stream<Uint8List> frames;
    try {
      frames = await _recorder.startStream(
        const rec.RecordConfig(
          encoder: rec.AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: channels,
        ),
      );
    } catch (error) {
      // The platform's own words. On Windows this carries the HRESULT the
      // Media Foundation capture failed with, which is the whole difference
      // between "it does not work" and a fix.
      log?.call(
        'startStream failed at ${sampleRate}Hz/${channels}ch pcm16: $error',
      );
      session.addError(
        const RecordingFailure('the microphone could not be opened'),
      );
      await session.close();
      return;
    }

    log?.call('capture started at ${sampleRate}Hz/${channels}ch pcm16');

    _frames = frames.listen(
      (Uint8List chunk) {
        if (!session.isClosed) session.add(chunk);
      },
      onError: (Object error) {
        log?.call('capture stream error: $error');
        if (!session.isClosed) {
          session.addError(const RecordingFailure('audio capture stopped'));
        }
      },
      onDone: () {
        // The platform ended the session — a phone call, a device change.
        // Closing here rather than hanging is what lets the pipeline commit
        // whatever was already spoken.
        if (!session.isClosed) session.close();
      },
    );
  }

  MicrophonePermission _translate(ph.PermissionStatus status) =>
      switch (status) {
        ph.PermissionStatus.granted ||
        ph.PermissionStatus.limited ||
        ph.PermissionStatus.provisional => MicrophonePermission.granted,
        ph.PermissionStatus.permanentlyDenied ||
        ph.PermissionStatus.restricted =>
          MicrophonePermission.permanentlyDenied,
        ph.PermissionStatus.denied => MicrophonePermission.denied,
      };
}
