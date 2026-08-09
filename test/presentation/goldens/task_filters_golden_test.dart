import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/list_tasks.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/shared/widgets/empty_state.dart';
import 'package:norte/presentation/tasks/task_providers.dart';
import 'package:norte/presentation/tasks/tasks_screen.dart';
import 'package:norte/presentation/tasks/widgets/task_filter_bar.dart';
import 'package:norte/presentation/tasks/widgets/task_search_field.dart';

import '../../fakes/fakes.dart';
import '../../support/golden_harness.dart';
import '../../support/platform_goldens.dart';
import '../../support/task_fixtures.dart';
import '../../support/test_fonts.dart';

/// S05a-GT-01 — the multi-select filter bar, the search field, and the empty
/// state a search produces (`docs/design-system.md` §4).
///
/// Three things are pinned as pictures because none of them survives a code
/// review reliably:
///
/// * **An active chip is visibly distinct from an inactive one**, and *two* of
///   them can be active at once. A refactor back to single-select would still
///   render a perfectly reasonable bar; only the picture shows that the second
///   chip stayed lit.
/// * **The search field carries its term and its clear button.** A field whose
///   clear button never appeared would look correct in every state a widget
///   test thinks to pump.
/// * **The two empty states read differently.** "No tasks yet" invites a first
///   task; "nothing matches" names the word back. Collapsing them into one
///   sentence is the kind of tidy-looking change this golden refuses.
void main() {
  setUpAll(() async {
    usePlatformGoldens();
    await loadNorteFonts();
  });

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];

  for (final (String name, ThemeData theme) in themes) {
    testWidgets('S05a-GT-01: filter bar with two statuses active ($name)', (
      WidgetTester tester,
    ) async {
      tester.setSurfaceSize(const Size(560, 120));
      await tester.pumpWidget(
        goldenHarness(
          theme: theme,
          child: TaskFilterBar(
            query: const TaskQuery(
              statuses: <TaskStatus>{TaskStatus.todo, TaskStatus.blocked},
            ),
            onStatusToggled: (_) {},
            onAllSelected: () {},
            onSortSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TaskFilterBar),
        matchesGoldenFile('images/task_filter_bar_multi_$name.png'),
      );
    });

    testWidgets('S05a-GT-01: search field with a term ($name)', (
      WidgetTester tester,
    ) async {
      tester.setSurfaceSize(const Size(420, 120));
      await tester.pumpWidget(
        goldenHarness(
          theme: theme,
          child: TaskSearchField(value: 'orçamento', onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TaskSearchField),
        matchesGoldenFile('images/task_search_field_$name.png'),
      );
    });
  }

  /// The two empty states, rendered through the real screen so the wording
  /// comes from where the user would see it.
  Future<void> pumpScreen(
    WidgetTester tester, {
    required ThemeData theme,
    required List<Task> tasks,
    required void Function(TaskQueryNotifier) narrow,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          taskRepositoryProvider.overrideWithValue(FakeTaskRepository(tasks)),
          clockProvider.overrideWithValue(FakeClock.fixed()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: TasksScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    narrow(
      ProviderScope.containerOf(
        tester.element(find.byType(TasksScreen)),
      ).read(taskQueryProvider.notifier),
    );
    await tester.pumpAndSettle();
  }

  for (final (String name, ThemeData theme) in themes) {
    testWidgets('S05a-GT-01: a search that matched nothing ($name)', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        theme: theme,
        tasks: goldenTasks,
        narrow: (TaskQueryNotifier query) => query.search('orçamento'),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      await expectLater(
        find.byType(TasksScreen),
        matchesGoldenFile('images/tasks_screen_search_empty_$name.png'),
      );
    });
  }

  testWidgets('S05a-GT-01: the three empty states say three different '
      'things', (WidgetTester tester) async {
    final List<String> messages = <String>[];

    Future<void> capture(void Function(TaskQueryNotifier) narrow) async {
      await pumpScreen(
        tester,
        theme: NorteTheme.dark,
        tasks: goldenTasks,
        narrow: narrow,
      );
      messages.add(tester.widget<EmptyState>(find.byType(EmptyState)).message);
    }

    // An empty database, a filter that matched nothing, and a search that
    // matched nothing. Same picture, three different fixes — and the wording
    // is the only thing that tells the user which one they are looking at.
    await pumpScreen(
      tester,
      theme: NorteTheme.dark,
      tasks: const <Task>[],
      narrow: (_) {},
    );
    messages.add(tester.widget<EmptyState>(find.byType(EmptyState)).message);
    await capture(
      (TaskQueryNotifier query) => query.search('nothing like this'),
    );
    // Every golden task is todo, inProgress or done, so `blocked` alone
    // matches none of them. The search is cleared first: pumping the same
    // tree again reuses the `ProviderScope`'s container, so the previous
    // term is still set — and a leftover search would make this case
    // indistinguishable from the one above for the wrong reason.
    await capture((TaskQueryNotifier query) {
      query
        ..search('')
        ..toggleStatus(TaskStatus.blocked);
    });

    expect(messages.toSet(), hasLength(3), reason: messages.join(' | '));
  });
}
