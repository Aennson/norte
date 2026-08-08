import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'domain/ports/clock.dart';
import 'infrastructure/jira/jira_rest_adapter.dart';
import 'infrastructure/jira/outbox_dispatcher.dart';
import 'infrastructure/jira/secure_jira_credential_store.dart';
import 'infrastructure/persistence/drift_outbox_repository.dart';
import 'infrastructure/persistence/drift_task_repository.dart';
import 'infrastructure/persistence/norte_database.dart';
import 'infrastructure/persistence/norte_database_factory.dart';
import 'jira_background_sync.dart';
import 'presentation/app/norte_app.dart';
import 'presentation/jira/jira_providers.dart';
import 'presentation/tasks/task_providers.dart';

/// Composition root.
///
/// The only place allowed to wire `infrastructure/` adapters into the
/// providers the rest of the app consumes (`docs/project-rules.md` §3) — which
/// is why `presentation/` can declare `taskRepositoryProvider` and
/// `jiraGatewayProvider` without ever importing Drift or dio.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NorteDatabase database = await openNorteDatabase();
  final DriftTaskRepository tasks = DriftTaskRepository(database);
  final DriftOutboxRepository outbox = DriftOutboxRepository(database);
  final SecureJiraCredentialStore credentials = SecureJiraCredentialStore(
    const FlutterSecureStorage(),
  );
  final JiraRestAdapter jira = JiraRestAdapter(
    dio: Dio(),
    credentialStore: credentials,
    // Diagnostics for the Jira connection, which is the one part of the app
    // that depends on a site nobody here controls. Safe by construction:
    // bodies are never written and every line is swept for credentials
    // (BR-08, `RedactingLogInterceptor`). Run the app from a terminal to
    // read it.
    log: (String line) => debugPrint('[jira] $line'),
  );
  final OutboxDispatcher dispatcher = OutboxDispatcher(
    outbox: outbox,
    gateway: jira,
    tasks: tasks,
    clock: const SystemClock(),
  );

  // Mobile keeps syncing while the app is closed; desktop relies on the
  // in-app timer started below (`docs/architecture.md` §12).
  await registerJiraBackgroundSync();

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      taskRepositoryProvider.overrideWithValue(tasks),
      outboxRepositoryProvider.overrideWithValue(outbox),
      jiraGatewayProvider.overrideWithValue(jira),
      jiraCredentialStoreProvider.overrideWithValue(credentials),
      outboxDispatchProvider.overrideWithValue(dispatcher.dispatch),
      outboxRetryProvider.overrideWithValue(dispatcher.retry),
    ],
  );
  container.read(jiraSyncControllerProvider).start();

  runApp(
    UncontrolledProviderScope(container: container, child: const NorteApp()),
  );
}
