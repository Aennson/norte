import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/transcription_engine.dart';

/// Deterministic [RealtimeTranscription] (`docs/testing-strategy.md` §3).
///
/// Replays a scripted `partial`/`committed` sequence instead of opening a
/// WebSocket. [disconnectAfter] reproduces the dropped-connection path the
/// adapter must recover from (`docs/architecture.md` §9.3).
///
/// It implements the promoted port, so S05-CT-01 can run the same script
/// through this and through `ScribeRealtimeEngine` and hold both to one
/// contract.
class FakeRealtimeTranscription implements RealtimeTranscription {
  FakeRealtimeTranscription({List<TranscriptEvent>? script})
    : script = script ?? <TranscriptEvent>[];

  /// Loads a scripted session from `test/fixtures/realtime_session.json`.
  factory FakeRealtimeTranscription.fromFixture([
    String path = 'test/fixtures/realtime_session.json',
  ]) {
    final Object? decoded = jsonDecode(File(path).readAsStringSync());
    final List<Object?> rows =
        (decoded! as Map<String, Object?>)['events']! as List<Object?>;
    return FakeRealtimeTranscription(
      script: <TranscriptEvent>[
        for (final Object? row in rows)
          TranscriptEvent(
            text: (row! as Map<String, Object?>)['text']! as String,
            isCommitted: (row as Map<String, Object?>)['committed']! as bool,
          ),
      ],
    );
  }

  /// Events emitted, in order, once [start] is called.
  final List<TranscriptEvent> script;

  /// When `false`, [start] emits nothing and the test drives with [emit].
  ///
  /// The contract suite and the E2E flows need speech to arrive *while* the
  /// app is on screen, not before the first frame is built. Replaying a whole
  /// utterance in one microtask is convenient for a unit test and useless for
  /// a widget one.
  bool autoplay = true;

  /// Emits [NetworkFailure] after this many events, reproducing a drop.
  /// `null` plays the whole script.
  int? disconnectAfter;

  /// `true` between [start] and [stop].
  bool isRunning = false;

  /// Number of times [stop] was called.
  int stopCount = 0;

  /// Audio chunks received from the caller.
  ///
  /// **BR-06's assertion surface**: they are here, in memory, and a test can
  /// check that nowhere else has a copy.
  final List<Uint8List> receivedChunks = <Uint8List>[];

  StreamController<TranscriptEvent>? _session;

  final StreamController<bool> _connected = StreamController<bool>.broadcast();
  bool _isConnected = false;

  @override
  TranscriptionMode get mode => TranscriptionMode.realtime;

  @override
  Stream<bool> get isConnected async* {
    yield _isConnected;
    yield* _connected.stream;
  }

  /// Opens or drops the notional connection, so a test can drive the overlay
  /// through "connecting" as a user would see it.
  void setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    if (!_connected.isClosed) _connected.add(value);
  }

  @override
  Stream<TranscriptEvent> start(Stream<Uint8List> pcm16k) {
    isRunning = true;
    // A fake socket is up the instant it is asked for; the delay a real one
    // has is what `setConnected` exists to reproduce deliberately.
    setConnected(true);
    final StreamController<TranscriptEvent> controller =
        StreamController<TranscriptEvent>();
    _session = controller;

    final StreamSubscription<Uint8List> audio = pcm16k.listen(
      receivedChunks.add,
    );

    if (!autoplay) {
      unawaited(audio.asFuture<void>().then((_) {}, onError: (_) {}));
      return controller.stream;
    }

    scheduleMicrotask(() async {
      var emitted = 0;
      for (final TranscriptEvent event in script) {
        if (controller.isClosed) break;
        if (disconnectAfter != null && emitted == disconnectAfter) {
          controller.addError(const NetworkFailure('realtime socket closed'));
          break;
        }
        controller.add(event);
        emitted++;
      }
      await audio.cancel();
      if (!controller.isClosed) await controller.close();
      isRunning = false;
    });

    return controller.stream;
  }

  /// Pushes one event into the open session. Ignored when none is open, which
  /// is what makes "no event arrives after `stop`" assertable.
  void emit(TranscriptEvent event) {
    final StreamController<TranscriptEvent>? session = _session;
    if (session == null || session.isClosed) return;
    session.add(event);
  }

  /// Pushes a `partial`.
  void emitPartial(String text) =>
      emit(TranscriptEvent(text: text, isCommitted: false));

  /// Pushes a `committed` — VAD closed the segment.
  void emitCommitted(String text) =>
      emit(TranscriptEvent(text: text, isCommitted: true));

  @override
  Future<void> stop() async {
    stopCount++;
    isRunning = false;
    setConnected(false);
    final StreamController<TranscriptEvent>? session = _session;
    _session = null;
    if (session != null && !session.isClosed) await session.close();
  }
}
