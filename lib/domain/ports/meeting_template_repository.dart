import '../entities/meeting.dart';
import '../entities/meeting_template.dart';

/// Storage for the summarization templates.
///
/// Templates are **data, not code** (`docs/architecture.md` §5.3): the four
/// defaults are seeded rows like any other, and the user may edit or delete
/// them.
///
/// **Contract**
/// * [seedDefaults] inserts the four built-in templates and is safe to call on
///   every launch: it inserts only ids that are absent, so it neither
///   duplicates a template nor overwrites one the user has edited
///   (S03-IT-02). A default the user deleted stays deleted only until the next
///   seed — restoring it is what "reset to defaults" means, and the user can
///   edit it away again.
/// * [watchAll] emits immediately and after every mutation, ordered by
///   `MeetingType.index` so the four defaults always appear in the same order.
/// * [save] is an upsert keyed by `MeetingTemplate.id`.
/// * A storage error surfaces as a thrown `StorageFailure`.
abstract interface class MeetingTemplateRepository {
  /// Inserts any built-in template that is not already stored.
  Future<void> seedDefaults();

  /// Reactive view of every stored template.
  Stream<List<MeetingTemplate>> watchAll();

  /// One-shot read of every stored template.
  Future<List<MeetingTemplate>> listAll();

  /// The template with [id], or `null` when there is none.
  Future<MeetingTemplate?> findById(String id);

  /// The first template for [type], or `null` when the user deleted it.
  Future<MeetingTemplate?> findByType(MeetingType type);

  /// Inserts or replaces [template].
  Future<void> save(MeetingTemplate template);

  /// Removes the template with [id], if present.
  Future<void> delete(String id);
}
