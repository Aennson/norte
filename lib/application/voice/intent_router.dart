import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/entities/voice_settings.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/task_repository.dart';
import '../usecases/add_jira_comment.dart';
import '../usecases/create_reminder.dart';
import '../usecases/create_task.dart';
import '../usecases/refresh_jira_status.dart';
import '../usecases/update_jira_status.dart';

/// Why the app is asking before it acts.
enum ConfirmationReason {
  /// **BR-04** — the parse was under `VoiceIntent.confidenceThreshold`.
  lowConfidence,

  /// The action writes to Jira and the user has left "always confirm Jira
  /// writes" on (`docs/architecture.md` §6.2).
  jiraWrite,
}

/// What routing an intent decided.
sealed class RouteOutcome {
  const RouteOutcome();
}

/// The use case ran. [detail] is a short, already-executed description —
/// the created task, the queued operation, the status that was read.
final class IntentExecuted extends RouteOutcome {
  const IntentExecuted({
    required this.intent,
    this.task,
    this.operation,
    this.reminder,
    this.status,
  });

  final VoiceIntent intent;

  /// The task created by `createTask`, or the one a Jira write was queued
  /// against.
  final Task? task;

  /// The queued Jira operation, for `updateJira` and `addComment` (BR-05).
  final OutboxOperation? operation;

  /// The reminder created by `createReminder`.
  final Reminder? reminder;

  /// The status `queryStatus` read back.
  final String? status;
}

/// Nothing ran. The user has to say yes first.
final class ConfirmationRequired extends RouteOutcome {
  const ConfirmationRequired({required this.intent, required this.reason});

  final VoiceIntent intent;
  final ConfirmationReason reason;
}

/// Nothing ran. One required slot is missing and the app asks for that slot
/// alone.
final class SlotMissing extends RouteOutcome {
  const SlotMissing({required this.intent, required this.slot});

  final VoiceIntent intent;

  /// The slot to ask about — `issueKey`, `transition`, `comment`, `title`,
  /// `text` or `triggerAt`.
  ///
  /// **A slot name, not a question.** The wording is a UI string and must
  /// come from the ARB resources in all three languages (BR-11); a router
  /// that returned "Which ticket?" would be an English literal in the
  /// application layer.
  final String slot;
}

/// Nothing ran, and nothing will: the utterance was not understood.
final class IntentNotUnderstood extends RouteOutcome {
  const IntentNotUnderstood();
}

/// Sends a [VoiceIntent] to the use case that can act on it
/// (`docs/architecture.md` §6.1).
///
/// **It creates no new path to anything.** Every branch below calls a use case
/// that already existed before this sprint, which is what keeps BR-05 true for
/// voice as it is for the buttons: a spoken transition goes through
/// [UpdateJiraStatus] into the outbox, never straight to the gateway. A router
/// that talked to Jira itself would be a second implementation of the offline
/// queue, discovered the first time a user spoke a command on the underground.
///
/// **The order of the guards is the safety.** Understood, then complete, then
/// permitted, then executed — and each guard returns without touching a use
/// case. That is why S05-UT-03 can assert the spy was never called rather than
/// asserting on a value it returned.
class IntentRouter {
  const IntentRouter({
    required this.tasks,
    required this.createTask,
    required this.createReminder,
    required this.updateJiraStatus,
    required this.addJiraComment,
    required this.refreshJiraStatus,
    required this.settings,
  });

  final TaskRepository tasks;
  final CreateTask createTask;
  final CreateReminder createReminder;
  final UpdateJiraStatus updateJiraStatus;
  final AddJiraComment addJiraComment;
  final RefreshJiraStatus refreshJiraStatus;

  /// The user's confirmation preferences, read per call so a change in
  /// Settings takes effect on the next command rather than the next launch.
  final VoiceSettings settings;

  /// Routes [intent].
  ///
  /// [confirmed] is the user having said yes to a [ConfirmationRequired] this
  /// router returned earlier. It skips the confirmation guards and **only**
  /// those: an unknown intent stays unknown and a missing slot stays missing,
  /// because neither is something a confirmation could supply.
  Future<Result<RouteOutcome>> route(
    VoiceIntent intent, {
    bool confirmed = false,
  }) async {
    if (intent.type == IntentType.unknown) {
      return const Ok<RouteOutcome>(IntentNotUnderstood());
    }

    final List<String> missing = intent.missingSlots;
    if (missing.isNotEmpty) {
      return Ok<RouteOutcome>(SlotMissing(intent: intent, slot: missing.first));
    }

    if (!confirmed) {
      final ConfirmationReason? reason = _confirmationFor(intent);
      if (reason != null) {
        return Ok<RouteOutcome>(
          ConfirmationRequired(intent: intent, reason: reason),
        );
      }
    }

    return switch (intent.type) {
      IntentType.createTask => _createTask(intent),
      IntentType.createReminder => _createReminder(intent),
      IntentType.updateJira => _updateJira(intent),
      IntentType.addComment => _addComment(intent),
      IntentType.queryStatus => _queryStatus(intent),
      IntentType.unknown => throw StateError('unreachable — guarded above'),
    };
  }

