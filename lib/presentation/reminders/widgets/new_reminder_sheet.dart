import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/ports/time_zone.dart';
import '../../../domain/services/trigger_time.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_button.dart';
import '../../shared/widgets/norte_text_field.dart';
import '../../tasks/task_providers.dart';
import '../reminder_providers.dart';
import 'reminder_card.dart';

/// What the manual sheet collected.
class NewReminderInput {
  const NewReminderInput({required this.text, required this.triggerAt});

  final String text;

  /// A `triggerAt` slot in the grammar `TriggerTime` reads — produced by the
  /// sheet, never typed by the user.
  final String triggerAt;
}

/// The typed fallback for creating a reminder (`sprint-06` scope).
///
/// It exists for the two cases voice cannot serve: a room where speaking aloud
/// is not on, and a machine with no working microphone. Both are ordinary, and
/// a Pillar-5 screen reachable only by talking would be unusable in either.
///
/// **The time is chosen, not typed.** The first version of this sheet had a
/// free-text time field hinting `in 20 minutes` — a phrase `TriggerTime`
/// refuses, because that grammar is what the *model* emits after reading
/// speech, not something a person should have to learn. The Developer met it
/// on the first manual pass and it did not make sense to them, which is the
/// correct reaction. Three one-tap choices cover almost every reminder anybody
/// sets, and the picker covers the rest; neither can be spelled wrong.
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
/// The same chooser, without the text field: one slot is missing, so one
/// answer is asked for. Asking the whole reminder again would throw away what
/// the user already said.
Future<String?> showReminderTimeSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NorteColors.of(context).surface,
    builder: (BuildContext context) => const _ReminderTimeSheet(),
  );
}

class _NewReminderSheet extends ConsumerStatefulWidget {
  const _NewReminderSheet();

  @override
  ConsumerState<_NewReminderSheet> createState() => _NewReminderSheetState();
}

class _NewReminderSheetState extends ConsumerState<_NewReminderSheet> {
  final TextEditingController _text = TextEditingController();
  String _triggerAt = _defaultSlot;

  @override
  void dispose() {
    _text.dispose();
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
        const SizedBox(height: NorteSpacing.lg),
        _TimeChooser(
          value: _triggerAt,
          onChanged: (String slot) => setState(() => _triggerAt = slot),
        ),
        const SizedBox(height: NorteSpacing.lg),
        NorteButton(
          key: const Key('reminder-create-button'),
          label: l10n.remindersCreate,
          onPressed: () => Navigator.of(
            context,
          ).pop(NewReminderInput(text: _text.text, triggerAt: _triggerAt)),
        ),
      ],
    );
  }
}

class _ReminderTimeSheet extends ConsumerStatefulWidget {
  const _ReminderTimeSheet();

  @override
  ConsumerState<_ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends ConsumerState<_ReminderTimeSheet> {
  String _triggerAt = _defaultSlot;

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
        const SizedBox(height: NorteSpacing.lg),
        _TimeChooser(
          value: _triggerAt,
          onChanged: (String slot) => setState(() => _triggerAt = slot),
        ),
        const SizedBox(height: NorteSpacing.lg),
        NorteButton(
          key: const Key('reminder-answer-time-button'),
          label: l10n.remindersCreate,
          onPressed: () => Navigator.of(context).pop(_triggerAt),
        ),
      ],
    );
  }
}

/// The one-tap choices plus the picker, and a line saying what is currently
/// chosen.
class _TimeChooser extends ConsumerWidget {
  const _TimeChooser({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  /// Key of the "in 20 minutes" choice, for the tests that drive it.
  static const Key inTwentyMinutesKey = Key('reminder-time.+20m');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    final List<(Key, String, String)> choices = <(Key, String, String)>[
      (inTwentyMinutesKey, '+20m', l10n.remindersInTwentyMinutes),
      (const Key('reminder-time.+1h'), '+1h', l10n.remindersInAnHour),
      (
        const Key('reminder-time.tomorrow'),
        'tomorrow 09:00',
        l10n.remindersTomorrowMorning,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.remindersTimeLabel,
          style: NorteTypography.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: NorteSpacing.sm),
        Wrap(
          spacing: NorteSpacing.sm,
          runSpacing: NorteSpacing.sm,
          children: <Widget>[
            for (final (Key key, String slot, String label) in choices)
              ChoiceChip(
                key: key,
                label: Text(label),
                selected: value == slot,
                onSelected: (bool _) => onChanged(slot),
              ),
            ActionChip(
              key: const Key('reminder-time.pick'),
              label: Text(l10n.remindersPickDateTime),
              onPressed: () => _pick(context, ref),
            ),
          ],
        ),
        const SizedBox(height: NorteSpacing.sm),
        // What was chosen, resolved and rendered the way the list will show it
        // — so the sheet and the row cannot disagree about what "tomorrow"
        // meant.
        Text(
          _preview(context, ref),
          key: const Key('reminder-time-preview'),
          style: NorteTypography.monoSmall.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }

  String _preview(BuildContext context, WidgetRef ref) {
    final DateTime? resolved = TriggerTime.resolve(
      value,
      ref.watch(clockProvider).now().toUtc(),
      ref.watch(timeZoneProvider),
    );
    return resolved == null ? value : formatReminderTime(context, resolved);
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final TimeZone zone = ref.read(timeZoneProvider);
    final DateTime now = zone.localAt(ref.read(clockProvider).now());

    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime.utc(now.year + 5),
    );
    if (day == null || !context.mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (time == null) return;

    onChanged(
      TriggerTime.slotFor(
        DateTime.utc(day.year, day.month, day.day, time.hour, time.minute),
      ),
    );
  }
}

/// What a sheet opens on. Twenty minutes is the reminder people actually set,
/// and it is one of the three choices, so opening on it means the common case
/// costs no taps at all.
const String _defaultSlot = '+20m';

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
