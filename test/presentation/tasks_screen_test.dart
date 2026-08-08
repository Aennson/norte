import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/shared/widgets/empty_state.dart';
import 'package:norte/presentation/tasks/task_providers.dart';
import 'package:norte/presentation/tasks/tasks_screen.dart';
import 'package:norte/presentation/tasks/widgets/delete_task_dialog.dart';

import '../fakes/fakes.dart';
import '../support/task_fixtures.dart';

/// Widget-level cover for the parts of the tasks screen the goldens can only
/// photograph: the filter chips and the delete confirmation.
void main() {
  Future<void> pump(WidgetTester tester, FakeTaskRepository repository) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          taskRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(FakeClock.fixed()),
          idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: NorteTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: TasksScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('S01-GT-01: the status filter narrows the list', (
    WidgetTester tester,
  ) async {
    await pump(tester, FakeTaskRepository(goldenTasks));

    expect(find.text('Review the connector PR'), findsOneWidget);
    expect(find.text('Buy coffee'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-done')));
    await tester.pumpAndSettle();

    expect(find.text('Buy coffee'), findsOneWidget);
    expect(find.text('Review the connector PR'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('Review the connector PR'), findsOneWidget);
  });

  testWidgets(
    'S01-GT-01: a filter matching nothing shows its own empty state',
    (WidgetTester tester) async {
      await pump(tester, FakeTaskRepository(goldenTasks));

      await tester.tap(find.byKey(const Key('filter-blocked')));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No task matches this filter.'), findsOneWidget);
      expect(
        find.text('No tasks yet.'),
        findsNothing,
        reason: 'an empty database and an empty filter read differently',
      );
    },
  );

  testWidgets('S01-GT-01: completing a task from the card writes it back', (
    WidgetTester tester,
  ) async {
    final FakeTaskRepository repository = FakeTaskRepository(goldenTasks);
    await pump(tester, repository);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('task-card-task-plain')),
        matching: find.byTooltip('Mark as done'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.savedIds, <String>['task-plain']);
    expect((await repository.findById('task-plain'))!.status, TaskStatus.done);
  });

  testWidgets('S01-E2E-02: cancelling the delete dialog keeps the task', (
    WidgetTester tester,
  ) async {
    final FakeTaskRepository repository = FakeTaskRepository(goldenTasks);
    await pump(tester, repository);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('task-card-task-done')),
        matching: find.byTooltip('Delete'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DeleteTaskDialog), findsOneWidget);
    expect(find.textContaining('Buy coffee'), findsWidgets);

    await tester.tap(find.byKey(const Key('delete-cancel-button')));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, isEmpty);
    expect(find.text('Buy coffee'), findsOneWidget);
  });

  testWidgets('S01-E2E-01: confirming the delete dialog removes the task', (
    WidgetTester tester,
  ) async {
    final FakeTaskRepository repository = FakeTaskRepository(goldenTasks);
    await pump(tester, repository);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('task-card-task-done')),
        matching: find.byTooltip('Delete'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-confirm-button')));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, <String>['task-done']);
    expect(find.text('Buy coffee'), findsNothing);
  });
}
