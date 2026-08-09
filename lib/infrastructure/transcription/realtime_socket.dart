import 'dart:async';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/failures/failure.dart';

/// The duplex connection `ScribeRealtimeEngine` talks over.
///
/// A one-method-each interface in front of `WebSocketChannel`, for one reason:
/// S05-UT-06 has to drop a live connection mid-speech and bring it back, and
/// doing that to a real socket means binding a server, racing its shutdown, and
/// hoping the timing reproduces. Behind this interface the test simply stops
/// answering, and the assertion — that the three seconds of speech spoken
/// during the outage are re-sent — becomes deterministic.
///
/// The real implementation is [WebSocketRealtimeSocket] below, and it is thin
/// enough to read in one sitting, which is what keeps the seam honest.
abstract interface class RealtimeSocket {
  /// Frames from the service: JSON text, in practice.
  Stream<Object?> get messages;

  /// Sends [data] — a `Uint8List` of PCM, or a JSON control string.
  void send(Object data);

  /// Closes the connection. Idempotent.
  Future<void> close();
}

/// Opens a socket to [uri], authenticated with [apiKey].
///
/// Throws a [Failure]: [AuthFailure] when the key is rejected, and
/// [NetworkFailure] when the socket cannot be opened at all. The distinction
/// decides whether the engine retries — a refused key does not get better on
/// the second attempt.
typedef RealtimeSocketConnector =
    Future<RealtimeSocket> Function(Uri uri, String apiKey);

/// [RealtimeSocket] over `web_socket_channel` (`docs/architecture.md` §2.1).
class WebSocketRealtimeSocket implements RealtimeSocket {
  WebSocketRealtimeSocket(this._channel);

  /// Header the API key is presented in.
  ///
  /// A **header, not a query parameter**, and deliberately: a URL is the one
  /// part of a request that reliably ends up in proxy logs, crash reports and
  /// shell history. A credential in a query string is a credential you cannot
  /// take back (BR-08).
  static const String apiKeyHeader = 'xi-api-key';

  /// Connects to [uri], presenting [apiKey] in [apiKeyHeader].
  ///
  /// Uses `IOWebSocketChannel` rather than the platform-agnostic
  /// `WebSocketChannel.connect`, because only the former can send handshake
  /// headers — and the app's three targets are all `dart:io` platforms
  /// (`docs/architecture.md` §12). The generic constructor silently sends no
  /// headers at all, which is how this shipped in its first draft: the key was
  /// accepted as an argument and dropped on the floor.
  static Future<RealtimeSocket> connect(Uri uri, String apiKey) async {
    final WebSocketChannel channel = IOWebSocketChannel.connect(
      uri,
      headers: <String, Object?>{apiKeyHeader: apiKey},
    );
    try {
      await channel.ready;
    } on WebSocketChannelException catch (error) {
      // The handshake is HTTP: a rejected key comes back as a 401 the
      // exception carries in its message, and there is no richer signal to
      // read at this layer.
      final String detail = error.message ?? '';
      if (detail.contains('401') || detail.contains('403')) {
        throw const AuthFailure(
          'the transcription service rejected the API key',
        );
      }
      throw const NetworkFailure('cannot reach the transcription service');
    } catch (_) {
      throw const NetworkFailure('cannot reach the transcription service');
    }
    return WebSocketRealtimeSocket(channel);
  }

  final WebSocketChannel _channel;

  @override
  Stream<Object?> get messages => _channel.stream;

  @override
  void send(Object data) => _channel.sink.add(data);

  @override
  Future<void> close() async {
    try {
      await _channel.sink.close();
    } catch (_) {
      // A socket the peer already tore down is closed either way.
    }
  }
}
