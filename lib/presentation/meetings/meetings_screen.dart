import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/meeting.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_state.dart';
import '../shared/widgets/loading_skeleton.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_card.dart';
import '../shared/widgets/norte_chip.dart';
import '../shared/widgets/norte_screen.dart';
import 'meeting_labels.dart';
import 'meeting_providers.dart';
import 'new_meeting_screen.dart';

/// Meetings destination — the saved summaries (`sprint-03`).
///
/// Four states from one [StreamProvider] over Drift's `watch`, as on the tasks
/// screen (`docs/design-system.md` §6): loading, error, empty, content.
///
/// **What is not here is the point.** A saved meeting shows its summary. It
/// shows a transcript only when the user asked for one to be kept — for every
/// other meeting there is nothing left to show, because BR-03 discarded it.
class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  /// Route path of this destination.
  static const String routePath = '/meetings';

  /// Key the tests and the E2E suite drive the primary action by.
  static const Key newMeetingButtonKey = Key('meetings.new');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Meeting>> meetings = ref.watch(meetingListProvider);

    return NorteScreen(
      title: l10n.navMeetings,
      action: NorteButton(
        key: newMeetingButtonKey,
        label: l10n.meetingsNewMeeting,
        icon: LucideIcons.plus,
        onPressed: () => context.push(NewMeetingScreen.routePath),
      ),
      child: meetings.when(
        loading: () =>
            LoadingSkeletonList(semanticLabel: l10n.meetingsLoadingLabel),
        error: (Object error, StackTrace stackTrace) => ErrorState(
          message: l10n.meetingsErrorMessage,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(meetingListProvider),
        ),
        data: (List<Meeting> data) => data.isEmpty
            ? EmptyState(
                icon: LucideIcons.users,
                message: l10n.meetingsEmptyMessage,
                actionLabel: l10n.meetingsNewMeeting,
                onAction: () => context.push(NewMeetingScreen.routePath),
              )
            : ListView.separated(
                itemCount: data.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: NorteSpacing.md),
                itemBuilder: (BuildContext context, int index) =>
                    _MeetingCard(meeting: data[index]),
              ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final int converted = meeting.actionItems
        .where((ActionItem item) => item.isConverted)
        .length;

    return NorteCard(
      key: Key('meeting-card-${meeting.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  meeting.title,
                  style: NorteTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: NorteSpacing.sm),
              NorteChip(
                label: meetingTypeLabel(l10n, meeting.type),
                isSelected: false,
                onSelected: null,
              ),
            ],
          ),
          const SizedBox(height: NorteSpacing.xs),
          Text(
            // Mono, because a timestamp is technical data
            // (`docs/design-system.md` §1.4).
            meeting.createdAt.toIso8601String(),
            style: NorteTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: NorteSpacing.md),
          for (final MapEntry<String, String> section
              in (meeting.summary?.sections ?? const <String, String>{})
                  .entries)
            Padding(
              padding: const EdgeInsets.only(bottom: NorteSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    section.key,
                    style: NorteTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    section.value.isEmpty
                        ? l10n.summaryEmptySection
                        : section.value,
                    style: NorteTypography.body.copyWith(
                      color: section.value.isEmpty
                          ? colors.textMuted
                          : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          if (meeting.actionItems.isNotEmpty)
            Text(
              l10n.meetingsActionItemSummary(
                meeting.actionItems.length,
                converted,
              ),
              style: NorteTypography.caption.copyWith(color: colors.accent),
            ),
          // Stated rather than assumed: a user looking at a saved meeting can
          // see whether its transcript was kept, and for most meetings the
          // honest answer is that it is gone (BR-03).
          const SizedBox(height: NorteSpacing.xs),
          Text(
            meeting.retention.allowsPersistence
                ? l10n.meetingsTranscriptKept
                : l10n.meetingsTranscriptDiscarded,
            style: NorteTypography.caption.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
