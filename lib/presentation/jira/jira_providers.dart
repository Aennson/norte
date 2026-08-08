import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/usecases/add_jira_comment.dart';
import '../../application/usecases/create_jira_issue_from_task.dart';
import '../../application/usecases/link_task_to_jira.dart';
import '../../application/usecases/refresh_jira_status.dart';
import '../../application/usecases/sync_linked_tasks.dart';
import '../../application/usecases/unlink_task.dart';
import '../../application/usecases/update_jira_status.dart';
import '../../domain/entities/jira_credentials.dart';
import '../../domain/entities/outbox_operation.dart';
import '../../domain/ports/jira_credential_store.dart';
import '../../domain/ports/jira_gateway.dart';
import '../../domain/ports/outbox_repository.dart';
import '../tasks/task_providers.dart';

/// Drains the outbox once. Supplied by the composition root, because the
/// dispatcher lives in `infrastructure/` and `presentation/` may not reach
/// there (`docs/project-rules.md` §3).
typedef OutboxDispatch = Future<void> Function();

/// Requeues a failed operation — the manual retry behind the sync indicator.
typedef OutboxRetry = Future<void> Function(String operationId);

/// How often linked, unfinished tasks are refreshed
/// (`docs/architecture.md` §4.3).
const Duration jiraRefreshInterval = Duration(minutes: 15);

/// The ports the composition root supplies. Each throws until overridden, so
/// a missing wire fails loudly at startup instead of silently doing nothing.
final Provider<JiraGateway> jiraGatewayProvider = Provider<JiraGateway>(
  (Ref ref) => throw UnimplementedError(
    'jiraGatewayProvider must be overridden in the composition root',
  ),
);

final Provider<OutboxRepository> outboxRepositoryProvider =
    Provider<OutboxRepository>(
      (Ref ref) => throw UnimplementedError(
        'outboxRepositoryProvider must be overridden in the composition root',
      ),
    );

final Provider<JiraCredentialStore> jiraCredentialStoreProvider =
    Provider<JiraCredentialStore>(
      (Ref ref) => throw UnimplementedError(
        'jiraCredentialStoreProvider must be overridden in the composition '
        'root',
      ),
    );

final Provider<OutboxDispatch> outboxDispatchProvider = Provider<OutboxDispatch>(
  (Ref ref) => throw UnimplementedError(
    'outboxDispatchProvider must be overridden in the composition root',
  ),
);

final Provider<OutboxRetry> outboxRetryProvider = Provider<OutboxRetry>(
  (Ref ref) => throw UnimplementedError(
    'outboxRetryProvider must be overridden in the composition root',
  ),
);

/// The six Jira use cases, assembled from the ports above.
final Provider<LinkTaskToJira> linkTaskToJiraProvider =
    Provider<LinkTaskToJira>(
      (Ref ref) => LinkTaskToJira(
        repository: ref.watch(taskRepositoryProvider),
        gateway: ref.watch(jiraGatewayProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<UnlinkTask> unlinkTaskProvider = Provider<UnlinkTask>(
  (Ref ref) => UnlinkTask(
    repository: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final Provider<UpdateJiraStatus> updateJiraStatusProvider =
    Provider<UpdateJiraStatus>(
      (Ref ref) => UpdateJiraStatus(
        outbox: ref.watch(outboxRepositoryProvider),
        clock: ref.watch(clockProvider),
        idGenerator: ref.watch(idGeneratorProvider),
      ),
    );

final Provider<AddJiraComment> addJiraCommentProvider =
    Provider<AddJiraComment>(
      (Ref ref) => AddJiraComment(
        outbox: ref.watch(outboxRepositoryProvider),
        clock: ref.watch(clockProvider),
        idGenerator: ref.watch(idGeneratorProvider),
      ),
    );

final Provider<CreateJiraIssueFromTask> createJiraIssueFromTaskProvider =
    Provider<CreateJiraIssueFromTask>(
      (Ref ref) => CreateJiraIssueFromTask(
        outbox: ref.watch(outboxRepositoryProvider),
        clock: ref.watch(clockProvider),
        idGenerator: ref.watch(idGeneratorProvider),
      ),
    );

final Provider<RefreshJiraStatus> refreshJiraStatusProvider =
    Provider<RefreshJiraStatus>(
      (Ref ref) => RefreshJiraStatus(
        repository: ref.watch(taskRepositoryProvider),
        gateway: ref.watch(jiraGatewayProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<SyncLinkedTasks> syncLinkedTasksProvider =
    Provider<SyncLinkedTasks>(
      (Ref ref) => SyncLinkedTasks(
        repository: ref.watch(taskRepositoryProvider),
        refresh: ref.watch(refreshJiraStatusProvider),
      ),
    );

/// Operations still owing the user an outcome, straight from Drift's `watch` —
/// what the "pending sync" and "sync failed" indicators are drawn from. The UI
/// never polls the queue.
final StreamProvider<List<OutboxOperation>> unsettledOperationsProvider =
    StreamProvider<List<OutboxOperation>>(
      (Ref ref) => ref.watch(outboxRepositoryProvider).watchUnsettled(),
    );

/// The stored Jira credentials, or `null` when the user has not configured a
/// site. Read through a provider so the settings screen and the "is Jira
/// available?" checks share one answer.
final FutureProvider<JiraCredentials?> jiraCredentialsProvider =
    FutureProvider<JiraCredentials?>(
      (Ref ref) => ref.watch(jiraCredentialStoreProvider).read(),
    );

/// `true` when Jira actions should be offered at all.
final Provider<bool> jiraConfiguredProvider = Provider<bool>(
  (Ref ref) =>
      ref.watch(jiraCredentialsProvider).valueOrNull?.isComplete ?? false,
);

/// Drives the two periodic jobs: draining the outbox and refreshing linked
/// tasks.
///
/// On desktop this timer *is* the background sync
/// (`docs/architecture.md` §12 — "isolate + timer, app open"). On mobile the
/// same work is additionally registered with `workmanager` by the composition
/// root, so it keeps happening while the app is not in the foreground.
///
/// The first pass runs immediately: a user who has just opened the app after
/// a flight should not wait fifteen minutes for their queued transitions to
/// leave.
class JiraSyncController {
  JiraSyncController(this._ref);

  final Ref _ref;
  Timer? _timer;

  /// Starts the periodic pass. Calling it twice does not start two timers.
  void start() {
    if (_timer != null) return;
    unawaited(runOnce());
    _timer = Timer.periodic(jiraRefreshInterval, (_) => unawaited(runOnce()));
  }

  /// Stops the periodic pass.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// One pass: send what is queued, then read back what changed.
  ///
  /// Dispatch comes first so that a status the user just pushed is already on
  /// the site when the refresh reads it — otherwise the refresh would report
  /// the user's own pending change as a divergence.
  Future<void> runOnce() async {
    await _ref.read(outboxDispatchProvider)();
    await _ref.read(syncLinkedTasksProvider)();
  }
}

final Provider<JiraSyncController> jiraSyncControllerProvider =
    Provider<JiraSyncController>((Ref ref) {
      final JiraSyncController controller = JiraSyncController(ref);
      ref.onDispose(controller.stop);
      return controller;
    });
