import 'package:flutter/material.dart';

import '../theme/norte_colors.dart';
import '../theme/norte_spacing.dart';
import '../theme/norte_typography.dart';

/// Single- or multi-line text input in the terminal aesthetic: `surface` fill,
/// 1px `border`, radius 8, `accent` outline on focus
/// (`docs/design-system.md` §1, §4).
///
/// Labels, hints and error text arrive already localized (BR-11).
class NorteTextField extends StatelessWidget {
  const NorteTextField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.errorText,
    this.maxLines = 1,
    this.autofocus = false,
    this.onSubmitted,
    this.isSecret = false,
  });

  /// Localized field label.
  final String label;

  final TextEditingController controller;

  /// Localized placeholder.
  final String? hint;

  /// Localized validation message; non-null paints the field in `error`.
  final String? errorText;

  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  /// Masks the value and keeps it out of autofill and suggestion caches —
  /// used for the Jira API token, which must not be readable over the user's
  /// shoulder or recoverable from the keyboard's history (BR-08).
  final bool isSecret;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(NorteSpacing.radius),
      borderSide: BorderSide(color: color, width: NorteSpacing.borderWidth),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: NorteTypography.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: NorteSpacing.sm),
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          onSubmitted: onSubmitted,
          obscureText: isSecret,
          enableSuggestions: !isSecret,
          autocorrect: !isSecret,
          cursorColor: colors.accent,
          style: NorteTypography.body.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: NorteTypography.body.copyWith(color: colors.textMuted),
            errorText: errorText,
            errorStyle: NorteTypography.caption.copyWith(color: colors.error),
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
            errorBorder: border(colors.error),
            focusedErrorBorder: border(colors.error),
          ),
        ),
      ],
    );
  }
}
