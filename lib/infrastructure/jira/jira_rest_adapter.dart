import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/entities/jira_credentials.dart';
import '../../domain/entities/jira_issue_snapshot.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/jira_credential_store.dart';
import '../../domain/ports/jira_gateway.dart';
import 'redacting_log_interceptor.dart';

/// [JiraGateway] over the Jira Cloud REST API v3.
///
/// **Authentication** is Basic with an API token (`docs/architecture.md`
/// §4.2). The token is read from the [JiraCredentialStore] on each request
/// and turned into an `Authorization` header — it is never held in a field,
/// never written to a config, and never reaches a log (BR-08, enforced by
/// [RedactingLogInterceptor]).
///
/// **Idempotency.** Jira Cloud offers no idempotency-key header, so the
/// `operationId` guarantee of BR-05 is delivered by the outbox: an operation
/// is one row keyed by its id, and the dispatcher applies it at most once.
/// What this adapter adds on top is what the API actually allows:
///
/// * a transition whose target status the issue already holds is reported as
///   success rather than as an error, so replaying one is harmless;
/// * a comment is posted with its `operationId` in a comment property, which
///   makes a duplicate identifiable after the fact.
///
/// Creating an issue has no such affordance and relies on the queue alone.
///
/// **Errors.** Every transport outcome becomes a [Failure]; a `DioException`
/// never escapes (`docs/project-rules.md` §6).
class JiraRestAdapter implements JiraGateway {
  JiraRestAdapter({
    required this.dio,
    required this.credentialStore,
    JiraLogSink? log,
  }) {
    if (log != null) dio.interceptors.add(RedactingLogInterceptor(log));
  }

  final Dio dio;
  final JiraCredentialStore credentialStore;

  /// Property key the `operationId` of a comment is filed under.
  static const String operationIdProperty = 'norte.operationId';

  @override
  Future<JiraIssueSnapshot> getIssue(String issueKey) async {
    final JiraCredentials credentials = await _credentials();
    final Map<String, Object?> body = await _send<Map<String, Object?>>(
      credentials,
      method: 'GET',
      path: '/rest/api/3/issue/$issueKey',
      query: const <String, Object?>{'fields': 'status'},
    );
    return JiraIssueSnapshot(
      issueKey: body['key'] as String? ?? issueKey,
      siteUrl: credentials.siteUrl,
      status: _statusNameOf(body),
    );
  }

  @override
  Future<String> getStatus(String issueKey) async =>
      (await getIssue(issueKey)).status;

  /// Two calls, because a Jira transition is identified by an id that depends
  /// on where the issue currently sits: read the transitions available from
  /// the issue's present status, then post the one whose target is [status].
  @override
  Future<void> transitionIssue({
    required String issueKey,
    required String status,
    required String operationId,
  }) async {
    final JiraCredentials credentials = await _credentials();
    final Map<String, Object?> body = await _send<Map<String, Object?>>(
      credentials,
      method: 'GET',
      path: '/rest/api/3/issue/$issueKey/transitions',
    );

    final String? transitionId = _transitionIdFor(body, status);
    if (transitionId == null) {
      // Either the issue is already where it is being asked to go — which is
      // what a replay looks like, and is a success — or the workflow has no
      // route there, which the user must resolve in Jira.
      final String current = await getStatus(issueKey);
      if (current.toLowerCase() == status.toLowerCase()) return;
      throw ValidationFailure(
        'no transition to "$status" from "$current" on $issueKey',
        'status',
      );
    }

    await _send<Map<String, Object?>?>(
      credentials,
      method: 'POST',
      path: '/rest/api/3/issue/$issueKey/transitions',
      body: <String, Object?>{
        'transition': <String, Object?>{'id': transitionId},
      },
    );
  }

  @override
  Future<void> addComment({
    required String issueKey,
    required String body,
    required String operationId,
  }) async {
    final JiraCredentials credentials = await _credentials();
    await _send<Map<String, Object?>?>(
      credentials,
      method: 'POST',
      path: '/rest/api/3/issue/$issueKey/comment',
      body: <String, Object?>{
        'body': _document(body),
        'properties': <Object?>[
          <String, Object?>{
            'key': operationIdProperty,
            'value': <String, Object?>{'operationId': operationId},
          },
        ],
      },
    );
  }

  @override
  Future<JiraIssueSnapshot> createIssue({
    required String projectKey,
    required String summary,
    required String operationId,
    String? description,
  }) async {
    final JiraCredentials credentials = await _credentials();
    final Map<String, Object?> created = await _send<Map<String, Object?>>(
      credentials,
      method: 'POST',
      path: '/rest/api/3/issue',
      body: <String, Object?>{
        'fields': <String, Object?>{
          'project': <String, Object?>{'key': projectKey},
          'summary': summary,
          'issuetype': <String, Object?>{'name': 'Task'},
          if (description != null && description.isNotEmpty)
            'description': _document(description),
        },
      },
    );

    final String key = created['key']! as String;
    return getIssue(key);
  }

