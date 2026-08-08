import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_credentials.dart';
import 'package:norte/domain/entities/jira_issue_snapshot.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/infrastructure/jira/jira_rest_adapter.dart';
import 'package:norte/infrastructure/jira/redacting_log_interceptor.dart';

import '../fakes/fakes.dart';
import '../support/fake_jira_server.dart';

void main() {
  /// Synthetic, and shaped like the real thing: an Atlassian API token is a
  /// long opaque string, which is exactly what must not turn up in a log.
  const String token = 'ATATT3xFfGF0-synthetic-token-value-9c1d4e';
  const String email = 'dev@example.com';

  late FakeJiraServer server;
  late FakeJiraCredentialStore credentials;
  late List<String> log;
  late JiraRestAdapter adapter;

  setUp(() async {
    server = await FakeJiraServer.start();
    credentials = FakeJiraCredentialStore(
      JiraCredentials(siteUrl: server.siteUrl, email: email, apiToken: token),
    );
    log = <String>[];
    adapter = JiraRestAdapter(
      dio: Dio(),
      credentialStore: credentials,
      log: log.add,
    );
  });

  tearDown(() => server.close());

  test('S02-IT-04: the log never carries the credentials (BR-08)', () async {
    final JiraIssueSnapshot issue = await adapter.getIssue('PROJ-123');
    expect(issue.status, 'In Progress');

    // The request really did authenticate — otherwise this test would be
    // asserting that a header nobody sent is absent from the log.
    expect(server.authorizations, isNotEmpty);
    final String sent = server.authorizations.single;
    expect(sent, startsWith('Basic '));
    expect(
      utf8.decode(base64Decode(sent.substring('Basic '.length))),
      '$email:$token',
    );

    // And what was logged carries none of it.
    expect(log, isNotEmpty);
    final String transcript = log.join('\n');
    expect(transcript, contains('[REDACTED]'));
    expect(transcript, isNot(contains(token)));
    expect(transcript, isNot(contains(sent.substring('Basic '.length))));
    expect(transcript.toLowerCase(), isNot(contains('basic ')));

    // The line is still useful: method, path and status survive.
    expect(transcript, contains('GET'));
    expect(transcript, contains('/rest/api/3/issue/PROJ-123'));
    expect(transcript, contains('200'));
  });

  test('S02-IT-04: a body is never logged at all', () async {
    await adapter.addComment(
      issueKey: 'PROJ-123',
      body: 'the staging deploy is on hold',
      operationId: 'op-1',
    );

    final String transcript = log.join('\n');
    expect(transcript, isNot(contains('staging deploy')));
    expect(transcript, contains('/rest/api/3/issue/PROJ-123/comment'));
  });

  test('S02-IT-04: an error line is redacted too', () async {
    server.forceStatus = 401;

    await expectLater(
      adapter.getIssue('PROJ-123'),
      throwsA(isA<AuthFailure>()),
    );

    final String transcript = log.join('\n');
    expect(transcript, isNot(contains(token)));
    expect(transcript, contains('401'));
  });

  group('RedactingLogInterceptor.redact', () {
    test('replaces every credential shape it knows', () {
      expect(
        RedactingLogInterceptor.redact('authorization: Basic YWJjOmRlZg=='),
        'authorization: [REDACTED]',
      );
      expect(
        RedactingLogInterceptor.redact('Bearer eyJhbGciOiJIUzI1NiJ9.abc'),
        '[REDACTED]',
      );
      expect(
        RedactingLogInterceptor.redact('https://dev:secret@site.atlassian.net'),
        'https://[REDACTED]@site.atlassian.net',
      );
    });

    test('leaves an ordinary line alone', () {
      expect(
        RedactingLogInterceptor.redact('→ GET /rest/api/3/issue/PROJ-123'),
        '→ GET /rest/api/3/issue/PROJ-123',
      );
    });
  });

  test('an unconfigured site fails before a socket is opened', () async {
    final JiraRestAdapter unconfigured = JiraRestAdapter(
      dio: Dio(),
      credentialStore: FakeJiraCredentialStore(),
    );

    await expectLater(
      unconfigured.getIssue('PROJ-123'),
      throwsA(isA<AuthFailure>()),
    );
    expect(server.requests, isEmpty);
  });

  test('a partially filled credential set is treated as none', () async {
    final JiraRestAdapter partial = JiraRestAdapter(
      dio: Dio(),
      credentialStore: FakeJiraCredentialStore(
        JiraCredentials(siteUrl: server.siteUrl, email: email, apiToken: '  '),
      ),
    );

    await expectLater(
      partial.getIssue('PROJ-123'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('a trailing slash on the site URL does not double up', () async {
    final JiraRestAdapter trailing = JiraRestAdapter(
      dio: Dio(),
      credentialStore: FakeJiraCredentialStore(
        JiraCredentials(
          siteUrl: '${server.siteUrl}/',
          email: email,
          apiToken: token,
        ),
      ),
    );

    await trailing.getIssue('PROJ-123');

    expect(server.requests, <String>['GET /rest/api/3/issue/PROJ-123']);
  });

  test('a 429 carries Retry-After through to the failure', () async {
    server
      ..forceStatus = 429
      ..retryAfter = '30';

    await expectLater(
      adapter.getIssue('PROJ-123'),
      throwsA(
        isA<RateLimitFailure>().having(
          (RateLimitFailure f) => f.retryAfter,
          'retryAfter',
          const Duration(seconds: 30),
        ),
      ),
    );
  });

  test('a 500 is an engine failure, not a network one', () async {
    server.forceStatus = 500;

    await expectLater(
      adapter.getIssue('PROJ-123'),
      throwsA(isA<EngineFailure>()),
    );
  });

  test('an unreachable host is a network failure', () async {
    await server.close();

    await expectLater(
      adapter.getIssue('PROJ-123'),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('a transition is resolved to its workflow id and posted', () async {
    await adapter.transitionIssue(
      issueKey: 'PROJ-123',
      status: 'Done',
      operationId: 'op-1',
    );

    expect(server.requests, <String>[
      'GET /rest/api/3/issue/PROJ-123/transitions',
      'POST /rest/api/3/issue/PROJ-123/transitions',
    ]);
    expect(server.issues['PROJ-123'], 'Done');
  });

  test('transitioning to where the issue already is succeeds', () async {
    // The replay case: the site has already applied it, so the workflow no
    // longer offers a route there. That is a success, not an error.
    await adapter.transitionIssue(
      issueKey: 'PROJ-123',
      status: 'In Progress',
      operationId: 'op-1',
    );

    expect(server.issues['PROJ-123'], 'In Progress');
  });

  test(
    'a transition the workflow does not offer is a validation failure',
    () async {
      await expectLater(
        adapter.transitionIssue(
          issueKey: 'PROJ-123',
          status: 'Awaiting Legal Review',
          operationId: 'op-1',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );

  test('a comment carries its operationId as a property', () async {
    await adapter.addComment(
      issueKey: 'PROJ-123',
      body: 'shipped',
      operationId: 'op-42',
    );

    final Map<String, Object?> body =
        server.bodies.last! as Map<String, Object?>;
    final List<Object?> properties = body['properties']! as List<Object?>;
    final Map<String, Object?> property =
        properties.single! as Map<String, Object?>;
    expect(property['key'], JiraRestAdapter.operationIdProperty);
    expect(
      (property['value']! as Map<String, Object?>)['operationId'],
      'op-42',
    );
  });

  test('a comment body is sent as an ADF document', () async {
    await adapter.addComment(
      issueKey: 'PROJ-123',
      body: 'shipped',
      operationId: 'op-1',
    );

    final Map<String, Object?> body =
        server.bodies.last! as Map<String, Object?>;
    final Map<String, Object?> document = body['body']! as Map<String, Object?>;
    expect(document['type'], 'doc');
    expect(document['version'], 1);
  });

  test('creating an issue returns the snapshot of what was created', () async {
    final JiraIssueSnapshot created = await adapter.createIssue(
      projectKey: 'NEW',
      summary: 'Review the connector PR',
      operationId: 'op-1',
      description: 'Second pass on the retry logic.',
    );

    expect(created.issueKey, startsWith('NEW-'));
    expect(created.status, 'To Do');
    expect(created.siteUrl, server.siteUrl);

    final Map<String, Object?> body =
        (server.bodies.first! as Map<String, Object?>)['fields']!
            as Map<String, Object?>;
    expect((body['project']! as Map<String, Object?>)['key'], 'NEW');
    expect(body['summary'], 'Review the connector PR');
    expect(body['description'], isNotNull);
  });

  test('getStatus reads only the status field', () async {
    expect(await adapter.getStatus('PROJ-123'), 'In Progress');
    expect(server.requests.single, 'GET /rest/api/3/issue/PROJ-123');
  });

  group('a response that is not the REST API (regression)', () {
    // The defect the Developer hit during the manual pass: a self-hosted site
    // behind SSO answers 200 with an HTML login page. `response.data as T`
    // threw a raw TypeError, which is neither a DioException nor a Failure,
    // so it escaped the adapter, escaped the use case's `on Failure`, and
    // died as an unhandled async error — the user's action vanished in
    // silence.

    setUp(() => server.forceSsoLoginPage = true);

    test('a read fails loudly instead of throwing past the caller', () async {
      await expectLater(
        adapter.getIssue('PROJ-123'),
        throwsA(
          isA<JiraUnreadableResponseFailure>().having(
            (JiraUnreadableResponseFailure f) => f.message,
            'message',
            contains('single sign-on'),
          ),
        ),
      );
    });

    test('so does a status read', () async {
      await expectLater(
        adapter.getStatus('PROJ-123'),
        throwsA(isA<JiraUnreadableResponseFailure>()),
      );
    });

    test('so does a transition', () async {
      await expectLater(
        adapter.transitionIssue(
          issueKey: 'PROJ-123',
          status: 'Done',
          operationId: 'op-1',
        ),
        throwsA(isA<JiraUnreadableResponseFailure>()),
      );
    });

    test('so does creating an issue', () async {
      await expectLater(
        adapter.createIssue(
          projectKey: 'NEW',
          summary: 'x',
          operationId: 'op-1',
        ),
        throwsA(isA<JiraUnreadableResponseFailure>()),
      );
    });

    test('nothing but a Failure ever leaves the adapter', () async {
      // The general guarantee, stated as an assertion: whatever the site
      // does, the caller sees a Failure it can pattern-match on.
      await expectLater(adapter.getIssue('PROJ-123'), throwsA(isA<Failure>()));
    });
  });
}
