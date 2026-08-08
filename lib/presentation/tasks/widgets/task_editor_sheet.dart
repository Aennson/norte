import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/entities/task.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_button.dart';
import '../../shared/widgets/norte_chip.dart';
import '../../shared/widgets/norte_text_field.dart';
import '../task_labels.dart';

/// What the editor hands back when the user saves.
///
/// Field-level, not entity-level: creating and editing feed different use
/// cases, and neither of them lets the UI choose an id or a timestamp.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.status,
    required this.priority,
    required this.tags,
    this.description,
    this.dueDate,
  });

  final String title;
  final String? description;
  final TaskStatus status;
  final Priority priority;
  final DateTime? dueDate;
  final List<String> tags;
}

/// Create/edit form for a task, shown as a modal bottom sheet.
///
/// [initial] is `null` when creating. Returns the [TaskDraft] on save, or
/// `null` when the user backs out.
class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.initial});

  final Task? initial;

  /// Opens the editor over [context] and resolves with the draft, or `null`.
  static Future<TaskDraft?> show(BuildContext context, {Task? initial}) {
    return showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NorteColors.of(context).bg,
      builder: (BuildContext context) => TaskEditorSheet(initial: initial),
    );
  }

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.initial?.title ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final TextEditingController _tags = TextEditingController(
    text: widget.initial?.tags.join(', ') ?? '',
  );

  late TaskStatus _status = widget.initial?.status ?? TaskStatus.todo;
  late Priority _priority = widget.initial?.priority ?? Priority.medium;
  late DateTime? _dueDate = widget.initial?.dueDate;

  /// Set once the user has tried to save with a blank title — the field is not
  /// painted red before the first attempt.
  bool _titleRejected = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.initial != null;

  void _submit() {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleRejected = true);
      return;
    }
    final String description = _description.text.trim();

    Navigator.of(context).pop(
      TaskDraft(
        title: title,
        description: description.isEmpty ? null : description,
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
        tags: _tags.text
            .split(',')
            .map((String tag) => tag.trim())
            .where((String tag) => tag.isNotEmpty)
            .toList(),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate?.toLocal() ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return SafeArea(
      child: Padding(
        // Lifts the sheet above the keyboard while typing.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(NorteSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _isEditing ? l10n.tasksEditTask : l10n.tasksNewTask,
                  style: NorteTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: NorteSpacing.lg),
                NorteTextField(
                  key: const Key('task-title-field'),
                  label: l10n.taskFieldTitle,
                  hint: l10n.taskFieldTitleHint,
                  controller: _title,
                  autofocus: true,
                  errorText: _titleRejected
                      ? l10n.taskFieldTitleRequired
                      : null,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: NorteSpacing.lg),
                NorteTextField(
                  key: const Key('task-description-field'),
                  label: l10n.taskFieldDescription,
                  controller: _description,
                  maxLines: 3,
                ),
                const SizedBox(height: NorteSpacing.lg),
                _OptionRow<TaskStatus>(
                  label: l10n.taskFieldStatus,
                  values: TaskStatus.values,
                  selected: _status,
                  labelOf: (TaskStatus value) => value.label(l10n),
                  dotOf: (TaskStatus value) => value.dotColor(colors),
                  onSelected: (TaskStatus value) =>
                      setState(() => _status = value),
                ),
                const SizedBox(height: NorteSpacing.lg),
                _OptionRow<Priority>(
                  label: l10n.taskFieldPriority,
                  values: Priority.values,
                  selected: _priority,
                  labelOf: (Priority value) => value.label(l10n),
                  onSelected: (Priority value) =>
                      setState(() => _priority = value),
                ),
                const SizedBox(height: NorteSpacing.lg),
                _DueDateField(
                  dueDate: _dueDate,
                  onPick: _pickDueDate,
                  onClear: () => setState(() => _dueDate = null),
                ),
                const SizedBox(height: NorteSpacing.lg),
                NorteTextField(
                  key: const Key('task-tags-field'),
                  label: l10n.taskFieldTags,
                  hint: l10n.taskFieldTagsHint,
                  controller: _tags,
                ),
                const SizedBox(height: NorteSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    NorteButton(
                      label: l10n.actionCancel,
                      variant: NorteButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: NorteSpacing.md),
                    NorteButton(
                      key: const Key('task-submit-button'),
                      label: _isEditing ? l10n.actionSave : l10n.actionCreate,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled row of [NorteChip]s over the values of an enum.
class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.dotOf,
    super.key,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final Color Function(T)? dotOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: NorteTypography.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: NorteSpacing.sm),
        Wrap(
          spacing: NorteSpacing.sm,
          runSpacing: NorteSpacing.sm,
          children: <Widget>[
            for (final T value in values)
              NorteChip(
                label: labelOf(value),
                isSelected: value == selected,
                dotColor: dotOf?.call(value),
                onSelected: () => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

/// Read-only due-date row: tapping opens the platform picker, the trailing
/// action clears the date.
class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.dueDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.taskFieldDueDate,
          style: NorteTypography.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: NorteSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: NorteButton(
                label: dueDate == null
                    ? l10n.taskFieldDueDateEmpty
                    : formatTaskDate(context, dueDate!),
                variant: NorteButtonVariant.secondary,
                icon: LucideIcons.calendar,
                onPressed: onPick,
              ),
            ),
            if (dueDate != null) ...<Widget>[
              const SizedBox(width: NorteSpacing.sm),
              IconButton(
                onPressed: onClear,
                icon: const Icon(LucideIcons.x, size: 18),
                color: colors.textMuted,
                tooltip: l10n.actionClear,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