  /// The credentials, or [AuthFailure] when the user has not configured Jira.
  Future<JiraCredentials> _credentials() async {
    final JiraCredentials? credentials = await credentialStore.read();
    if (credentials == null || !credentials.isComplete) {
      throw const AuthFailure('Jira is not configured');
    }
    return credentials;
  }

  /// Performs one request and translates every outcome into either a value or
  /// a [Failure].
  Future<T> _send<T>(
    JiraCredentials credentials, {
    required String method,
    required String path,
    Map<String, Object?>? query,
    Object? body,
  }) async {
    try {
      final Response<Object?> response = await dio.request<Object?>(
        '${_baseOf(credentials.siteUrl)}$path',
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: <String, Object?>{
            'Authorization': _basicAuth(credentials),
            'Accept': 'application/json',
            if (body != null) 'Content-Type': 'application/json',
          },
          // Statuses are classified below rather than thrown as generic dio
          // errors, so the mapping lives in exactly one place.
          validateStatus: (int? status) => status != null && status < 500,
        ),
      );
      final int status = response.statusCode ?? 0;
      if (status >= 400) throw _failureFor(status, response.headers);
      return response.data as T;
    } on DioException catch (error) {
      throw _failureForDio(error);
    }
  }

  String _basicAuth(JiraCredentials credentials) {
    final String pair = '${credentials.email}:${credentials.apiToken}';
    return 'Basic ${base64Encode(utf8.encode(pair))}';
  }

  Failure _failureFor(int status, Headers headers) => switch (status) {
    401 || 403 => const AuthFailure('Jira rejected the credentials'),
    404 => const NotFoundFailure('the Jira site has no such issue'),
    429 => RateLimitFailure(
      'Jira is throttling requests',
      _retryAfter(headers),
    ),
    _ => EngineFailure('Jira answered $status'),
  };

  Failure _failureForDio(DioException error) {
    final Object? thrown = error.error;
    if (thrown is Failure) return thrown;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const TimeoutFailure(
        'Jira did not answer in time',
      ),
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => const NetworkFailure('cannot reach Jira'),
      DioExceptionType.badCertificate => const NetworkFailure(
        'the Jira site presented an untrusted certificate',
      ),
      DioExceptionType.cancel => const NetworkFailure('request cancelled'),
      DioExceptionType.badResponse => _failureFor(
        error.response?.statusCode ?? 0,
        error.response?.headers ?? Headers(),
      ),
    };
  }

  Duration? _retryAfter(Headers headers) {
    final String? value = headers.value('retry-after');
    final int? seconds = value == null ? null : int.tryParse(value);
    return seconds == null ? null : Duration(seconds: seconds);
  }
}

/// `siteUrl` without a trailing slash, so paths concatenate cleanly.
String _baseOf(String siteUrl) =>
    siteUrl.endsWith('/') ? siteUrl.substring(0, siteUrl.length - 1) : siteUrl;

/// `fields.status.name` — the only field the app reads (BR-09).
String _statusNameOf(Map<String, Object?> issue) {
  final Object? fields = issue['fields'];
  if (fields is! Map<String, Object?>) return '';
  final Object? status = fields['status'];
  if (status is! Map<String, Object?>) return '';
  return status['name'] as String? ?? '';
}

/// The id of the transition leading to [status], or `null` when the workflow
/// offers none from where the issue currently is.
String? _transitionIdFor(Map<String, Object?> body, String status) {
  final Object? transitions = body['transitions'];
  if (transitions is! List<Object?>) return null;
  for (final Object? entry in transitions) {
    if (entry is! Map<String, Object?>) continue;
    final Object? to = entry['to'];
    final String? name = to is Map<String, Object?>
        ? to['name'] as String?
        : null;
    if (name != null && name.toLowerCase() == status.toLowerCase()) {
      return entry['id']?.toString();
    }
  }
  return null;
}

/// Wraps [text] in the minimal Atlassian Document Format node the v3 API
/// expects wherever v2 took a plain string.
Map<String, Object?> _document(String text) => <String, Object?>{
  'type': 'doc',
  'version': 1,
  'content': <Object?>[
    <String, Object?>{
      'type': 'paragraph',
      'content': <Object?>[
        <String, Object?>{'type': 'text', 'text': text},
      ],
    },
  ],
};
