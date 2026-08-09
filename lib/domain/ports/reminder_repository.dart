import '../entities/reminder.dart';

/// Local storage for [Reminder]s.
///
/// **BR-06 lives in the adapter, not in the caller.** `Reminder` carries a
/// transient [Reminder.sourceAudioNote], and the implementation drops it on
/// write — a repository that persisted whatever it was handed would make the
/// rule depend on every future caller remembering to clear the field.
///
/// **Contract**
/// * [watchAll] emits the full list immediately on subscription and again
///   after every mutation. Ordering is unspecified; the screen sorts.
/// * [save] is an upsert keyed by [Reminder.id], and never writes
///   `sourceAudioNote`. A reminder read back always has it `null`.
/// * [delete] is idempotent.
/// * A storage error surfaces as a thrown `StorageFailure`.
abstract interface class ReminderRepository {
  /// Reactive view of every stored reminder.
  Stream<List<Reminder>> watchAll();

  /// One-shot read of every stored reminder.
  Future<List<Reminder>> listAll();

  /// The reminder with [id], or `null` when there is none.
  Future<Reminder?> findById(String id);

  /// Inserts or replaces [reminder], minus its audio note.
  Future<void> save(Reminder reminder);

  /// Removes the reminder with [id], if present.
  Future<void> delete(String id);
}
