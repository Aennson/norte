import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/failures/failure.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_card.dart';
import '../shared/widgets/norte_screen.dart';
import 'meeting_labels.dart';
import 'meeting_providers.dart';

/// The summary, for review before anything is kept.
///
/// **Nothing on this screen has been persisted.** The meeting is held in the
/// composer's memory; Save is what writes it, and leaving without saving
/// discards the whole thing — transcript included (BR-03). That is why the
/// screen says so rather than leaving the user to assume.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  /// Route path, nested under the meetings branch.
  static const String routePath = '/meetings/summary';

  /// Keys the tests and the E2E suite drive this screen by.
  static const Key saveButtonKey = Key('summary.save');

  /// Key of the convert button for [itemId].
  static Key convertKey(String itemId) => Key('summary.convert.$itemId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final MeetingComposerState composer = ref.watch(meetingComposerProvider);
    final Meeting? meeting = composer.meeting;

    if (meeting == null || meeting.summary == null) {
      return NorteScreen(
        title: l10n.summaryTitle,
        onBack: () => context.pop(),
        child: EmptyState(
          icon: LucideIcons.fileText,
          message: l10n.summaryGone,
        ),
      );
    }

    final MeetingSummary summary = meeting.summary!;
    return NorteScreen(
      title: meeting.title,
      onBack: () => context.pop(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          for (final MapEntry<String, String> section
              in summary.sections.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: NorteSpacing.md),
              child: _SectionCard(title: section.key, body: section.value),
            ),
          if (summary.actionItems.isNotEmpty) ...<Widget>[
            const SizedBox(height: NorteSpacing.sm),
            _ActionItems(items: summary.actionItems),
          ],
          const SizedBox(height: NorteSpacing.lg),
          _SaveCard(saved: meeting.retention.allowsPersistence),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return NorteCard(
      key: Key('summary.section.$title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: NorteSpacing.sm),
          Text(
            // A section the meeting did not cover says so, rather than
            // rendering as a heading with nothing under it — which reads as a
            // bug rather than as an answer.
            body.isEmpty ? l10n.summaryEmptySection : body,
            style: NorteTypography.body.copyWith(
              color: body.isEmpty ? colors.textMuted : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItems extends ConsumerWidget {
  const _ActionItems({required this.items});

  final List<ActionItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return NorteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.summaryActionItems,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: NorteSpacing.md),
          for (final ActionItem item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: NorteSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.description,
                          style: NorteTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        if (item.assignee != null)
                          Text(
                            item.assignee!,
                            style: NorteTypography.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: NorteSpacing.md),
                  // Converted items keep their place and lose their button —
                  // the record of what was done stays visible, and there is no
                  // control left to make a duplicate with.
                  if (item.isConverted)
                    Row(
                      children: <Widget>[
                        Icon(
                          LucideIcons.check,
                          size: 16,
                          color: colors.success,
                        ),
                        const SizedBox(width: NorteSpacing.xs),
                        Text(
                          l10n.summaryConverted,
                          style: NorteTypography.caption.copyWith(
                            color: colors.success,
                          ),
                        ),
                      ],
                    )
                  else
                    NorteButton(
                      key: SummaryScreen.convertKey(item.id),
                      label: l10n.summaryConvert,
                      variant: NorteButtonVariant.secondary,
                      onPressed: () => _convert(context, ref, item.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    String itemId,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Failure? failure = await ref
        .read(meetingComposerProvider.notifier)
        .convert(itemId);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? l10n.summaryConvertedToast
              : meetingFailureText(l10n, failure),
        ),
      ),
    );
  }
}

/// Save, and a plain statement of what happens if the user does not.
class _SaveCard extends ConsumerWidget {
  const _SaveCard({required this.saved});

  /// Whether the user opted to keep the transcript, which changes what the
  /// warning below has to say.
  final bool saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return NorteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            saved
                ? l10n.summaryDiscardWarningWithTranscript
                : l10n.summaryDiscardWarning,
            style: NorteTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: NorteSpacing.md),
          NorteButton(
            key: SummaryScreen.saveButtonKey,
            label: l10n.summarySave,
            icon: LucideIcons.save,
            onPressed: () => _save(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Failure? failure = await ref
        .read(meetingComposerProvider.notifier)
        .save();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? l10n.summarySaved
              : meetingFailureText(l10n, failure),
        ),
      ),
    );
  }
}
