import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/failures/failure.dart';
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
import '../shared/widgets/norte_text_field.dart';
import 'meeting_labels.dart';
import 'meeting_providers.dart';
import 'summary_screen.dart';

/// Where the user pastes a transcript and has it summarized
/// (`docs/architecture.md` §5.1 — the v1.0 primary input).
///
/// **The retention toggle sits above the Process button on purpose.** BR-03
/// requires the choice to be made *before* the text is processed: afterwards
/// the user has read a summary and is deciding whether to keep evidence, which
/// is a different question asked under different pressure.
///
/// **A failure keeps the transcript.** The error is rendered in place, with
/// the field untouched, because a user who has just pasted twenty minutes of
/// meeting must not have to find it again (S03-E2E-02).
class NewMeetingScreen extends ConsumerStatefulWidget {
  const NewMeetingScreen({super.key});

  /// Route path, nested under the meetings branch.
  static const String routePath = '/meetings/new';

  /// Keys the tests and the E2E suite drive this screen by.
  static const Key titleFieldKey = Key('meeting.title');
  static const Key transcriptFieldKey = Key('meeting.transcript');
  static const Key saveTranscriptKey = Key('meeting.saveTranscript');
  static const Key processButtonKey = Key('meeting.process');
  static const Key retryButtonKey = Key('meeting.retry');

  @override
  ConsumerState<NewMeetingScreen> createState() => _NewMeetingScreenState();
}

class _NewMeetingScreenState extends ConsumerState<NewMeetingScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _transcript = TextEditingController();

  /// Whether the user has typed over the title we pre-filled from the
  /// template, so that changing the template stops rewriting their words.
  bool _titleEdited = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() {
      if (_title.text.isNotEmpty) _titleEdited = true;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _transcript.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<MeetingTemplate>> templates = ref.watch(
      meetingTemplateListProvider,
    );
    final MeetingComposerState composer = ref.watch(meetingComposerProvider);

    // Leaving the screen is a discard, whether by the back button or a gesture
    // (BR-03). The transcript is in a controller and the summary in the
    // notifier; both go with it.
    return PopScope<Object?>(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) ref.read(meetingComposerProvider.notifier).reset();
      },
      child: NorteScreen(
        title: l10n.newMeetingTitle,
        child: templates.when(
          loading: () =>
              LoadingSkeletonList(semanticLabel: l10n.meetingsLoadingLabel),
          error: (Object error, StackTrace stackTrace) => ErrorState(
            message: l10n.meetingsErrorMessage,
            retryLabel: l10n.actionRetry,
            onRetry: () => ref.invalidate(meetingTemplateListProvider),
          ),
          data: (List<MeetingTemplate> data) => data.isEmpty
              ? EmptyState(
                  icon: LucideIcons.fileText,
                  message: l10n.newMeetingNoTemplates,
                )
              : _form(context, l10n, data, composer),
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    List<MeetingTemplate> templates,
    MeetingComposerState composer,
  ) {
    final NorteColors colors = NorteColors.of(context);
    final MeetingTemplate selected = composer.template ?? templates.first;
    final bool isProcessing =
        composer.status == MeetingComposerStatus.processing;

    // The list arrived after the notifier was built, so settle the default
    // choice — and pre-fill the title from it, localized, so the use case
    // never has to invent one (BR-11).
    if (composer.template == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(meetingComposerProvider.notifier).selectTemplate(selected);
        if (!_titleEdited) _title.text = meetingTypeLabel(l10n, selected.type);
      });
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Text(
          l10n.newMeetingTypeLabel,
          style: NorteTypography.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: NorteSpacing.sm),
        Wrap(
          spacing: NorteSpacing.sm,
          runSpacing: NorteSpacing.sm,
          children: <Widget>[
            for (final MeetingTemplate template in templates)
              NorteChip(
                key: Key('meeting.template.${template.id}'),
                label: meetingTypeLabel(l10n, template.type),
                isSelected: template.id == selected.id,
                onSelected: isProcessing
                    ? null
                    : () {
                        ref
                            .read(meetingComposerProvider.notifier)
                            .selectTemplate(template);
                        if (!_titleEdited) {
                          _title.text = meetingTypeLabel(l10n, template.type);
                        }
                      },
              ),
          ],
        ),
        const SizedBox(height: NorteSpacing.lg),
        NorteTextField(
          key: NewMeetingScreen.titleFieldKey,
          label: l10n.newMeetingTitleField,
          controller: _title,
        ),
        const SizedBox(height: NorteSpacing.lg),
        NorteTextField(
          key: NewMeetingScreen.transcriptFieldKey,
          label: l10n.newMeetingTranscriptField,
          hint: l10n.newMeetingTranscriptHint,
          controller: _transcript,
          maxLines: 12,
        ),
        const SizedBox(height: NorteSpacing.lg),
        _RetentionCard(
          retention: composer.retention,
          enabled: !isProcessing,
          onChanged: (RetentionPolicy value) =>
              ref.read(meetingComposerProvider.notifier).setRetention(value),
        ),
        if (composer.status == MeetingComposerStatus.failed &&
            composer.failure != null) ...<Widget>[
          const SizedBox(height: NorteSpacing.lg),
          _FailureCard(failure: composer.failure!, onRetry: _process),
        ],
        const SizedBox(height: NorteSpacing.lg),
        NorteButton(
          key: NewMeetingScreen.processButtonKey,
          label: isProcessing
              ? l10n.newMeetingProcessing
              : l10n.newMeetingProcess,
          icon: LucideIcons.sparkles,
          isLoading: isProcessing,
          onPressed: isProcessing ? null : _process,
        ),
      ],
    );
  }

  Future<void> _process() async {
    final MeetingComposer notifier = ref.read(meetingComposerProvider.notifier);
    await notifier.summarize(transcript: _transcript.text, title: _title.text);

    if (!mounted) return;
    if (ref.read(meetingComposerProvider).status ==
        MeetingComposerStatus.summarized) {
      // The transcript stays in the field behind this route: coming back
      // without saving lands on an untouched form.
      await context.push(SummaryScreen.routePath);
    }
  }
}

/// The BR-03 choice, stated as what will happen rather than as a setting name.
class _RetentionCard extends StatelessWidget {
  const _RetentionCard({
    required this.retention,
    required this.enabled,
    required this.onChanged,
  });

  final RetentionPolicy retention;
  final bool enabled;
  final ValueChanged<RetentionPolicy> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return NorteCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.newMeetingSaveTranscript,
                  style: NorteTypography.body.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: NorteSpacing.xs),
                Text(
                  retention.allowsPersistence
                      ? l10n.newMeetingSaveTranscriptOn
                      : l10n.newMeetingSaveTranscriptOff,
                  style: NorteTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: NewMeetingScreen.saveTranscriptKey,
            value: retention.allowsPersistence,
            activeThumbColor: colors.accent,
            onChanged: enabled
                ? (bool value) => onChanged(
                    value
                        ? RetentionPolicy.persisted
                        : RetentionPolicy.ephemeral,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// A failed attempt, in place, with the transcript still in the field above.
class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return NorteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(LucideIcons.circleAlert, size: 18, color: colors.error),
              const SizedBox(width: NorteSpacing.sm),
              Expanded(
                child: Text(
                  meetingFailureText(l10n, failure),
                  style: NorteTypography.body.copyWith(color: colors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: NorteSpacing.md),
          NorteButton(
            key: NewMeetingScreen.retryButtonKey,
            label: l10n.actionRetry,
            variant: NorteButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
