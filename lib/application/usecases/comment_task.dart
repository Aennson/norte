import '../../domain/entities/task.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/task_repository.dart';

/// Appends a local note to a task (`docs/architecture.md` §3.2).
///
/// **BR-01 in one class.** It holds no Jira gateway and no outbox repository,
/// so there is no code path from here to a linked issue — the guarantee is
/// structural rather than a rule someone has to remember. A user who wants
/// their team to read the note says "comenta no PROJ-123", which is
/// `AddJiraComment` and goes through the outbox (BR-05).
///
/// The id comes from [IdGenerator] and the timestamp from [Clock], as
/// everywhere else, so the test can pin both.
class CommentTask {
  const CommentTask({
    required this.repository,
    required this.clock,
    required this.idGenerator,
  });

  final TaskRepository repository;
  final Clock clock;
  final IdGenerator idGenerator;

  /// Adds [body] to the task with [id] and returns the stored task.
  ///
  /// Returns [ValidationFailure] for a blank body and [NotFoundFailure] when
  /// no task carries [id] — in both cases nothing is written.
  ///
  /// The task's `updatedAt` moves: a note is a change to the task, and a list
  /// sorted by recency that ignored comments would hide the row the user just
  /// touched.
  Future<Result<Task>> call({required String id, required String body}) async {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const Err<Task>(
        ValidationFailure('a comment must not be empty', 'comment'),
      );
    }

    final Task? current = await repository.findById(id);
    if (current == null) {
      return Err<Task>(NotFoundFailure('no task with id $id'));
    }

    final DateTime now = clock.now().toUtc();
    final Task updated = current.copyWith(
      comments: List<TaskComment>.unmodifiable(<TaskComment>[
        ...current.comments,
        TaskComment(id: idGenerator.newId(), body: trimmed, createdAt: now),
      ]),
      updatedAt: now,
    );

    await repository.save(updated);
    return Ok<Task>(updated);
  }
}
