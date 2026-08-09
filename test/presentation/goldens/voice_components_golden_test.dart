import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/voice/intent_router.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/voice/voice_labels.dart';
import 'package:norte/presentation/voice/widgets/confirm_sheet.dart';
import 'package:norte/presentation/voice/widgets/voice_overlay.dart';

import '../../support/golden_harness.dart';
import '../../support/platform_goldens.dart';
import '../../support/test_fonts.dart';

/// S05-GT-01 — the voice components of `docs/design-system.md` §4.
///
/// Two behaviours are pinned as pictures because neither survives a code
/// review reliably:
///
/// * **The partial is `mono` `textSecondary`, the committed is
///   `textPrimary`.** The grey-to-solid transition is how a user knows the
///   sentence was heard, and a refactor that unified the two colours would
///   read as "tidier" in a diff and silently remove the signal.
/// * **The confidence bar changes colour at the BR-04 threshold.** 0.68 is
///   `warning`; a confident intent is `accent`. A bar that looked the same at
///   either end would make the sheet's whole reason for existing invisible.
void main() {
  setUpAll(() async {
    usePlatformGoldens();
    await loadNorteFonts();
  });

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];

  /// The `updateJira` intent at 0.68 — under the threshold, so the sheet is
  /// there because BR-04 put it there.
  const VoiceIntent doubtful = VoiceIntent(
    type: IntentType.updateJira,
    slots: <String, dynamic>{'issueKey': 'PROJ-123', 'transition': 'Done'},
    confidence: 0.68,
  );

  Future<void> pump(
    WidgetTester tester,
    ThemeData theme,
    Widget child, {
    Size size = const Size(420, 320),
  }) async {
    tester.setSurfaceSize(size);
    await tester.pumpWidget(goldenHarness(theme: theme, child: child));
    await tester.pumpAndSettle();
  }

  for (final (String name, ThemeData theme) in themes) {
    testWidgets('S05-GT-01: VoiceOverlay with a partial ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return VoiceOverlay(
              phase: VoicePhase.listening,
              statusLabel: l10n.voiceListening,
              stopLabel: l10n.voiceStop,
              meterLabel: l10n.voiceMeterLabel,
              // Mid-speech: the meter is up, which is the thing the picture is
              // pinning. A flat meter here would look identical to a dead
              // microphone, and that is exactly the confusion it exists to end.
              level: 0.55,
              onStop: () {},
              partial: 'muda o PROJ-123 pra',
            );
          },
        ),
        size: const Size(420, 220),
      );

      await expectLater(
        find.byType(VoiceOverlay),
        matchesGoldenFile('images/voice_overlay_partial_$name.png'),
      );
    });

    testWidgets('S05-GT-01: VoiceOverlay with a committed segment ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return VoiceOverlay(
              phase: VoicePhase.understanding,
              statusLabel: l10n.voiceUnderstanding,
              stopLabel: l10n.voiceStop,
              meterLabel: l10n.voiceMeterLabel,
              onStop: () {},
              committed: 'muda o PROJ-123 pra concluído',
            );
          },
        ),
        size: const Size(420, 220),
      );

      await expectLater(
        find.byType(VoiceOverlay),
        matchesGoldenFile('images/voice_overlay_committed_$name.png'),
      );
    });

    testWidgets('S05-GT-01: VoiceOverlay asking for a slot ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return VoiceOverlay(
              phase: VoicePhase.asking,
              statusLabel: l10n.voiceUnderstanding,
              stopLabel: l10n.voiceStop,
              meterLabel: l10n.voiceMeterLabel,
              onStop: () {},
              committed: 'muda pra concluído',
              // The targeted question, and only the one slot (S05-UT-05).
              message: slotQuestion(l10n, 'issueKey'),
            );
          },
        ),
        size: const Size(420, 260),
      );

      await expectLater(
        find.byType(VoiceOverlay),
        matchesGoldenFile('images/voice_overlay_asking_$name.png'),
      );
    });

    testWidgets('S05-GT-01: ConfirmSheet at 0.68 confidence ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            return ConfirmSheet(
              title: l10n.voiceConfirmTitle,
              action: intentDescription(l10n, doubtful),
              reason: confirmationReasonText(
                l10n,
                ConfirmationReason.lowConfidence,
              ),
              confidence: doubtful.confidence,
              confidenceLabel: l10n.voiceConfidenceLabel(68),
              confirmLabel: l10n.actionConfirm,
              cancelLabel: l10n.actionCancel,
              onConfirm: () {},
              onCancel: () {},
            );
          },
        ),
        size: const Size(420, 380),
      );

      await expectLater(
        find.byType(ConfirmSheet),
        matchesGoldenFile('images/voice_confirm_sheet_low_$name.png'),
      );
    });

    testWidgets('S05-GT-01: ConfirmSheet on a confident Jira write ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = AppLocalizations.of(context);
            const VoiceIntent confident = VoiceIntent(
              type: IntentType.updateJira,
              slots: <String, dynamic>{
                'issueKey': 'PROJ-123',
                'transition': 'Done',
              },
              confidence: 0.99,
            );
            return ConfirmSheet(
              title: l10n.voiceConfirmTitle,
              action: intentDescription(l10n, confident),
              // The other reason the sheet appears — a policy, not a doubt.
              reason: confirmationReasonText(
                l10n,
                ConfirmationReason.jiraWrite,
              ),
              confidence: confident.confidence,
              confidenceLabel: l10n.voiceConfidenceLabel(99),
              confirmLabel: l10n.actionConfirm,
              cancelLabel: l10n.actionCancel,
              onConfirm: () {},
              onCancel: () {},
            );
          },
        ),
        size: const Size(420, 380),
      );

      await expectLater(
        find.byType(ConfirmSheet),
        matchesGoldenFile('images/voice_confirm_sheet_jira_$name.png'),
      );
    });
  }
}
