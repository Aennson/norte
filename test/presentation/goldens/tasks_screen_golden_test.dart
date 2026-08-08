import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/shared/widgets/empty_state.dart';
import 'package:norte/presentation/shared/widgets/error_state.dart';
import 'package:norte/presentation/shared/widgets/loading_skeleton.dart';
import 'package:norte/presentation/shared/widgets/norte_card.dart';
import 'package:norte/presentation/shared/widgets/status_badge.dart';
import 'package:norte/presentation/tasks/task_providers.dart';
import 'package:norte/presentation/tasks/tasks_screen.dart';

import '../../fakes/fakes.dart';
import '../../support/platform_goldens.dart';
import '../../support/task_fixtures.dart';
import '../../support/test_fonts.dart';

/// S01-GT-01 — the tasks screen in the four mandatory states
/// (`docs/design-system.md` §6), dark and light, mobile and desktop.
void main() {
  setUpAll(() async {
    usePlatformGoldens();
    await loadNorteFonts();
  });

  const Size mobile = Size(390, 844);
  const Size desktop = Size(1280, 800);

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];
  final List<(String, Size)> viewports = <(String, Size)>[
    ('mobile', mobile),
    ('desktop', desktop),
  ];

  /// Renders the real [TasksScreen] with the repository replaced by a fake in
  /// the state under test — the same override point the composition root uses.
  Future<void> pump(
    WidgetTester tester, {
    required ThemeData theme,
    required Size size,
    required FakeTaskRepository repository,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          taskRepositoryProvider.overrideWithValue(repository),
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // The loading state never settles on its own — it waits for data.
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  for (final (String themeName, ThemeData theme) in themes) {
    for (final (String sizeName, Size size) in viewports) {
      final String suffix = '${sizeName}_$themeName';

      testWidgets('S01-GT-01: tasks screen — content ($suffix)', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeTaskRepository(goldenTasks),
        );

        expect(find.byType(NorteCard), findsNWidgets(goldenTasks.length));
        expect(find.byType(StatusBadge), findsNWidgets(goldenTasks.length));
        await expectLater(
          find.byType(TasksScreen),
          matchesGoldenFile('images/tasks_screen_content_$suffix.png'),
        );
      });

      testWidgets('S01-GT-01: tasks screen — empty ($suffix)', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeTaskRepository(const <Task>[]),
        );

        expect(find.byType(EmptyState), findsOneWidget);
        await expectLater(
          find.byType(TasksScreen),
          matchesGoldenFile('images/tasks_screen_empty_$suffix.png'),
        );
      });

      testWidgets('S01-GT-01: tasks screen — error ($suffix)', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeTaskRepository.failing(),
        );

        expect(find.byType(ErrorState), findsOneWidget);
        await expectLater(
          find.byType(TasksScreen),
          matchesGoldenFile('images/tasks_screen_error_$suffix.png'),
        );
      });

      testWidgets('S01-GT-01: tasks screen — loading ($suffix)', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          theme: theme,
          size: size,
          repository: FakeTaskRepository.pending(),
          settle: false,
        );

        expect(find.byType(LoadingSkeletonList), findsOneWidget);
        await expectLater(
          find.byType(TasksScreen),
          matchesGoldenFile('images/tasks_screen_loading_$suffix.png'),
        );
      });
    }
  }

  testWidgets('S01-GT-01: a card carries a Jira link without depending on it', (
    WidgetTester tester,
  ) async {
    // BR-01 — the same card renders a linked and an unlinked task.
    expect(
      goldenTasks.any((Task task) => task.jiraLink != null),
      isTrue,
      reason: 'the content golden must cover a linked task',
    );
    expect(
      goldenTasks.any((Task task) => task.jiraLink == null),
      isTrue,
      reason: 'and an unlinked one',
    );
    expect(
      goldenTasks.firstWhere((Task task) => task.jiraLink != null).jiraLink,
      isA<JiraLink>(),
    );
  });
}
