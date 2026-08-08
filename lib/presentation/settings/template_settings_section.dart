import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/meeting_template.dart';
import '../../l10n/generated/app_localizations.dart';
import '../meetings/meeting_labels.dart';
import '../meetings/meeting_providers.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_card.dart';
import '../shared/widgets/norte_text_field.dart';

/// Template CRUD (`docs/architecture.md` §5.3 — templates are data, not code).
///
/// The editable surface is the **prompt** and the **section headings**, which
/// is what actually shapes a summary. Restore brings the four built-ins back
/// by re-running the seed, which only ever inserts what is missing — so it
/// cannot overwrite a template the user has spent time on.
class TemplateSettingsSection extends ConsumerWidget {
  const TemplateSettingsSection({super.key});

  /// Keys the tests drive this section by.
  static const Key restoreButtonKey = Key('templates.restore');

  /// Key of the edit button for [templateId].
  static Key editKey(String templateId) => Key('templates.edit.$templateId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final List<MeetingTemplate> templates =
        ref.watch(meetingTemplateListProvider).valueOrNull ??
        const <MeetingTemplate>[];

    return NorteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.templatesSectionTitle,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: NorteSpacing.xs),
          Text(
            l10n.templatesSectionDescription,
            style: NorteTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: NorteSpacing.lg),
          for (final MeetingTemplate template in templates)
            Padding(
              padding: const EdgeInsets.only(bottom: NorteSpacing.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          meetingTypeLabel(l10n, template.type),
                          style: NorteTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          template.sectionTitles.join(' · '),
                          style: NorteTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: NorteSpacing.md),
                  NorteButton(
                    key: TemplateSettingsSection.editKey(template.id),
                    label: l10n.templatesEdit,
                    variant: NorteButtonVariant.secondary,
                    onPressed: () => _edit(context, ref, template),
                  ),
                ],
              ),
            ),
          NorteButton(
            key: TemplateSettingsSection.restoreButtonKey,
            label: l10n.templatesRestoreDefaults,
            icon: LucideIcons.rotateCcw,
            variant: NorteButtonVariant.secondary,
            onPressed: () async {
              await ref.read(meetingTemplateRepositoryProvider).seedDefaults();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    MeetingTemplate template,
  ) async {
    final MeetingTemplate? edited = await _TemplateEditorSheet.show(
      context,
      template,
    );
    if (edited == null) return;
    await ref.read(meetingTemplateRepositoryProvider).save(edited);
  }
}

/// Editor for one template's prompt and headings.
class _TemplateEditorSheet extends StatefulWidget {
  const _TemplateEditorSheet({required this.template});

  final MeetingTemplate template;

  /// Opens the editor and returns the edited template, or `null` on cancel.
  static Future<MeetingTemplate?> show(
    BuildContext context,
    MeetingTemplate template,
  ) {
    return showModalBottomSheet<MeetingTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          _TemplateEditorSheet(template: template),
    );
  }

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  late final TextEditingController _prompt = TextEditingController(
    text: widget.template.systemPrompt,
  );

  /// One heading per line — the simplest editable form of an ordered list, and
  /// the one a user can reorder without a drag handle.
  late final TextEditingController _sections = TextEditingController(
    text: widget.template.sectionTitles.join('\n'),
  );

  late bool _extractActionItems = widget.template.extractActionItems;

  @override
  void dispose() {
    _prompt.dispose();
    _sections.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.border,
              width: NorteSpacing.borderWidth,
            ),
          ),
        ),
        padding: const EdgeInsets.all(NorteSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                meetingTypeLabel(l10n, widget.template.type),
                style: NorteTypography.display.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: NorteSpacing.lg),
              NorteTextField(
                label: l10n.templatesPromptField,
                controller: _prompt,
                maxLines: 8,
              ),
              const SizedBox(height: NorteSpacing.lg),
              NorteTextField(
                label: l10n.templatesSectionsField,
                hint: l10n.templatesSectionsHint,
                controller: _sections,
                maxLines: 6,
              ),
              const SizedBox(height: NorteSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.templatesExtractActionItems,
                      style: NorteTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _extractActionItems,
                    activeThumbColor: colors.accent,
                    onChanged: (bool value) =>
                        setState(() => _extractActionItems = value),
                  ),
                ],
              ),
              const SizedBox(height: NorteSpacing.lg),
              Wrap(
                spacing: NorteSpacing.sm,
                children: <Widget>[
                  NorteButton(label: l10n.actionSave, onPressed: _submit),
                  NorteButton(
                    label: l10n.actionCancel,
                    variant: NorteButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    // Guidance is dropped for headings the user typed fresh and preserved for
    // the ones they kept: matching by title means renaming a heading loses its
    // note, which is the honest outcome — the note described the old heading.
    final Map<String, String?> guidance = <String, String?>{
      for (final TemplateSection section in widget.template.sections)
        section.title: section.guidance,
    };

    final List<TemplateSection> sections = <TemplateSection>[
      for (final String line in _sections.text.split('\n'))
        if (line.trim().isNotEmpty)
          TemplateSection(title: line.trim(), guidance: guidance[line.trim()]),
    ];

    Navigator.of(context).pop(
      widget.template.copyWith(
        systemPrompt: _prompt.text.trim(),
        sections: sections,
        extractActionItems: _extractActionItems,
      ),
    );
  }
}
