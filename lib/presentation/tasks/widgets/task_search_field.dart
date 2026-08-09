import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';

/// Free-text search over the task list (`docs/architecture.md` §4.1).
///
/// A single dense row rather than a [NorteTextField]: that widget stacks a
/// label above the input, and a labelled box between the filter chips and the
/// list would push the first task below the fold on a phone. The leading icon
/// carries the meaning the label would have.
///
/// **The clear button is not decoration.** An empty box and a box holding a
/// term that matches nothing produce two different empty states, and a user
/// looking at "nothing matched" needs one tap back to the whole list.
class TaskSearchField extends StatefulWidget {
  const TaskSearchField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The term currently filtering the list, or `null` when there is none.
  final String? value;

  /// Called on every keystroke, and with `''` when the field is cleared.
  final ValueChanged<String> onChanged;

  @override
  State<TaskSearchField> createState() => _TaskSearchFieldState();
}

class _TaskSearchFieldState extends State<TaskSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value ?? '',
  );

  @override
  void didUpdateWidget(TaskSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The query is the source of truth: something other than this field can
    // change it — a voice command that filters, a screen that reopens with a
    // term already set — and the box has to say what the list is showing.
    final String value = widget.value ?? '';
    if (value != _controller.text) _controller.text = value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(NorteSpacing.radius),
      borderSide: BorderSide(color: color, width: NorteSpacing.borderWidth),
    );

    return TextField(
      key: const Key('task-search-field'),
      controller: _controller,
      onChanged: widget.onChanged,
      cursorColor: colors.accent,
      style: NorteTypography.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: l10n.tasksSearchHint,
        hintStyle: NorteTypography.body.copyWith(color: colors.textMuted),
        prefixIcon: Icon(LucideIcons.search, size: 18, color: colors.textMuted),
        prefixIconConstraints: const BoxConstraints(
          minWidth: NorteSpacing.xxl,
          minHeight: NorteSpacing.xxl,
        ),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                key: const Key('task-search-clear'),
                icon: Icon(LucideIcons.x, size: 18, color: colors.textMuted),
                tooltip: l10n.tasksSearchClear,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              ),
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NorteSpacing.md,
          vertical: NorteSpacing.md,
        ),
        border: border(colors.border),
        enabledBorder: border(colors.border),
        focusedBorder: border(colors.accent),
      ),
    );
  }
}
