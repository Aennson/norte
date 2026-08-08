import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:norte/domain/failures/failure.dart';
import 'package:norte/infrastructure/transcription/realtime_socket.dart';

/// A [RealtimeSocket] a test can drop and bring back at will.
///
/// S05-UT-06 needs a connection that dies mid-speech and returns three seconds
/// later, with the assertion resting on exactly which bytes arrive after it.
/// Against a real socket that is a timing race; here it is two method calls.
class FakeRealtimeSocket implements RealtimeSocket {
  FakeRealtimeSocket();

  final StreamController<Object?> _incoming =
      StreamController<Object?>.broadcast();

  /// Everything the engine sent, in order — PCM chunks and control frames
  /// alike.
  final List<Object> sent = <Object>[];

  /// `true` until [drop] or [close].
  bool isOpen = true;

  @override
  Stream<Object?> get messages => _incoming.stream;

  @override
  void send(Object data) {
    if (!isOpen) return;
    sent.add(data);
  }

  @override
  Future<void> close() async {
    isOpen = false;
    if (!_incoming.isClosed) await _incoming.close();
  }

  /// The audio frames received, concatenated — the bytes the service heard.
  Uint8List get audio {
    final BytesBuilder heard = BytesBuilder();
    for (final Object frame in sent) {
      if (frame is Uint8List) heard.add(frame);
    }
    return heard.toBytes();
  }

  /// The JSON control frames received, decoded.
  List<Map<String, Object?>> get control => <Map<String, Object?>>[
    for (final Object frame in sent)
      if (frame is String) jsonDecode(frame) as Map<String, Object?>,
  ];

  /// Pushes a `partial` transcript from the service.
  void emitPartial(String text) =>
      _emit(<String, Object?>{'type': 'partial_transcript', 'text': text});

  /// Pushes a `committed` transcript — VAD closed the segment.
  void emitCommitted(String text) =>
      _emit(<String, Object?>{'type': 'final_transcript', 'text': text});

  /// Pushes a service-side error frame.
  void emitError(String type) => _emit(<String, Object?>{
    'type': 'error',
    'error': <String, Object?>{'type': type},
  });

  /// The connection dies without a goodbye, as a lost network does.
  Future<void> drop() async {
    isOpen = false;
    if (!_incoming.isClosed) await _incoming.close();
  }

  void _emit(Map<String, Object?> frame) {
    if (_incoming.isClosed) return;
    _incoming.add(jsonEncode(frame));
  }
}

/// A connector handing out [FakeRealtimeSocket]s, one per attempt.
///
/// [failFirst] refuses that many connections before the first success, which
/// is how the backoff is exercised without waiting for it.
class FakeSocketConnector {
  FakeSocketConnector({this.failFirst = 0, this.failWith});

  int failFirst;

  /// While `true`, every attempt is refused — the network is simply gone.
  ///
  /// This is what makes an *outage* testable as opposed to a reconnection:
  /// with a connector that always succeeds the engine is back before the next
  /// audio frame arrives, and the buffer the sprint cares about never fills.
  bool isDown = false;

  /// The failure to refuse with. Defaults to a [NetworkFailure], the one a
  /// retry could fix.
  Failure? failWith;

  /// Every socket handed out, in order.
  final List<FakeRealtimeSocket> sockets = <FakeRealtimeSocket>[];

  /// Attempts made, including the refused ones.
  int attempts = 0;

  /// The key each attempt presented.
  final List<String> keys = <String>[];

  /// The socket currently in the engine's hands.
  FakeRealtimeSocket get current => sockets.last;

  Future<RealtimeSocket> call(Uri uri, String apiKey) async {
    attempts++;
    keys.add(apiKey);
    if (isDown || attempts <= failFirst) {
      throw failWith ?? const NetworkFailure('cannot reach the service');
    }
    final FakeRealtimeSocket socket = FakeRealtimeSocket();
    sockets.add(socket);
    return socket;
  }
}
