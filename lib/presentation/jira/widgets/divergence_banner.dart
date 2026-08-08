import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_button.dart';

/// The local×Jira status conflict, shown rather than resolved.
///
/// **BR-02 in one widget.** The app has no rule for which side wins, because
/// there is no rule that is right: the user may have closed the ticket in Jira
/// and not here, or moved on here and not told Jira. So the banner states both
/// values and offers the two decisions, and until one is taken **nothing
/// changes** — neither the local status nor the ticket.
///
/// Visually it is the `warning` treatment of `docs/design-system.md` §4: a 3px
/// `warning` rule on the left over a 15%-opacity `warning` field. Warning, not
/// error — a divergence is a fact about two systems, not a fault.
class DivergenceBanner extends StatelessWidget {
  const DivergenceBanner({
    required this.issueKey,
    required this.localStatus,
    required this.remoteStatus,
    required this.onKeepLocal,
    required this.onAdoptRemote,
    super.key,
  });

  final String issueKey;

  /// Local status, already localized.
  final String localStatus;

  /// Status name as Jira spells it — passed through untranslated, because it
  /// is the site's own workflow vocabulary and the user recognises it there.
  final String remoteStatus;

  /// Keep the local status and queue a transition telling Jira about it.
  final VoidCallback onKeepLocal;

  /// Take Jira's status locally; nothing is sent to the site.
  final VoidCallback onAdoptRemote;

  /// Opacity of the `warning` fill (`docs/design-system.md` §4).
  static const double fillOpacity = 0.15;

  /// Width of the leading rule.
  static const double ruleWidth = 3;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: fillOpacity),
          border: Border(
            left: BorderSide(color: colors.warning, width: ruleWidth),
          ),
          borderRadius: BorderRadius.circular(NorteSpacing.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NorteSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.jiraDivergenceTitle,
                style: NorteTypography.title.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: NorteSpacing.xs),
              Text(
                l10n.jiraDivergenceMessage(localStatus, issueKey, remoteStatus),
                style: NorteTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: NorteSpacing.md),
              Wrap(
                spacing: NorteSpacing.sm,
                runSpacing: NorteSpacing.sm,
                children: <Widget>[
                  NorteButton(
                    label: l10n.jiraDivergenceKeepLocal,
                    onPressed: onKeepLocal,
                    variant: NorteButtonVariant.secondary,
                  ),
                  NorteButton(
                    label: l10n.jiraDivergenceAdoptRemote,
                    onPressed: onAdoptRemote,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
