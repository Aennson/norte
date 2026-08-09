import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_button.dart';
import '../../shared/widgets/norte_text_field.dart';

/// What the manual sheet collected.
class NewReminderInput {
  const NewReminderInput({required this.text, required this.triggerAt});

  final String text;

  /// Typed exactly as the model would have returned it — `in 20 minutes`,
  /// `tomorrow 09:00`. The use case owns reading it, so this sheet does no
  /// parsing and can give no second opinion.
  final String triggerAt;
}

/// The typed fallback for creating a reminder (`sprint-06` scope).
///
/// It exists for the two cases voice cannot serve: a room where speaking aloud
/// is not on, and a machine with no working microphone. Both are ordinary, and
/// a Pillar-5 screen reachable only by talking would be unusable in either.
Future<NewReminderInput?> showNewReminderSheet(BuildContext context) {
  return showModalBottomSheet<NewReminderInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NorteColors.of(context).surface,
    builder: (BuildContext context) => const _NewReminderSheet(),
  );
}

/// The targeted question asked when an utterance named no time (S06-E2E-02).
///
/// One field, because one slot is missing. Asking the whole reminder again
/// would throw away what the user already said.
Future<String?> showReminderTimeSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NorteColors.of(context).surface,
    builder: (BuildContext context) => const _ReminderTimeSheet(),
  );
}

class _NewReminderSheet extends StatefulWidget {
  const _NewReminderSheet();

  @override
  State<_NewReminderSheet> createState() => _NewReminderSheetState();
}

class _NewReminderSheetState extends State<_NewReminderSheet> {
  final TextEditingController _text = TextEditingController();
  final TextEditingController _time = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return _SheetFrame(
      children: <Widget>[
        NorteTextField(
          key: const Key('reminder-text-field'),
          label: l10n.remindersTextLabel,
          controller: _text,
          autofocus: true,
        ),
        const SizedBox(height: NorteSpacing.md),
        NorteTextField(
          key: const Key('reminder-time-field'),
          label: l10n.remindersTimeLabel,
          hint: l10n.remindersTimeHint,
          controller: _time,
        ),
        const SizedBox(height: NorteSpacing.lg),
        NorteButton(
          key: const Key('reminder-create-button'),
          label: l10n.remindersCreate,
          onPressed: () => Navigator.of(
            context,
          ).pop(NewReminderInput(text: _text.text, triggerAt: _time.text)),
        ),
      ],
    );
  }
}

class _ReminderTimeSheet extends StatefulWidget {
  const _ReminderTimeSheet();

  @override
  State<_ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends State<_ReminderTimeSheet> {
  final TextEditingController _time = TextEditingController();

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return _SheetFrame(
      children: <Widget>[
        Text(
          l10n.voiceAskTriggerAt,
          style: NorteTypography.title.copyWith(
            color: NorteColors.of(context).textPrimary,
          ),
        ),
        const SizedBox(height: NorteSpacing.md),
        NorteTextField(
          key: const Key('reminder-answer-time-field'),
          label: l10n.remindersTimeLabel,
          hint: l10n.remindersTimeHint,
          controller: _time,
          autofocus: true,
          onSubmitted: (String value) => Navigator.of(context).pop(value),
        ),
        const SizedBox(height: NorteSpacing.lg),
        NorteButton(
          key: const Key('reminder-answer-time-button'),
          label: l10n.remindersCreate,
          onPressed: () => Navigator.of(context).pop(_time.text),
        ),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: NorteSpacing.lg,
      right: NorteSpacing.lg,
      top: NorteSpacing.lg,
      bottom: NorteSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}
