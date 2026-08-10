import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/notification_scheduler.dart';
import '../../domain/ports/reminder_repository.dart';

/// Cancels a reminder — **both halves of it** (`sprint-06` validation rules).
///
/// A reminder exists in two places: a row in the database and a registration
/// with the platform. Deleting only the row leaves a notification that still
/// fires, for something the user has already dismissed, deep-linking to an id
/// that no longer resolves. That defect is invisible to any test that checks
/// the list, which is why S06-UT-03 asserts the scheduler was told as well.
///
/// **The scheduler is told first.** `cancel` on an unknown id is a no-op by
/// the port's contract, so cancelling a schedule whose row then fails to
/// delete costs nothing; the reverse order can leave a live notification
/// behind if the process dies between the two.
class CancelReminder {
  const CancelReminder({required this.repository, required this.scheduler});

  final ReminderRepository repository;
  final NotificationScheduler scheduler;

  /// Cancels the reminder with [id].
  ///
  /// Idempotent, like both ports it calls: cancelling something already gone
  /// succeeds rather than reporting a missing row the user cannot act on.
  Future<Result<void>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Err<void>(ValidationFailure('reminder id is empty', 'id'));
    }

    await scheduler.cancel(id);
    await repository.delete(id);
    return const Ok<void>(null);
  }
}
