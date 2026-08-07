import 'dart:convert';
import 'dart:io';

import 'package:norte/domain/failures/failure.dart';

import 'ports/provisional_ports.dart';

/// A write the gateway accepted.
class JiraWrite {
  const JiraWrite({
    required this.kind,
    required this.issueKey,
    required this.value,
    required this.operationId,
  });

  /// `transition` or `comment`.
  final String kind;
  final String issueKey;

  /// The target status or the comment body.
  final String value;

  /// Idempotency key (BR-05).
  final String operationId;

  @override
  String toString() => '$kind($issueKey, $value, $operationId)';
}

/// In-memory Jira with the state a real server would keep
/// (`docs/testing-strategy.md` §3).
///
/// Deterministic: no network, no clock, no randomness. Simulates the failures
/// the adapter must survive — 401, 404, 429 and a dropped connection.
class FakeJiraGateway implements JiraGateway {
  FakeJiraGateway({Map<String, JiraIssueSnapshot>? issues})
    : issues = issues ?? <String, JiraIssueSnapshot>{};

  /// Loads the preloaded issues from `test/fixtures/jira_issues.json`.
  factory FakeJiraGateway.fromFixture([
    String path = 'test/fixtures/jira_issues.json',
  ]) {
    final Object? decoded = jsonDecode(File(path).readAsStringSync());
    final List<Object?> rows =
        (decoded! as Map<String, Object?>)['issues']! as List<Object?>;
    final Map<String, JiraIssueSnapshot> issues = <String, JiraIssueSnapshot>{};
    for (final Object? row in rows) {
      final Map<String, Object?> issue = row! as Map<String, Object?>;
      final String key = issue['issueKey']! as String;
      issues[key] = JiraIssueSnapshot(
        issueKey: key,
        siteUrl: issue['siteUrl']! as String,
        status: issue['status']! as String,
      );
    }
    return FakeJiraGateway(issues: issues);
  }

  /// Server-side issue state, keyed by issue key.
  final Map<String, JiraIssueSnapshot> issues;

  /// Every accepted write, in order.
  final List<JiraWrite> writes = <JiraWrite>[];

  /// Operation ids already applied — a replay is ignored, never duplicated.
  final Set<String> appliedOperationIds = <String>{};

  /// Reads performed, in order.
  final List<String> reads = <String>[];

  /// When set, every call throws it. Use [AuthFailure] for 401,
  /// [RateLimitFailure] for 429 and [NetworkFailure] for a dropped connection.
  Failure? failWith;

  @override
  Future<JiraIssueSnapshot> fetchIssue(String issueKey) async {
    reads.add(issueKey);
    _guard();
    final JiraIssueSnapshot? issue = issues[issueKey];
    if (issue == null) throw NotFoundFailure('issue $issueKey does not exist');
    return issue;
  }

  @override
  Future<void> transition({
    required String issueKey,
    required String status,
    required String operationId,
  }) async {
    _guard();
    final JiraIssueSnapshot? issue = issues[issueKey];
    if (issue == null) throw NotFoundFailure('issue $issueKey does not exist');
    if (!appliedOperationIds.add(operationId)) return; // BR-05 — idempotent.
    issues[issueKey] = JiraIssueSnapshot(
      issueKey: issue.issueKey,
      siteUrl: issue.siteUrl,
      status: status,
    );
    writes.add(
      JiraWrite(
        kind: 'transition',
        issueKey: issueKey,
        value: status,
        operationId: operationId,
      ),
    );
  }

  @override
  Future<void> addComment({
    required String issueKey,
    required String body,
    required String operationId,
  }) async {
    _guard();
    if (!issues.containsKey(issueKey)) {
      throw NotFoundFailure('issue $issueKey does not exist');
    }
    if (!appliedOperationIds.add(operationId)) return; // BR-05 — idempotent.
    writes.add(
      JiraWrite(
        kind: 'comment',
        issueKey: issueKey,
        value: body,
        operationId: operationId,
      ),
    );
  }

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }

  /// Writes recorded for [issueKey].
  List<JiraWrite> writesFor(String issueKey) =>
      writes.where((JiraWrite write) => write.issueKey == issueKey).toList();

  /// Forgets every recorded interaction, keeping the loaded issues.
  void reset() {
    writes.clear();
    reads.clear();
    appliedOperationIds.clear();
    failWith = null;
  }
}
