import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'infrastructure/persistence/drift_task_repository.dart';
import 'infrastructure/persistence/norte_database.dart';
import 'infrastructure/persistence/norte_database_factory.dart';
import 'presentation/app/norte_app.dart';
import 'presentation/tasks/task_providers.dart';

/// Composition root.
///
/// The only place allowed to wire `infrastructure/` adapters into the
/// providers the rest of the app consumes (`docs/project-rules.md` §3) — which
/// is why `presentation/` can declare `taskRepositoryProvider` without ever
/// importing Drift.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NorteDatabase database = await openNorteDatabase();

  runApp(
    ProviderScope(
      overrides: <Override>[
        taskRepositoryProvider.overrideWithValue(DriftTaskRepository(database)),
      ],
      child: const NorteApp(),
    ),
  );
}
