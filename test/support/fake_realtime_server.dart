import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A real WebSocket server that records the handshake.
///
/// `FakeRealtimeSocket` stands in for the *transport* in the engine's tests,
/// which is what makes an outage reproducible. It cannot answer the one
/// question that matters about `WebSocketRealtimeSocket` itself: **does the
/// API key actually leave the machine?**
///
/// It did not, in the first draft — the key was accepted as an argument and
/// dropped, because `WebSocketChannel.connect` sends no headers and no test
/// went near the real class (0 of 14 lines covered). This server exists so
/// that cannot happen again silently.
///
/// Binds to loopback on an ephemeral port, so it needs no network and cannot
/// collide with a parallel test. Same shape as `FakeClaudeServer` and
/// `FakeJiraServer`.
class FakeRealtimeServer {
  FakeRealtimeServer._(this._server);

  /// Starts a server that upgrades any request to a WebSocket.
  static Future<FakeRealtimeServer> start() async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final FakeRealtimeServer fake = FakeRealtimeServer._(server);
    unawaited(fake._serve());
    return fake;
  }

  final HttpServer _server;

  /// Headers of every handshake received, in order.
  final List<HttpHeaders> handshakes = <HttpHeaders>[];

  /// Query parameters of every handshake, in order.
  final List<Map<String, String>> queries = <Map<String, String>>[];

  /// Sockets accepted, in order.
  final List<WebSocket> sockets = <WebSocket>[];

  /// When set, the handshake is refused with this status instead of upgraded.
  int? refuseWith;

  /// Base URL to hand the adapter.
  String get baseUrl => 'ws://${_server.address.host}:${_server.port}';

  /// The value of [header] on the last handshake, or `null`.
  String? headerOf(String header) =>
      handshakes.isEmpty ? null : handshakes.last.value(header);

  /// Everything the last socket received, as text frames.
  final List<Object?> received = <Object?>[];

  Future<void> close() async {
    for (final WebSocket socket in sockets) {
      await socket.close();
    }
    await _server.close(force: true);
  }

  Future<void> _serve() async {
    await for (final HttpRequest request in _server) {
      handshakes.add(request.headers);
      queries.add(request.uri.queryParameters);

      final int? refused = refuseWith;
      if (refused != null) {
        request.response.statusCode = refused;
        await request.response.close();
        continue;
      }

      final WebSocket socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.listen(received.add, onError: (Object _) {}, onDone: () {});
    }
  }

  /// Pushes a committed transcript to the last accepted socket.
  void emitCommitted(String text) {
    if (sockets.isEmpty) return;
    sockets.last.add(
      jsonEncode(<String, Object?>{'type': 'final_transcript', 'text': text}),
    );
  }
}
