import '../../domain/entities/meeting.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/ports/meeting_repository.dart';
import '../../domain/ports/task_repository.dart';

/// What one conversion produced: the new task, and the meeting with the item
/// marked.
///
/// Both are returned because both changed, and the caller needs the updated
/// meeting to redraw the item as converted whether or not that meeting has
/// ever been saved.
class ActionItemConversion {
  const ActionItemConversion({required this.task, required this.meeting});

  /// The task created from the action item.
  final Task task;

  /// The meeting, with the item now carrying `convertedTaskId`.
  final Meeting meeting;
}

/// Turns one action item into a task — the one-tap conversion
/// (`docs/architecture.md` §5.2).
///
/// **Conversion is individual and once-only.** Individual because a summary
/// usually contains follow-ups that belong to other people, and converting the
/// lot would fill the user's task list with other people's work. Once-only
/// because the alternative is a task list with three copies of "update the
/// runbook" and no way to tell which one is real — so a second attempt is
/// refused with [AlreadyConvertedFailure] rather than quietly obeyed
/// (S03-UT-05).
class ConvertActionItemToTask {
  const ConvertActionItemToTask({
    required this.tasks,
    required this.meetings,
    required this.clock,
    required this.idGenerator,
  });

  final TaskRepository tasks;
  final MeetingRepository meetings;
  final Clock clock;
  final IdGenerator idGenerator;

  /// Converts the item [itemId] of [meeting].
  Future<Result<ActionItemConversion>> call({
    required Meeting meeting,
    required String itemId,
  }) async {
    final MeetingSummary? summary = meeting.summary;
    if (summary == null) {
      return const Err<ActionItemConversion>(
        ValidationFailure('this meeting has no summary yet'),
      );
    }

    final ActionItem? item = summary.itemById(itemId);
    if (item == null) {
      return const Err<ActionItemConversion>(
        ValidationFailure('no such action item', 'itemId'),
      );
    }

    final String? already = item.convertedTaskId;
    if (already != null) {
      return Err<ActionItemConversion>(AlreadyConvertedFailure(already));
    }

    final String title = item.description.trim();
    if (title.isEmpty) {
      return const Err<ActionItemConversion>(
        ValidationFailure('the action item has no text to make a task from'),
      );
    }

    // "A reference to the meeting id (if saved)" — an unsaved meeting has no
    // id worth pointing at, because leaving the result screen discards it
    // (BR-03). Checking storage rather than assuming keeps the reference
    // honest: a task never points at a meeting that is not there.
    final bool meetingIsStored = await meetings.findById(meeting.id) != null;

    final DateTime now = clock.now().toUtc();
    final Task task = Task(
      id: idGenerator.newId(),
      title: title,
      status: TaskStatus.todo,
      dueDate: item.dueDate,
      // The assignee is not a Norte concept — the app is single-user — so it
      // goes in the description rather than being silently dropped.
      description: item.assignee == null
          ? null
          : 'Assigned in the meeting to ${item.assignee}',
      tags: const <String>[meetingTag],
      sourceMeetingId: meetingIsStored ? meeting.id : null,
      createdAt: now,
      updatedAt: now,
    );

    final Meeting updated = meeting.copyWith(
      summary: summary.withItem(item.copyWith(convertedTaskId: task.id)),
    );

    try {
      await tasks.save(task);
      // Only a meeting that is already stored is written back. Saving one here
      // would persist a meeting the user has not asked to keep, and with it a
      // transcript BR-03 says is gone the moment they leave the screen.
      if (meetingIsStored) await meetings.save(updated.forStorage);
    } on Failure catch (failure) {
      return Err<ActionItemConversion>(failure);
    }

    return Ok<ActionItemConversion>(
      ActionItemConversion(task: task, meeting: updated),
    );
  }
}
