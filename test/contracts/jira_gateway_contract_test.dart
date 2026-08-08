import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_credentials.dart';
import 'package:norte/domain/entities/jira_issue_snapshot.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/jira_gateway.dart';
import 'package:norte/infrastructure/jira/jira_rest_adapter.dart';

import '../fakes/fakes.dart';
import '../support/fake_jira_server.dart';

/// One adapter under test, plus the levers the suite needs to drive it.
///
/// The suite never touches an adapter's own API — only this, so that adding a
/// third implementation later means writing one of these and nothing else.
class _Subject {
  _Subject({
    required this.gateway,
    required this.forceUnauthorized,
    required this.forceRateLimited,
    required this.dispose,
  });

  final JiraGateway gateway;
  final void Function() forceUnauthorized;
  final void Function() forceRateLimited;
  final Future<void> Function() dispose;
}

/// Builds a REST subject for [deployment] against its own fake server.
Future<_Subject> _restSubject(
  JiraDeployment deployment,
  Map<String, String> issues,
) async {
  final FakeJiraServer server = await FakeJiraServer.start(issues: issues);
  return _Subject(
    gateway: JiraRestAdapter(
      dio: Dio(),
      credentialStore: FakeJiraCredentialStore(
        JiraCredentials(
          siteUrl: server.siteUrl,
          email: deployment.needsEmail ? 'dev@example.com' : '',
          apiToken: 'synthetic-token',
          deployment: deployment,
        ),
      ),
    ),
    forceUnauthorized: () => server.forceStatus = 401,
    forceRateLimited: () => server.forceStatus = 429,
    dispose: server.close,
  );
}

