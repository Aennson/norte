import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A real HTTP server that answers like the Claude Messages API.
///
/// The contract and integration suites need `ClaudeApiEngine` exercised
/// through an actual socket — mocking dio would test the mock, not the
/// adapter's headers, its URL, or its SSE reader, which is exactly where an
/// adapter goes wrong. Same reasoning, and same shape, as `FakeJiraServer`
/// (S02-CT-01).
///
/// It binds to loopback on an ephemeral port, so it needs no network and
/// cannot collide with a parallel test.
class FakeClaudeServer {
  FakeClaudeServer._(this._server);

  /// Starts a server that answers every request with [answer] as the assistant
  /// text, streamed as `content_block_delta` events.
  static Future<FakeClaudeServer> start({String answer = '{}'}) async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final FakeClaudeServer fake = FakeClaudeServer._(server)..answer = answer;
    unawaited(fake._serve());
    return fake;
  }

  final HttpServer _server;

  /// The assistant text to stream back.
  String answer = '{}';

  /// How many characters of [answer] to put in each delta.
  ///
  /// Small on purpose in the tests: an answer that arrives whole in one event
  /// would not exercise the accumulator at all.
  int chunkSize = 24;

  /// Every request, as `METHOD /path`.
  final List<String> requests = <String>[];

  /// Decoded request bodies, in order.
  final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];

  /// Headers of every request received, in order.
  final List<HttpHeaders> headers = <HttpHeaders>[];

  /// When set, every request is answered with this status instead.
  int? forceStatus;

  /// Value of `Retry-After` on a forced 429.
  String? retryAfter;

  /// When set, the stream carries this error event after [errorAfterChunks]
  /// deltas — a 200 that fails part-way, which must not read as a short but
  /// complete summary.
  String? streamErrorType;
  int errorAfterChunks = 1;

  /// When `true`, the response is a normal JSON body rather than an event
  /// stream — what a proxy that strips SSE, or a misconfigured gateway, does.
  bool answerWithoutSse = false;

  /// Base URL to hand the adapter.
  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  /// The `x-api-key` of the last request, or `null` when it carried none.
  String? get lastApiKey =>
      headers.isEmpty ? null : headers.last.value('x-api-key');

  /// The system blocks of the last request.
  List<Object?> get lastSystemBlocks => bodies.isEmpty
      ? const <Object?>[]
      : bodies.last['system'] as List<Object?>;

  Future<void> close() => _server.close(force: true);

  Future<void> _serve() async {
    await for (final HttpRequest request in _server) {
      try {
        await _handle(request);
      } finally {
        await request.response.close();
      }
    }
  }

  Future<void> _handle(HttpRequest request) async {
    requests.add('${request.method} ${request.uri.path}');
    headers.add(request.headers);

    final String raw = await utf8.decoder.bind(request).join();
    if (raw.isNotEmpty) {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) bodies.add(decoded);
    }

    final int? forced = forceStatus;
    if (forced != null) {
      request.response.statusCode = forced;
      if (forced == 429 && retryAfter != null) {
        request.response.headers.set('retry-after', retryAfter!);
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, Object?>{
          'type': 'error',
          'error': <String, Object?>{'type': 'invalid_request_error'},
        }),
      );
      return;
    }

    if (request.headers.value('x-api-key') == null) {
      request.response.statusCode = 401;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, Object?>{
          'type': 'error',
          'error': <String, Object?>{'type': 'authentication_error'},
        }),
      );
      return;
    }

    if (answerWithoutSse) {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(<String, Object?>{'ok': true}));
      return;
    }

    _writeStream(request.response);
  }

  void _writeStream(HttpResponse response) {
    response.statusCode = 200;
    response.headers.contentType = ContentType('text', 'event-stream');

    // Written as UTF-8 bytes rather than through `write`, which encodes
    // ISO-8859-1 and throws on the first accented character. A real
    // transcript is full of them, so anything else here would be the fake
    // failing on input the app must handle.
    void event(String type, Map<String, Object?> data) {
      response.add(utf8.encode('event: $type\ndata: ${jsonEncode(data)}\n\n'));
    }

    event('message_start', <String, Object?>{
      'type': 'message_start',
      'message': <String, Object?>{'id': 'msg_fake', 'model': 'fake'},
    });
    event('content_block_start', <String, Object?>{
      'type': 'content_block_start',
      'index': 0,
      'content_block': <String, Object?>{'type': 'text', 'text': ''},
    });

    // A thinking delta the adapter must ignore: concatenating it would
    // corrupt the JSON the codec has to read.
    event('content_block_delta', <String, Object?>{
      'type': 'content_block_delta',
      'index': 0,
      'delta': <String, Object?>{
        'type': 'thinking_delta',
        'thinking': 'considering the transcript…',
      },
    });

    int chunks = 0;
    for (int i = 0; i < answer.length; i += chunkSize) {
      final int end = (i + chunkSize).clamp(0, answer.length);
      event('content_block_delta', <String, Object?>{
        'type': 'content_block_delta',
        'index': 0,
        'delta': <String, Object?>{
          'type': 'text_delta',
          'text': answer.substring(i, end),
        },
      });
      chunks++;
      if (streamErrorType != null && chunks >= errorAfterChunks) {
        event('error', <String, Object?>{
          'type': 'error',
          'error': <String, Object?>{'type': streamErrorType},
        });
        return;
      }
    }

    event('content_block_stop', <String, Object?>{
      'type': 'content_block_stop',
      'index': 0,
    });
    event('message_delta', <String, Object?>{
      'type': 'message_delta',
      'delta': <String, Object?>{'stop_reason': 'end_turn'},
    });
    event('message_stop', <String, Object?>{'type': 'message_stop'});
  }
}
