import 'dart:async';
import 'dart:typed_data';

import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/audio_recorder.dart';
import 'package:norte/domain/ports/microphone.dart';

/// In-memory [Microphone] (`docs/testing-strategy.md` §3).
///
/// Emits whatever [frames] a test pushes and records how the session was
/// opened and closed. It produces **no** audio of its own: the transcripts in
/// a voice test come from `FakeRealtimeTranscription`, so a test never depends
/// on synthesising speech that no engine would hear anyway.
///
/// [closes] is the assertion BR-06 turns on at this level — a pipeline that
/// left the microphone open after a command was understood would be recording
/// the room while the user reads a confirmation sheet.
class FakeMicrophone implements Microphone {
  FakeMicrophone({this.granted = MicrophonePermission.granted});

  /// What the platform answers when asked.
  MicrophonePermission granted;

  /// Number of times [open] was called.
  int opens = 0;

  /// Number of times [close] was called.
  int closes = 0;

  /// Number of times the system settings were opened.
  int settingsOpened = 0;

  /// When set, [open] fails with it instead of streaming.
  Failure? failWith;

  StreamController<Uint8List>? _session;

  /// `true` while a session is open.
  bool get isOpen => _session != null && !_session!.isClosed;

  @override
  Future<MicrophonePermission> permission() async => granted;

  @override
  Future<MicrophonePermission> requestPermission() async => granted;

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Stream<Uint8List> open() {
    opens++;
    final StreamController<Uint8List> session = StreamController<Uint8List>();
    _session = session;

    scheduleMicrotask(() async {
      final Failure? failure = failWith;
      if (failure != null) {
        session.addError(failure);
        await session.close();
        return;
      }
      if (granted != MicrophonePermission.granted) {
        session.addError(
          MicrophonePermissionFailure(
            isPermanentlyDenied:
                granted == MicrophonePermission.permanentlyDenied,
          ),
        );
        await session.close();
      }
    });

    return session.stream;
  }

  /// Pushes one frame of audio, for a test that needs the engine to see bytes.
  void emit(Uint8List frame) {
    final StreamController<Uint8List>? session = _session;
    if (session == null || session.isClosed) return;
    session.add(frame);
  }

  @override
  Future<void> close() async {
    closes++;
    final StreamController<Uint8List>? session = _session;
    _session = null;
    if (session != null && !session.isClosed) await session.close();
  }
}
