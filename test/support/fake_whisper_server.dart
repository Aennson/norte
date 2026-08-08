import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A real HTTP server that answers like the Whisper transcriptions API.
///
/// Same reasoning as `FakeClaudeServer` and `FakeJiraServer`: the integration
/// and contract suites need `WhisperBatchEngine` driven through an actual
/// socket. Mocking dio would test the mock rather than the multipart body, the
/// authorization header or the URL — which is precisely where an upload
/// adapter goes wrong.
///
/// It binds to loopback on an ephemeral port, so it needs no network and
/// cannot collide with a parallel test.
class FakeWhisperServer {
  FakeWhisperServer._(this._server);

  /// Starts a server that transcribes every upload as [text].
  static Future<FakeWhisperServer> start({
    String text = 'the transcript',
    String language = 'pt',
  }) async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final FakeWhisperServer fake = FakeWhisperServer._(server)
      ..text = text
      ..language = language;
    unawaited(fake._serve());
    return fake;
  }

  final HttpServer _server;

  /// The text to answer with.
  String text = 'the transcript';

  /// The language the service claims to have detected.
  String language = 'pt';

  /// Every request, as `METHOD /path`.
  final List<String> requests = <String>[];

  /// Headers of every request received, in order.
  final List<HttpHeaders> headers = <HttpHeaders>[];

  /// Raw multipart bodies, in order.
  final List<String> bodies = <String>[];

  /// When set, every request is answered with this status instead.
  int? forceStatus;

  /// When `true`, the answer is HTML rather than JSON — what a captive portal
  /// or a misconfigured proxy returns with a 200.
  bool answerWithHtml = false;

  /// When set, replaces the JSON body entirely.
  String? rawAnswer;

  /// Base URL to hand the adapter.
  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  /// The `authorization` header of the last request.
  String? get lastAuthorization =>
      headers.isEmpty ? null : headers.last.value('authorization');

  /// The last multipart body, for asserting the fields it carried.
  String get lastBody => bodies.isEmpty ? '' : bodies.last;

  /// Whether the last upload carried a form field named [name], and what it
  /// was set to.
  String? fieldOf(String name) {
    final RegExp pattern = RegExp(
      'name="$name"\r\n\r\n(.*?)\r\n',
      dotAll: true,
    );
    return pattern.firstMatch(lastBody)?.group(1);
  }

  /// Whether the last upload carried a file part, and under what filename.
  String? get uploadedFilename =>
      RegExp(r'name="file"; filename="([^"]+)"').firstMatch(lastBody)?.group(1);

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

    // Latin-1 rather than UTF-8: a multipart body carries raw file bytes that
    // are not valid UTF-8, and decoding them strictly would throw before the
    // assertions about the *fields* could run.
    bodies.add(await latin1.decoder.bind(request).join());

    final int? forced = forceStatus;
    if (forced != null) {
      request.response.statusCode = forced;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, Object?>{
          'error': <String, Object?>{'message': 'forced'},
        }),
      );
      return;
    }

    if (request.headers.value('authorization') == null) {
      request.response.statusCode = 401;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, Object?>{
          'error': <String, Object?>{'message': 'no key'},
        }),
      );
      return;
    }

    request.response.statusCode = 200;
    if (answerWithHtml) {
      request.response.headers.contentType = ContentType.html;
      request.response.write('<html><body>sign in</body></html>');
      return;
    }

    request.response.headers.contentType = ContentType.json;
    request.response.write(
      rawAnswer ??
          jsonEncode(<String, Object?>{
            'text': text,
            'language': language,
            'duration': 12.5,
          }),
    );
  }
}
