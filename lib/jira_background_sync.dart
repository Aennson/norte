/// Background Jira sync on mobile.
///
/// Part of the composition root, and deliberately so: it is the one place
/// besides `main.dart` that is allowed to see every layer at once
/// (`docs/project-rules.md` §3, `tool/check_imports.dart`). Everything here is
/// wiring — the behaviour it wires up lives in the layers below.
///
/// **Why this file exists at all.** `workmanager` wakes the app in a *fresh
/// isolate*: no `ProviderScope`, no open database, nothing the running app
/// built. The graph therefore has to be assembled from scratch on each wake,
/// which is what [runJiraBackgroundSync] does.
///
/// On Windows there is no workmanager and no second isolate to wake — the
/// desktop story is the timer in `JiraSyncController`, which the app starts
/// when it launches (`docs/architecture.md` §12).
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import 'application/usecases/refresh_jira_status.dart';
import 'application/usecases/sync_linked_tasks.dart';
import 'domain/ports/clock.dart';
import 'infrastructure/jira/jira_rest_adapter.dart';
import 'infrastructure/jira/outbox_dispatcher.dart';
import 'infrastructure/jira/secure_jira_credential_store.dart';
import 'infrastructure/persistence/drift_outbox_repository.dart';
import 'infrastructure/persistence/drift_task_repository.dart';
import 'infrastructure/persistence/norte_database.dart';
import 'infrastructure/persistence/norte_database_factory.dart';
import 'presentation/jira/jira_providers.dart';

/// Unique name workmanager files the periodic job under.
const String jiraSyncTaskName = 'norte.jira.sync';

/// `true` on the platforms where `workmanager` exists.
bool get supportsWorkmanagerSync => Platform.isAndroid || Platform.isIOS;

/// Registers the 15-minute periodic sync on mobile; a no-op elsewhere.
///
/// Fifteen minutes is both what `docs/architecture.md` §4.3 specifies and the
/// shortest period Android's `WorkManager` honours, so asking for less would
/// silently get this anyway.
Future<void> registerJiraBackgroundSync() async {
  if (!supportsWorkmanagerSync) return;
  await Workmanager().initialize(jiraBackgroundSyncDispatcher);
  await Workmanager().registerPeriodicTask(
    jiraSyncTaskName,
    jiraSyncTaskName,
    frequency: jiraRefreshInterval,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

/// Entry point the platform calls on a wake-up.
@pragma('vm:entry-point')
void jiraBackgroundSyncDispatcher() {
  Workmanager().executeTask((String task, Map<String, Object?>? _) async {
    if (task != jiraSyncTaskName) return true;
    await runJiraBackgroundSync();
    return true;
  });
}

/// One background pass: drain the outbox, then refresh linked tasks.
///
/// Returns `false` when Jira is not configured or the pass could not run, so
/// the platform is told the wake-up achieved nothing rather than being led to
/// believe otherwise.
///
/// **BR-02 holds here too.** A pass that finds a divergence updates the
/// display cache and stops. It does not resolve, and it does not notify —
/// the user meets the divergence on the task, where the banner can offer them
/// a choice.
Future<bool> runJiraBackgroundSync({NorteDatabase? database}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final NorteDatabase db = database ?? await openNorteDatabase();
  try {
    final SecureJiraCredentialStore credentials = SecureJiraCredentialStore(
      const FlutterSecureStorage(),
    );
    if (await credentials.read() == null) return false;

    const Clock clock = SystemClock();
    final DriftTaskRepository tasks = DriftTaskRepository(db);
    final JiraRestAdapter gateway = JiraRestAdapter(
      dio: Dio(),
      credentialStore: credentials,
    );

    await OutboxDispatcher(
      outbox: DriftOutboxRepository(db),
      gateway: gateway,
      tasks: tasks,
      clock: clock,
    ).dispatch();

    await SyncLinkedTasks(
      repository: tasks,
      refresh: RefreshJiraStatus(
        repository: tasks,
        gateway: gateway,
        clock: clock,
      ),
    )();
    return true;
  } finally {
    if (database == null) await db.close();
  }
}