  /// Why [intent] needs a yes, or `null` when it may simply run.
  ConfirmationReason? _confirmationFor(VoiceIntent intent) {
    // The Jira rule is checked first because it is the stricter one: a write
    // at 0.99 with the setting on still asks, and reporting `lowConfidence`
    // for it would tell the user the parse was doubtful when it was not.
    if (intent.type.writesToJira && settings.alwaysConfirmJiraWrites) {
      return ConfirmationReason.jiraWrite;
    }
    if (!intent.canRunUnconfirmed) return ConfirmationReason.lowConfidence;
    return null;
  }

  // --- the five intents ---------------------------------------------------

  Future<Result<RouteOutcome>> _createTask(VoiceIntent intent) async {
    final Result<Task> created = await createTask(
      title: intent.slotText('title')!,
      priority: _priorityFrom(intent.slots['priority']),
      dueDate: _dateFrom(intent.slots['dueDate']),
    );
    return switch (created) {
      Ok<Task>(:final Task value) => Ok<RouteOutcome>(
        IntentExecuted(intent: intent, task: value),
      ),
      Err<Task>(:final Failure failure) => Err<RouteOutcome>(failure),
    };
  }

  Future<Result<RouteOutcome>> _createReminder(VoiceIntent intent) async {
    final Result<Reminder> created = await createReminder(
      text: intent.slotText('text')!,
      triggerAt: intent.slotText('triggerAt')!,
    );
    return switch (created) {
      Ok<Reminder>(:final Reminder value) => Ok<RouteOutcome>(
        IntentExecuted(intent: intent, reminder: value),
      ),
      Err<Reminder>(:final Failure failure) => Err<RouteOutcome>(failure),
    };
  }

  Future<Result<RouteOutcome>> _updateJira(VoiceIntent intent) async {
    final String key = intent.slotText('issueKey')!;
    final Task? task = await _linkedTask(key);
    if (task == null) return Err<RouteOutcome>(_notLinked(key));

    final Result<OutboxOperation> queued = await updateJiraStatus(
      task: task,
      status: intent.slotText('transition')!,
    );
    return switch (queued) {
      Ok<OutboxOperation>(:final OutboxOperation value) => Ok<RouteOutcome>(
        IntentExecuted(intent: intent, task: task, operation: value),
      ),
      Err<OutboxOperation>(:final Failure failure) => Err<RouteOutcome>(
        failure,
      ),
    };
  }

  Future<Result<RouteOutcome>> _addComment(VoiceIntent intent) async {
    final String key = intent.slotText('issueKey')!;
    final Task? task = await _linkedTask(key);
    if (task == null) return Err<RouteOutcome>(_notLinked(key));

    final Result<OutboxOperation> queued = await addJiraComment(
      task: task,
      body: intent.slotText('comment')!,
    );
    return switch (queued) {
      Ok<OutboxOperation>(:final OutboxOperation value) => Ok<RouteOutcome>(
        IntentExecuted(intent: intent, task: task, operation: value),
      ),
      Err<OutboxOperation>(:final Failure failure) => Err<RouteOutcome>(
        failure,
      ),
    };
  }

  Future<Result<RouteOutcome>> _queryStatus(VoiceIntent intent) async {
    final String key = intent.slotText('issueKey')!;
    final Task? task = await _linkedTask(key);
    if (task == null) return Err<RouteOutcome>(_notLinked(key));

    final Result<JiraRefresh> read = await refreshJiraStatus(task);
    return switch (read) {
      Ok<JiraRefresh>(:final JiraRefresh value) => Ok<RouteOutcome>(
        IntentExecuted(
          intent: intent,
          task: value.task,
          status: value.remoteStatus,
        ),
      ),
      Err<JiraRefresh>(:final Failure failure) => Err<RouteOutcome>(failure),
    };
  }

  // --- helpers ------------------------------------------------------------

  /// The local task linked to [issueKey], case-insensitively, or `null`.
  ///
  /// Case-insensitive because the key arrives from a transcript: a service
  /// that heard "proj cento e vinte e três" and wrote `Proj-123` has
  /// identified the ticket, and refusing it on capitalisation would be the app
  /// being pedantic about its own input.
  Future<Task?> _linkedTask(String issueKey) async {
    final String wanted = issueKey.toUpperCase();
    for (final Task task in await tasks.listAll()) {
      if (task.jiraLink?.issueKey.toUpperCase() == wanted) return task;
    }
    return null;
  }

  Failure _notLinked(String issueKey) =>
      NotLinkedFailure('no local task is linked to $issueKey');

  Priority _priorityFrom(Object? value) => switch (value) {
    'low' => Priority.low,
    'high' => Priority.high,
    'urgent' => Priority.urgent,
    _ => Priority.medium,
  };

  DateTime? _dateFrom(Object? value) => switch (value) {
    final String text => DateTime.tryParse(text)?.toUtc(),
    _ => null,
  };
}
