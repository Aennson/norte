import 'package:dio/dio.dart';

/// Where a log line goes. Injectable so a test can capture what was written
/// (S02-IT-04) and so the app can send it wherever diagnostics live.
typedef JiraLogSink = void Function(String line);

/// The dio interceptor that makes Jira traffic loggable at all.
///
/// **BR-08** — a token lives in secure storage and nowhere else, and a log
/// file is very much "somewhere else". The guarantee here is structural
/// rather than best-effort:
///
/// * **Bodies are never logged.** Not redacted, not truncated — not logged.
///   A request body carries the user's comment text; a response body carries
///   whatever Jira felt like returning. Neither belongs in a diagnostic line,
///   so there is no code path that writes one.
/// * **Sensitive headers are replaced** by [_redacted] before the line is
///   built, so the value never enters the string in the first place.
/// * **Every finished line is swept** by [redact] as a backstop, in case a
///   credential reaches it by a route this class did not anticipate — a
///   `Basic ...` in a redirect URL, a token echoed in an error message.
class RedactingLogInterceptor extends Interceptor {
  RedactingLogInterceptor(this.log);

  final JiraLogSink log;

  static const String _redacted = '[REDACTED]';

  /// Headers whose value is a credential.
  static const Set<String> sensitiveHeaders = <String>{
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-atlassian-token',
  };

  /// Replaces anything credential-shaped in [line] with `[REDACTED]`.
  ///
  /// Covers the two shapes a Jira credential can take on the wire: an
  /// `Authorization` value (`Basic <base64>`, `Bearer <jwt>`) and the
  /// `user:token@host` form of a URL's userinfo.
  static String redact(String line) => line
      .replaceAll(
        RegExp(r'(Basic|Bearer)\s+[A-Za-z0-9\-._~+/=]+', caseSensitive: false),
        _redacted,
      )
      .replaceAllMapped(
        RegExp(r'(https?://)[^/\s:@]+:[^/\s@]+@', caseSensitive: false),
        (Match match) => '${match.group(1)}$_redacted@',
      );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log(
      redact(
        '→ ${options.method} ${options.uri.path} '
        'headers=${_safeHeaders(options.headers)}',
      ),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    // The content type and the decoded Dart type, never the body itself
    // (BR-08). Between them they answer the only question a 2xx that the
    // adapter could not read leaves open: what did the site actually send?
    log(
      redact(
        '← ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri.path} '
        '${response.headers.value(Headers.contentTypeHeader) ?? 'no type'} '
        'as ${response.data.runtimeType}',
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log(
      redact(
        '✗ ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${err.requestOptions.uri.path}',
      ),
    );
    handler.next(err);
  }

  /// [headers] with every sensitive value swapped out — the redaction happens
  /// before the map is stringified, not after.
  Map<String, Object?> _safeHeaders(Map<String, Object?> headers) {
    return <String, Object?>{
      for (final MapEntry<String, Object?> entry in headers.entries)
        entry.key: sensitiveHeaders.contains(entry.key.toLowerCase())
            ? _redacted
            : entry.value,
    };
  }
}
