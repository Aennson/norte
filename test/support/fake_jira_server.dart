import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A real HTTP server that answers like Jira — both products.
///
/// The contract suite (S02-CT-01) needs `JiraRestAdapter` to be exercised
/// through an actual socket — mocking dio would test the mock, not the
/// adapter's URL building, header handling, status classification and JSON
/// reading, which is exactly where an adapter goes wrong.
///
/// It answers on `/rest/api/2/…` and `/rest/api/3/…` alike and accepts either
/// `Basic` or `Bearer`, so one server can stand in for a Cloud site and for a
/// Data Center one (DEC-012). What it does *not* do is paper over the
/// difference: [commentBodies] records what each request actually sent, and
/// the contract suite asserts that v3 got a document and v2 got a string.
///
/// It binds to the loopback interface on an ephemeral port, so it needs no
/// network and cannot collide with a parallel test
/// (`docs/testing-strategy.md` §1 — "local fake server").
class FakeJiraServer {
  FakeJiraServer._(this._server, this.issues);

  /// Starts a server preloaded with [issues] (key → status name).
  static Future<FakeJiraServer> start({
    Map<String, String> issues = const <String, String>{
      'PROJ-123': 'In Progress',
      'NORTE-1': 'To Do',
    },
  }) async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final FakeJiraServer fake = FakeJiraServer._(
      server,
      Map<String, String>.of(issues),
    );
    unawaited(fake._serve());
    return fake;
  }

  final HttpServer _server;

  /// Server-side issue state: key → status name.
  final Map<String, String> issues;

  /// Every request, as `METHOD /path`.
  final List<String> requests = <String>[];

  /// Bodies posted, in order.
  final List<Object?> bodies = <Object?>[];

  /// Every `Authorization` header value the server received.
  ///
  /// The redaction test asserts that what reached the wire is *not* what
  /// reached the log.
  final List<String> authorizations = <String>[];

  /// The `body` field of every comment posted, as it arrived — a `Map` from a
  /// v3 client, a `String` from a v2 one.
  final List<Object?> commentBodies = <Object?>[];

  /// REST versions the requests used, in order.
  final List<String> restVersions = <String>[];

  /// When set, every request is answered with this status instead.
  int? forceStatus;

  /// Value of `Retry-After` on a forced 429.
  String? retryAfter;

  /// When `true`, every request is answered **200 with an HTML login page** —
  /// what a self-hosted site behind single sign-on does to an unauthenticated
  /// REST call, and the shape that used to crash the adapter.
  bool forceSsoLoginPage = false;

  /// Base URL to hand to the adapter as the site URL.
  String get siteUrl => 'http://${_server.address.host}:${_server.port}';

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
    final String path = request.uri.path;
    requests.add('${request.method} $path');

    final String? authorization = request.headers.value('authorization');
    if (authorization != null) authorizations.add(authorization);

    final String raw = await utf8.decoder.bind(request).join();
    if (raw.isNotEmpty) bodies.add(jsonDecode(raw));

    if (forceSsoLoginPage) {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.html;
      request.response.write('<html><body>Sign in to continue</body></html>');
      return;
    }

    final int? forced = forceStatus;
    if (forced != null) {
      if (forced == 429 && retryAfter != null) {
        request.response.headers.set('retry-after', retryAfter!);
      }
      _write(request, forced, <String, Object?>{
        'errorMessages': <String>['forced'],
      });
      return;
    }

    // Unauthenticated requests are 401, so the adapter's Authorization header
    // is not merely decorative in these tests. Either scheme is accepted:
    // which one is correct for a site is the adapter's business, and the
    // contract suite checks it directly.
    if (authorization == null ||
        !(authorization.startsWith('Basic ') ||
            authorization.startsWith('Bearer '))) {
      _write(request, 401, <String, Object?>{
        'errorMessages': <String>['no credentials'],
      });
      return;
    }

    final RegExpMatch? version = RegExp(
      r'^/rest/api/([23])/issue',
    ).firstMatch(path);
    if (version == null) {
      _write(request, 404, <String, Object?>{});
      return;
    }
    restVersions.add(version.group(1)!);

    final String prefix = '/rest/api/${version.group(1)}/issue';
    if (request.method == 'POST' && path == prefix) {
      final String key = 'NEW-${issues.length + 1}';
      issues[key] = 'To Do';
      _write(request, 201, <String, Object?>{'key': key});
      return;
    }

    if (!path.startsWith('$prefix/')) {
      _write(request, 404, <String, Object?>{});
      return;
    }

    final List<String> segments = path.substring(prefix.length + 1).split('/');
    final String key = segments.first;
    final String? status = issues[key];
    if (status == null) {
      _write(request, 404, <String, Object?>{
        'errorMessages': <String>['Issue does not exist'],
      });
      return;
    }

    final String resource = segments.length > 1 ? segments[1] : '';
    switch ('${request.method} $resource') {
      case 'GET ':
        _write(request, 200, <String, Object?>{
          'key': key,
          'fields': <String, Object?>{
            'status': <String, Object?>{'name': status},
          },
        });
      case 'GET transitions':
        _write(request, 200, <String, Object?>{
          'transitions': <Object?>[
            for (final String name in const <String>[
              'To Do',
              'In Progress',
              'Done',
              'Blocked',
            ])
              if (name != status)
                <String, Object?>{
                  'id': '${name.hashCode.abs()}',
                  'to': <String, Object?>{'name': name},
                },
          ],
        });
      case 'POST transitions':
        issues[key] = _requestedTransition() ?? status;
        _write(request, 204, null);
      case 'POST comment':
        final Object? posted = bodies.last;
        commentBodies.add(
          posted is Map<String, Object?> ? posted['body'] : null,
        );
        _write(request, 201, <String, Object?>{'id': '10000'});
      default:
        _write(request, 404, <String, Object?>{});
    }
  }

  /// Resolves the transition id in the last posted body back to a status name.
  String? _requestedTransition() {
    final Object? body = bodies.isEmpty ? null : bodies.last;
    if (body is! Map<String, Object?>) return null;
    final Object? transition = body['transition'];
    if (transition is! Map<String, Object?>) return null;
    final Object? id = transition['id'];
    for (final String name in const <String>[
      'To Do',
      'In Progress',
      'Done',
      'Blocked',
    ]) {
      if ('${name.hashCode.abs()}' == id) return name;
    }
    return null;
  }

  void _write(HttpRequest request, int status, Object? body) {
    request.response.statusCode = status;
    if (body == null) return;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
  }
}
