import '../../domain/entities/reminder.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/reminder_repository.dart';

/// Persists a reminder captured by voice — **the Sprint 05 stub**
/// (`sprint-05` scope note).
///
/// It validates the slots and stores the [Reminder]. It does **not** schedule
/// a notification: that is Sprint 06's whole subject, and the
/// `NotificationScheduler` is deliberately not a dependency here so that
/// "Sprint 05 does not schedule" is a fact about the constructor rather than a
/// promise in a comment.
///
/// **What it can resolve, and what it cannot** (DEC-025). The sprint's "Out"
/// section excludes date/time parsing beyond what the `AiEngine` returns in
/// the slots, so this reads only the two forms that need nothing but the
/// injected clock:
///
/// * an ISO 8601 instant, and
/// * a relative offset — `+20m`, `+90s`, `+1h`, `+2d`.
///
/// A wall-clock phrase like `today 15:00`, `tomorrow 09:00` or `friday 15:00`
/// is refused with a [ValidationFailure], because resolving one correctly
/// needs the device timezone and a weekday calendar — which is exactly
/// S06-IT-02. Implementing it here would be doing a future sprint's work
/// badly; refusing it leaves a failing case Sprint 06 has to make pass, which
/// is the honest way to hand work forward.
class CreateReminder {
  const CreateReminder({
    required this.repository,
    required this.clock,
    required this.idGenerator,
  });

  final ReminderRepository repository;
  final Clock clock;
  final IdGenerator idGenerator;

  /// Stores a reminder saying [text], due at [triggerAt].
  ///
  /// [triggerAt] is the slot exactly as the parser returned it. Returns
  /// [ValidationFailure] for a blank [text] or a [triggerAt] this sprint
  /// cannot resolve, in both cases **without touching the repository**.
  Future<Result<Reminder>> call({
    required String text,
    required String triggerAt,
  }) async {
    final String body = text.trim();
    if (body.isEmpty) {
      return const Err<Reminder>(
        ValidationFailure('reminder text must not be empty', 'text'),
      );
    }

    final DateTime now = clock.now().toUtc();
    final DateTime? due = resolveTriggerAt(triggerAt, now);
    if (due == null) {
      return Err<Reminder>(
        ValidationFailure(
          'this app cannot yet resolve "$triggerAt" to a time',
          'triggerAt',
        ),
      );
    }

    final Reminder reminder = Reminder(
      id: idGenerator.newId(),
      text: body,
      triggerAt: due,
      createdAt: now,
    );

    await repository.save(reminder);
    return Ok<Reminder>(reminder);
  }

  /// [slot] as an instant relative to [now], or `null` when this sprint
  /// cannot read it.
  ///
  /// Exposed for the test that pins exactly which forms Sprint 05 claims —
  /// the boundary is the deliverable, not an implementation detail.
  static DateTime? resolveTriggerAt(String slot, DateTime now) {
    final String value = slot.trim();
    if (value.isEmpty) return null;

    final RegExpMatch? offset = _offset.firstMatch(value);
    if (offset != null) {
      final int amount = int.parse(offset.group(1)!);
      return switch (offset.group(2)!) {
        's' => now.add(Duration(seconds: amount)),
        'm' => now.add(Duration(minutes: amount)),
        'h' => now.add(Duration(hours: amount)),
        _ => now.add(Duration(days: amount)),
      };
    }

    return DateTime.tryParse(value)?.toUtc();
  }

  static final RegExp _offset = RegExp(r'^\+(\d+)\s*([smhd])$');
}
