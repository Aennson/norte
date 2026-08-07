import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/shared/theme/norte_spacing.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/shared/widgets/empty_state.dart';
import 'package:norte/presentation/shared/widgets/norte_button.dart';
import 'package:norte/presentation/shared/widgets/norte_card.dart';
import 'package:norte/presentation/shared/widgets/status_badge.dart';

import '../../support/golden_harness.dart';
import '../../support/test_fonts.dart';

/// S00-GT-01 — appearance of the shared components in dark and light.
void main() {
  setUpAll(loadNorteFonts);

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];

  /// [settle] must be `false` whenever the tree contains a perpetual
  /// animation (the loading spinner) — `pumpAndSettle` would never return.
  /// A fixed pump from a fresh frame keeps the golden deterministic.
  Future<void> pump(
    WidgetTester tester,
    ThemeData theme,
    Widget child, {
    Size size = const Size(360, 320),
    bool settle = true,
  }) async {
    tester.setSurfaceSize(size);
    await tester.pumpWidget(goldenHarness(theme: theme, child: child));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  for (final (String name, ThemeData theme) in themes) {
    testWidgets('S00-GT-01: NorteButton — 4 states ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return Column(
              mainAxisSize: MainAxisSize.min,
              spacing: NorteSpacing.md,
              children: <Widget>[
                NorteButton(label: l10n.actionConfirm, onPressed: () {}),
                NorteButton(
                  key: const Key('hovered'),
                  label: l10n.actionConfirm,
                  onPressed: () {},
                ),
                NorteButton(label: l10n.actionConfirm, onPressed: null),
                NorteButton(
                  label: l10n.actionConfirm,
                  onPressed: () {},
                  isLoading: true,
                ),
              ],
            );
          },
        ),
        settle: false,
      );

      // Second state: a real pointer hover, so the golden shows accentHover.
      final TestGesture pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);
      await pointer.moveTo(tester.getCenter(find.byKey(const Key('hovered'))));
      await tester.pump();

      await expectLater(
        find.byType(Column),
        matchesGoldenFile('images/norte_button_states_$name.png'),
      );
    });

    testWidgets('S00-GT-01: NorteButton — variants ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return Column(
              mainAxisSize: MainAxisSize.min,
              spacing: NorteSpacing.md,
              children: <Widget>[
                NorteButton(label: l10n.actionConfirm, onPressed: () {}),
                NorteButton(
                  label: l10n.actionCancel,
                  onPressed: () {},
                  variant: NorteButtonVariant.secondary,
                ),
                NorteButton(
                  label: l10n.actionDelete,
                  onPressed: () {},
                  variant: NorteButtonVariant.destructive,
                ),
              ],
            );
          },
        ),
      );

      await expectLater(
        find.byType(Column),
        matchesGoldenFile('images/norte_button_variants_$name.png'),
      );
    });

    testWidgets('S00-GT-01: NorteCard ($name)', (WidgetTester tester) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return SizedBox(
              width: 300,
              child: NorteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: NorteSpacing.sm,
                  children: <Widget>[
                    Text(l10n.navTasks, style: theme.textTheme.titleMedium),
                    StatusBadge(
                      status: NorteStatus.inProgress,
                      label: l10n.statusInProgress,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        size: const Size(360, 180),
      );

      await expectLater(
        find.byType(NorteCard),
        matchesGoldenFile('images/norte_card_$name.png'),
      );
    });

    testWidgets('S00-GT-01: StatusBadge — 4 statuses ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: NorteSpacing.md,
              children: <Widget>[
                StatusBadge(status: NorteStatus.todo, label: l10n.statusTodo),
                StatusBadge(
                  status: NorteStatus.inProgress,
                  label: l10n.statusInProgress,
                ),
                StatusBadge(status: NorteStatus.done, label: l10n.statusDone),
                StatusBadge(
                  status: NorteStatus.blocked,
                  label: l10n.statusBlocked,
                ),
              ],
            );
          },
        ),
        size: const Size(300, 220),
      );

      await expectLater(
        find.byType(Column),
        matchesGoldenFile('images/status_badge_$name.png'),
      );
    });

    testWidgets('S00-GT-01: EmptyState ($name)', (WidgetTester tester) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return SizedBox(
              width: 320,
              height: 220,
              child: EmptyState(
                icon: LucideIcons.listChecks,
                message: l10n.tasksEmptyMessage,
                actionLabel: l10n.actionRetry,
                onAction: () {},
              ),
            );
          },
        ),
      );

      await expectLater(
        find.byType(EmptyState),
        matchesGoldenFile('images/empty_state_$name.png'),
      );
    });
  }
}
