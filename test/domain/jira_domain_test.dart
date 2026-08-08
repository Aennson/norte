import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_credentials.dart';
import 'package:norte/domain/entities/jira_status_mapping.dart';
import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';

void main() {
  group('JiraCredentials', () {
    const JiraCredentials complete = JiraCredentials(
      siteUrl: 'https://example.atlassian.net',
      email: 'dev@example.com',
      apiToken: 'synthetic-token',
    );

    test('toString never reveals the token (BR-08)', () {
      final String printed = complete.toString();

      expect(printed, isNot(contains('synthetic-token')));
      expect(printed, contains('[REDACTED]'));
      // The identifying half is still there, so a log line stays useful.
      expect(printed, contains('dev@example.com'));
      expect(printed, contains('https://example.atlassian.net'));
    });

    test('interpolation goes through toString, so it is safe too', () {
      expect('$complete', isNot(contains('synthetic-token')));
    });

    test('a blank field makes the set unusable', () {
      expect(complete.isComplete, isTrue);
      expect(complete.copy(siteUrl: '   ').isComplete, isFalse);
      expect(complete.copy(email: '').isComplete, isFalse);
      expect(complete.copy(apiToken: '\n').isComplete, isFalse);
    });

    test('a Data Center set needs no e-mail (DEC-012)', () {
      const JiraCredentials pat = JiraCredentials(
        siteUrl: 'https://jira.example.com',
        email: '',
        apiToken: 'synthetic-pat',
        deployment: JiraDeployment.dataCenter,
      );

      expect(pat.isComplete, isTrue);
      // …and names the site, since a PAT names nobody.
      expect(pat.accountLabel, 'https://jira.example.com');
      expect(complete.accountLabel, 'dev@example.com');
      // A site and a token are still required.
      expect(
        const JiraCredentials(
          siteUrl: 'https://jira.example.com',
          email: '',
          apiToken: '',
          deployment: JiraDeployment.dataCenter,
        ).isComplete,
        isFalse,
      );
    });

    test('each deployment knows its REST version and what it asks for', () {
      expect(JiraDeployment.cloud.restVersion, '3');
      expect(JiraDeployment.dataCenter.restVersion, '2');
      expect(JiraDeployment.cloud.needsEmail, isTrue);
      expect(JiraDeployment.dataCenter.needsEmail, isFalse);
    });

    test('the deployment is part of the identity', () {
      expect(
        complete,
        isNot(complete.copy(deployment: JiraDeployment.dataCenter)),
      );
    });

    test('toString names the deployment but still hides the token', () {
      final String printed = complete
          .copy(deployment: JiraDeployment.dataCenter)
          .toString();

      expect(printed, contains('dataCenter'));
      expect(printed, isNot(contains('synthetic-token')));
    });

    test('equality is by value', () {
      expect(complete, complete.copy());
      expect(complete.hashCode, complete.copy().hashCode);
      expect(complete, isNot(complete.copy(apiToken: 'other')));
      expect(complete, isNot(equals(Object())));
    });
  });

  group('JiraStatusMapping', () {
    test('reads the names of the default Jira workflow', () {
      expect(JiraStatusMapping.toLocal('To Do'), TaskStatus.todo);
      expect(JiraStatusMapping.toLocal('In Progress'), TaskStatus.inProgress);
      expect(JiraStatusMapping.toLocal('Done'), TaskStatus.done);
      expect(JiraStatusMapping.toLocal('Blocked'), TaskStatus.blocked);
    });

    test('is tolerant about case and padding', () {
      expect(JiraStatusMapping.toLocal('  done  '), TaskStatus.done);
      expect(JiraStatusMapping.toLocal('IN PROGRESS'), TaskStatus.inProgress);
    });

    test('accepts the common synonyms of each state', () {
      expect(JiraStatusMapping.toLocal('Backlog'), TaskStatus.todo);
      expect(JiraStatusMapping.toLocal('Open'), TaskStatus.todo);
      expect(JiraStatusMapping.toLocal('In Review'), TaskStatus.inProgress);
      expect(JiraStatusMapping.toLocal('Resolved'), TaskStatus.done);
      expect(JiraStatusMapping.toLocal('Closed'), TaskStatus.done);
      expect(JiraStatusMapping.toLocal('Impediment'), TaskStatus.blocked);
    });

    test('a name it does not know maps to nothing', () {
      expect(JiraStatusMapping.toLocal('Awaiting Legal Review'), isNull);
    });

    test('every local status has a name to push', () {
      for (final TaskStatus status in TaskStatus.values) {
        final String remote = JiraStatusMapping.toRemote(status);
        expect(remote, isNotEmpty);
        // And the round trip lands back where it started.
        expect(JiraStatusMapping.toLocal(remote), status);
      }
    });

    test('divergence is disagreement, and nothing else', () {
      expect(JiraStatusMapping.diverges(TaskStatus.done, 'To Do'), isTrue);
      expect(JiraStatusMapping.diverges(TaskStatus.done, 'Done'), isFalse);
      expect(JiraStatusMapping.diverges(TaskStatus.done, 'Resolved'), isFalse);
      // An unreadable status is not a disagreement — there is nothing to
      // disagree with.
      expect(JiraStatusMapping.diverges(TaskStatus.done, 'Wat'), isFalse);
    });
  });

  group('OutboxOperationState', () {
    test('only completed is settled', () {
      expect(OutboxOperationState.pending.isUnsettled, isTrue);
      expect(OutboxOperationState.failed.isUnsettled, isTrue);
      expect(OutboxOperationState.completed.isUnsettled, isFalse);
    });
  });

  group('the Jira failures', () {
    test('a missing key carries the key', () {
      const JiraIssueNotFoundFailure failure = JiraIssueNotFoundFailure(
        'PROJ-123',
      );

      expect(failure.issueKey, 'PROJ-123');
      expect(failure.message, contains('PROJ-123'));
      expect(failure, isA<Failure>());
    });

    test('NotLinkedFailure has a usable default message', () {
      expect(const NotLinkedFailure().message, isNotEmpty);
    });
  });
}

/// `copyWith` for a plain class, so the tests above read as variations on one
/// credential set rather than five near-identical literals.
extension on JiraCredentials {
  JiraCredentials copy({
    String? siteUrl,
    String? email,
    String? apiToken,
    JiraDeployment? deployment,
  }) => JiraCredentials(
    siteUrl: siteUrl ?? this.siteUrl,
    email: email ?? this.email,
    apiToken: apiToken ?? this.apiToken,
    deployment: deployment ?? this.deployment,
  );
}
