import '../entities/meeting.dart';

/// Local storage for [Meeting]s.
///
/// **BR-03 is the whole shape of this port.** The adapter stores what it is
/// given; the guarantee that an ephemeral transcript never arrives is enforced
/// one layer up, by `Meeting.forStorage` and the use cases that call it. That
/// split is deliberate — the rule is testable without a database, and an
/// adapter written later cannot be the place it is forgotten.
///
/// **Contract**
/// * [watchAll] emits immediately on subscription and again after every
///   mutation. Ordering is newest first, by `createdAt`.
/// * [save] is an upsert keyed by [Meeting.id].
/// * [delete] is idempotent.
/// * A storage error surfaces as a thrown `StorageFailure`; nothing else
///   escapes the adapter.
abstract interface class MeetingRepository {
  /// Reactive view of every stored meeting, newest first.
  Stream<List<Meeting>> watchAll();

  /// One-shot read of every stored meeting, newest first.
  Future<List<Meeting>> listAll();

  /// The meeting with [id], or `null` when there is none.
  Future<Meeting?> findById(String id);

  /// Inserts or replaces [meeting].
  Future<void> save(Meeting meeting);

  /// Removes the meeting with [id], if present.
  Future<void> delete(String id);
}
