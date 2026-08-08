import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/ports/task_repository.dart';
import 'package:norte/infrastructure/persistence/drift_task_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';
import 'package:norte/presentation/app/norte_app.dart';
import 'package:norte/presentation/shared/widgets/empty_state.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

/// S01-E2E-01 / S01-E2E-02 — the task CRUD driven entirely through the UI,
/// against a real (in-memory) Drift database.
///
/// The app boots from the real composition root: `ProviderScope` + `NorteApp`,
/// with only the database swapped for an in-memory one
/// (`docs/testing-strategy.md` §4.2). Every assert checks both the
/// user-observable effect and the row actually stored (§4.4).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late NorteDatabase database;
  late TaskRepository repository;

  setUp(() {
    database = openInMemoryNorteDatabase();
    repository = DriftTaskRepository(database);
  });

  tearDown(() => database.close());

  /// Boots the app on a desktop-sized viewport, where the task list and the
  /// editor are both fully visible without scrolling.
  Future<void> bootApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = <Locale>[const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          taskRepositoryProvider.overrideWithValue(repository),
        ],
        child: const NorteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Types [text] into the field carrying [key], replacing what is there.
  Future<void> enterText(WidgetTester tester, Key key, String text) async {
    await tester.enterText(
      find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
      text,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('S01-E2E-01: create, edit, complete and delete a task', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);

    // The app starts on Tasks with an empty database.
    expect(find.byType(EmptyState), findsOneWidget);
    expect(await repository.listAll(), isEmpty);

    // --- create -------------------------------------------------------
    await tester.tap(find.byKey(const Key('new-task-button')));
    await tester.pumpAndSettle();

    await enterText(tester, const Key('task-title-field'), 'Buy coffee');
    // Priority chips render the localized label in upper case.
    await tester.tap(find.text('HIGH'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Buy coffee'), findsOneWidget, reason: 'shown at once');
    expect(find.byType(EmptyState), findsNothing);

    List<Task> stored = await repository.listAll();
    expect(stored, hasLength(1), reason: 'the task reached the database');
    expect(stored.single.title, 'Buy coffee');
    expect(stored.single.priority, Priority.high);
    expect(stored.single.status, TaskStatus.todo);
    expect(stored.single.jiraLink, isNull, reason: 'BR-01 — no Jira involved');
    final String id = stored.single.id;

    // --- edit ---------------------------------------------------------
    await tester.tap(find.text('Buy coffee'));
    await tester.pumpAndSettle();
    await enterText(
      tester,
      const Key('task-title-field'),
      'Buy specialty coffee',
    );
    await tester.tap(find.byKey(const Key('task-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Buy specialty coffee'), findsOneWidget);
    expect(find.text('Buy coffee'), findsNothing);

    stored = await repository.listAll();
    expect(stored.single.title, 'Buy specialty coffee');
    expect(stored.single.id, id, reason: 'editing keeps the identity');
    expect(
      stored.single.createdAt.isAtSameMomentAs(stored.single.updatedAt),
      isFalse,
      reason: 'the edit refreshed updatedAt but not createdAt',
    );

    // --- complete -----------------------------------------------------
    await tester.tap(find.byTooltip('Mark as done'));
    await tester.pumpAndSettle();

    stored = await repository.listAll();
    expect(stored.single.status, TaskStatus.done);
    expect(find.byTooltip('Reopen task'), findsOneWidget);

    // --- delete -------------------------------------------------------
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-confirm-button')));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Buy specialty coffee'), findsNothing);
    expect(await repository.listAll(), isEmpty, reason: 'the row is gone');
  });

  testWidgets('S01-E2E-02: cancelling the delete keeps the task everywhere', (
    WidgetTester tester,
  ) async {
    // The scenario creates its own state (docs/testing-strategy.md §4.3).
    await repository.save(
      Task(
        id: 'keep-me',
        title: 'Review PR',
        createdAt: DateTime.utc(2026, 1, 1, 9),
        updatedAt: DateTime.utc(2026, 1, 1, 9),
      ),
    );

    await bootApp(tester);
    expect(find.text('Review PR'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete task?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-cancel-button')));
    await tester.pumpAndSettle();

    expect(find.text('Review PR'), findsOneWidget, reason: 'still on screen');
    expect(find.byType(EmptyState), findsNothing);

    final List<Task> stored = await repository.listAll();
    expect(stored, hasLength(1), reason: 'and still in the database');
    expect(stored.single.id, 'keep-me');
  });

  testWidgets('S01-E2E-01: a blank title is refused by the editor', (
    WidgetTester tester,
  ) async {
    await bootApp(tester);

    await tester.tap(find.byKey(const Key('new-task-button')));
    await tester.pumpAndSettle();
    await enterText(tester, const Key('task-title-field'), '   ');
    await tester.tap(find.byKey(const Key('task-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('A title is required.'), findsOneWidget);
    expect(await repository.listAll(), isEmpty);
  });
}