/// S02-CT-01 — the same stimuli against every [JiraGateway] implementation.
///
/// The point of a contract suite is that the layers above cannot tell which
/// adapter they are holding (`docs/testing-strategy.md` §1). If the fake
/// answers a missing issue with a `NotFoundFailure` and the REST adapter
/// answers with something else, then every test written against the fake is
/// worth nothing — so both go through this, and CI runs both.
void main() {
  /// The issues both adapters start from. `PROJ-123` exists, `NOPE-1` does
  /// not, and both implementations agree about which is which.
  const Map<String, String> issues = <String, String>{
    'PROJ-123': 'In Progress',
    'NORTE-1': 'To Do',
  };

  final Map<String, Future<_Subject> Function()> adapters =
      <String, Future<_Subject> Function()>{
        'FakeJiraGateway': () async {
          final FakeJiraGateway fake = FakeJiraGateway(
            issues: <String, JiraIssueSnapshot>{
              for (final MapEntry<String, String> entry in issues.entries)
                entry.key: JiraIssueSnapshot(
                  issueKey: entry.key,
                  siteUrl: FakeJiraGateway.siteUrl,
                  status: entry.value,
                ),
            },
          );
          return _Subject(
            gateway: fake,
            forceUnauthorized: () => fake.failWith = const AuthFailure(),
            forceRateLimited: () => fake.failWith = const RateLimitFailure(),
            dispose: () async {},
          );
        },
        'JiraRestAdapter (Cloud)': () =>
            _restSubject(JiraDeployment.cloud, issues),
        'JiraRestAdapter (Data Center)': () =>
            _restSubject(JiraDeployment.dataCenter, issues),
      };

  for (final MapEntry<String, Future<_Subject> Function()> entry
      in adapters.entries) {
    group(entry.key, () {
      late _Subject subject;

      setUp(() async => subject = await entry.value());
      tearDown(() => subject.dispose());

      test('S02-CT-01: an existing issue reads back', () async {
        final JiraIssueSnapshot issue = await subject.gateway.getIssue(
          'PROJ-123',
        );

        expect(issue.issueKey, 'PROJ-123');
        expect(issue.status, 'In Progress');
        expect(issue.siteUrl, isNotEmpty);
      });

      test('S02-CT-01: getStatus agrees with getIssue', () async {
        expect(await subject.gateway.getStatus('PROJ-123'), 'In Progress');
      });

      test('S02-CT-01: a missing issue is a NotFoundFailure', () async {
        await expectLater(
          subject.gateway.getIssue('NOPE-1'),
          throwsA(isA<NotFoundFailure>()),
        );
      });

      test('S02-CT-01: rejected credentials are an AuthFailure', () async {
        subject.forceUnauthorized();

        await expectLater(
          subject.gateway.getIssue('PROJ-123'),
          throwsA(isA<AuthFailure>()),
        );
      });

      test('S02-CT-01: throttling is a RateLimitFailure', () async {
        subject.forceRateLimited();

        await expectLater(
          subject.gateway.getIssue('PROJ-123'),
          throwsA(isA<RateLimitFailure>()),
        );
      });

      test('S02-CT-01: a comment on an existing issue succeeds', () async {
        await expectLater(
          subject.gateway.addComment(
            issueKey: 'PROJ-123',
            body: 'deployed to staging',
            operationId: 'op-1',
          ),
          completes,
        );
      });

      test('S02-CT-01: a transition moves the issue', () async {
        await subject.gateway.transitionIssue(
          issueKey: 'PROJ-123',
          status: 'Done',
          operationId: 'op-1',
        );

        expect(await subject.gateway.getStatus('PROJ-123'), 'Done');
      });

      test('S02-CT-01: creating an issue returns a usable snapshot', () async {
        final JiraIssueSnapshot created = await subject.gateway.createIssue(
          projectKey: 'NEW',
          summary: 'Review the connector PR',
          operationId: 'op-1',
        );

        expect(created.issueKey, startsWith('NEW-'));
        expect(created.siteUrl, isNotEmpty);
        expect(created.status, isNotEmpty);
        // And the site knows about it afterwards.
        expect(
          (await subject.gateway.getIssue(created.issueKey)).issueKey,
          created.issueKey,
        );
      });

      test(
        'S02-CT-01: transitioning to the status already held is not an error',
        () async {
          await expectLater(
            subject.gateway.transitionIssue(
              issueKey: 'PROJ-123',
              status: 'In Progress',
              operationId: 'op-1',
            ),
            completes,
          );
        },
      );
    });
  }

  group('the wire format each product expects', () {
    late FakeJiraServer server;

    Future<JiraRestAdapter> adapterFor(JiraDeployment deployment) async {
      server = await FakeJiraServer.start(issues: issues);
      return JiraRestAdapter(
        dio: Dio(),
        credentialStore: FakeJiraCredentialStore(
          JiraCredentials(
            siteUrl: server.siteUrl,
            email: deployment.needsEmail ? 'dev@example.com' : '',
            apiToken: 'synthetic-token',
            deployment: deployment,
          ),
        ),
      );
    }

    tearDown(() => server.close());

    test('S02-CT-01: Cloud speaks v3, Basic and ADF', () async {
      final JiraRestAdapter adapter = await adapterFor(JiraDeployment.cloud);

      await adapter.addComment(
        issueKey: 'PROJ-123',
        body: 'shipped',
        operationId: 'op-1',
      );

      expect(server.restVersions, everyElement('3'));
      expect(server.authorizations.single, startsWith('Basic '));
      expect(server.commentBodies.single, isA<Map<String, Object?>>());
    });

    test('S02-CT-01: Data Center speaks v2, Bearer and plain text', () async {
      final JiraRestAdapter adapter = await adapterFor(
        JiraDeployment.dataCenter,
      );

      await adapter.addComment(
        issueKey: 'PROJ-123',
        body: 'shipped',
        operationId: 'op-1',
      );

      expect(server.restVersions, everyElement('2'));
      // The PAT goes as a bearer, and the account e-mail never appears.
      expect(server.authorizations.single, 'Bearer synthetic-token');
      expect(server.commentBodies.single, 'shipped');
    });

    test(
      'S02-CT-01: a Data Center credential needs no e-mail to be complete',
      () async {
        const JiraCredentials pat = JiraCredentials(
          siteUrl: 'https://jira.example.com',
          email: '',
          apiToken: 'synthetic-token',
          deployment: JiraDeployment.dataCenter,
        );

        expect(pat.isComplete, isTrue);
        // …whereas a Cloud one does.
        expect(
          const JiraCredentials(
            siteUrl: 'https://example.atlassian.net',
            email: '',
            apiToken: 'synthetic-token',
          ).isComplete,
          isFalse,
        );
      },
    );
  });
}
