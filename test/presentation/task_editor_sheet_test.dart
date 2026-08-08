import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/tasks/widgets/task_editor_sheet.dart';

import '../support/task_fixtures.dart';

/// S01-GT-01 — the create/edit form behind the tasks screen.
void main() {
  /// Captures whatever the sheet returns when it closes.
  late TaskDraft? result;
  late bool closed;

  Future<void> openEditor(WidgetTester tester, {Task? initial}) async {
    result = null;
    closed = false;

    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: NorteTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await TaskEditorSheet.show(
                    context,
                    initial: initial,
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, Key key, String text) async {
    await tester.enterText(
      find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
      text,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('S01-GT-01: creating opens an empty form and returns a draft', (
    WidgetTester tester,
  ) async {
    await openEditor(tester);

    expect(find.text('New task'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('No due date'), findsOneWidget);

    await type(tester, const Key('task-title-field'), 'Buy coffee');
    await type(tester, const Key('task-description-field'), 'the good one');
    await type(tester, const Key('task-tags-field'), 'errands, , home');
    await tester.tap(find.text('URGENT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BLOCKED'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-submit-button')));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result!.title, 'Buy coffee');
    expect(result!.description, 'the good one');
    expect(result!.priority, Priority.urgent);
    expect(result!.status, TaskStatus.blocked);
    expect(result!.tags, <String>[
      'errands',
      'home',
    ], reason: 'blank entries between commas are dropped');
    expect(result!.dueDate, isNull);
  });

  testWidgets('S01-GT-01: editing pre-fills the form from the task', (
    WidgetTester tester,
  ) async {
    await openEditor(tester, initial: goldenTasks.first);

    expect(find.text('Edit task'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Review the connector PR'), findsOneWidget);
    expect(find.text('api, urgent'), findsOneWidget);

    // Unchanged fields come back exactly as they went in.
    await tester.tap(find.byKey(const Key('task-submit-button')));
    await tester.pumpAndSettle();

    expect(result!.title, 'Review the connector PR');
    expect(result!.status, TaskStatus.inProgress);
    expect(result!.priority, Priority.urgent);
    expect(result!.tags, <String>['api', 'urgent']);
    expect(result!.dueDate, goldenTasks.first.dueDate);
  });

  testWidgets(
    'S01-GT-01: a blank title keeps the sheet open and explains why',
    (WidgetTester tester) async {
      await openEditor(tester);

      await type(tester, const Key('task-title-field'), '   ');
      await tester.tap(find.byKey(const Key('task-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('A title is required.'), findsOneWidget);
      expect(
        closed,
        isFalse,
        reason: 'the sheet does not close on a rejection',
      );
      expect(find.byType(TaskEditorSheet), findsOneWidget);
    },
  );

  testWidgets('S01-GT-01: cancelling returns nothing', (
    WidgetTester tester,
  ) async {
    await openEditor(tester);

    await type(tester, const Key('task-title-field'), 'Discard me');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('S01-GT-01: the due date can be picked and cleared', (
    WidgetTester tester,
  ) async {
    await openEditor(tester, initial: goldenTasks.first);

    // The task starts dated, so the clear action is available.
    expect(find.byTooltip('Clear'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('No due date'), findsOneWidget);
    expect(find.byTooltip('Clear'), findsNothing);

    await tester.tap(find.byKey(const Key('task-submit-button')));
    await tester.pumpAndSettle();

    expect(result!.dueDate, isNull);
  });
}
