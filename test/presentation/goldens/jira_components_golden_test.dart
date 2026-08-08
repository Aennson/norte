import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/jira/widgets/divergence_banner.dart';
import 'package:norte/presentation/jira/widgets/jira_chip.dart';
import 'package:norte/presentation/shared/theme/norte_colors.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/tasks/widgets/task_card.dart';

import '../../support/golden_harness.dart';
import '../../support/platform_goldens.dart';
import '../../support/test_fonts.dart';

/// S02-GT-01 — the Jira components of `docs/design-system.md` §4.
///
/// Two things are being pinned here. The obvious one is appearance: the chip
/// in `accentSubtle`/`accent` mono, the banner in the `warning` treatment with
/// its two decision buttons. The less obvious one is BR-02 — a linked card
/// that disagrees with Jira must *look* like a question, and the golden is
/// what stops that quietly turning into a card that resolves itself.
void main() {
  setUpAll(() async {
    usePlatformGoldens();
    await loadNorteFonts();
  });

  final DateTime t0 = DateTime.utc(2026, 1, 1, 9);

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];

  /// A linked task whose local status matches the cached Jira one.
  Task agreeing() => Task(
    id: 'task-linked',
    title: 'Review the connector PR',
    status: TaskStatus.inProgress,
    priority: Priority.urgent,
    dueDate: DateTime.utc(2026, 1, 5, 18),
    tags: const <String>['api'],
    createdAt: t0,
    updatedAt: t0,
    jiraLink: JiraLink(
      issueKey: 'PROJ-123',
      siteUrl: 'https://example.atlassian.net',
      lastKnownStatus: 'In Progress',
      lastSyncedAt: t0,
    ),
  );

  /// The same task, finished here while Jira still has it open.
  Task diverging() => agreeing().copyWith(
    status: TaskStatus.done,
    jiraLink: agreeing().jiraLink!.copyWith(lastKnownStatus: 'To Do'),
  );

  Future<void> pump(
    WidgetTester tester,
    ThemeData theme,
    Widget child, {
    Size size = const Size(420, 240),
  }) async {
    tester.setSurfaceSize(size);
    await tester.pumpWidget(goldenHarness(theme: theme, child: child));
    await tester.pumpAndSettle();
  }

  for (final (String name, ThemeData theme) in themes) {
    testWidgets('S02-GT-01: JiraChip ($name)', (WidgetTester tester) async {
      await pump(
        tester,
        theme,
        JiraChip(link: agreeing().jiraLink!, onTap: () {}),
        size: const Size(220, 120),
      );

      await expectLater(
        find.byType(JiraChip),
        matchesGoldenFile('images/jira_chip_$name.png'),
      );
    });

    testWidgets('S02-GT-01: DivergenceBanner ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return DivergenceBanner(
              issueKey: 'PROJ-123',
              localStatus: l10n.statusDone,
              remoteStatus: 'To Do',
              onKeepLocal: () {},
              onAdoptRemote: () {},
            );
          },
        ),
        size: const Size(460, 260),
      );

      await expectLater(
        find.byType(DivergenceBanner),
        matchesGoldenFile('images/jira_divergence_banner_$name.png'),
      );
    });

    testWidgets('S02-GT-01: linked task card, no divergence ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        TaskCard(
          task: agreeing(),
          onTap: () {},
          onToggleDone: () {},
          onDelete: () {},
          onJiraMenu: () {},
          onKeepLocal: () {},
          onAdoptRemote: () {},
        ),
        size: const Size(520, 220),
      );

      await expectLater(
        find.byType(TaskCard),
        matchesGoldenFile('images/jira_task_card_linked_$name.png'),
      );
    });

    testWidgets('S02-GT-01: linked task card, diverging ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        TaskCard(
          task: diverging(),
          onTap: () {},
          onToggleDone: () {},
          onDelete: () {},
          onJiraMenu: () {},
          onKeepLocal: () {},
          onAdoptRemote: () {},
        ),
        size: const Size(520, 400),
      );

      await expectLater(
        find.byType(TaskCard),
        matchesGoldenFile('images/jira_task_card_diverging_$name.png'),
      );
    });
  }

  testWidgets('S02-GT-01: the banner offers exactly two decisions', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      NorteTheme.dark,
      TaskCard(
        task: diverging(),
        onTap: () {},
        onToggleDone: () {},
        onDelete: () {},
        onJiraMenu: () {},
        onKeepLocal: () {},
        onAdoptRemote: () {},
      ),
      size: const Size(520, 400),
    );

    final BuildContext context = tester.element(find.byType(TaskCard));
    final AppLocalizations l10n = AppLocalizations.of(context);

    expect(find.byType(DivergenceBanner), findsOneWidget);
    expect(find.text(l10n.jiraDivergenceKeepLocal), findsOneWidget);
    expect(find.text(l10n.jiraDivergenceAdoptRemote), findsOneWidget);
    // Both statuses are named, so the user can see what they are choosing
    // between rather than being asked to trust a label.
    expect(find.textContaining('To Do'), findsOneWidget);
  });

  testWidgets('S02-GT-01: the banner uses the warning colour', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      NorteTheme.dark,
      Builder(
        builder: (BuildContext context) => DivergenceBanner(
          issueKey: 'PROJ-123',
          localStatus: AppLocalizations.of(context).statusDone,
          remoteStatus: 'To Do',
          onKeepLocal: () {},
          onAdoptRemote: () {},
        ),
      ),
      size: const Size(460, 260),
    );

    final DecoratedBox box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(DivergenceBanner),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final BoxDecoration decoration = box.decoration as BoxDecoration;
    final Color warning = NorteTheme.dark.extension<NorteColors>()!.warning;

    expect(decoration.border!.bottom.style, BorderStyle.none);
    expect((decoration.border! as Border).left.color, warning);
    expect(
      (decoration.border! as Border).left.width,
      DivergenceBanner.ruleWidth,
    );
    expect(
      decoration.color,
      warning.withValues(alpha: DivergenceBanner.fillOpacity),
    );
  });

  testWidgets('S02-GT-01: an agreeing card raises no banner', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      NorteTheme.dark,
      TaskCard(
        task: agreeing(),
        onTap: () {},
        onToggleDone: () {},
        onDelete: () {},
        onJiraMenu: () {},
        onKeepLocal: () {},
        onAdoptRemote: () {},
      ),
      size: const Size(520, 220),
    );

    expect(find.byType(DivergenceBanner), findsNothing);
    expect(find.byType(JiraChip), findsOneWidget);
    expect(find.text('PROJ-123'), findsOneWidget);
  });

  testWidgets('S02-GT-01: an unlinked card shows no chip', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      NorteTheme.dark,
      TaskCard(
        task: agreeing().copyWith(jiraLink: null),
        onTap: () {},
        onToggleDone: () {},
        onDelete: () {},
      ),
      size: const Size(520, 200),
    );

    expect(find.byType(JiraChip), findsNothing);
    expect(find.byType(DivergenceBanner), findsNothing);
  });
}
