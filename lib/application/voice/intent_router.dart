import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/entities/voice_settings.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/task_repository.dart';
import '../../domain/ports/voice_settings_store.dart';
import '../../domain/services/text_match.dart';
import '../usecases/add_jira_comment.dart';
import '../usecases/comment_task.dart';
import '../usecases/create_reminder.dart';
import '../usecases/create_task.dart';
import '../usecases/delete_task.dart';
import '../usecases/refresh_jira_status.dart';
import '../usecases/update_jira_status.dart';
import '../usecases/update_task.dart';

/// Why the app is asking before it acts.
enum ConfirmationReason {
  /// **BR-04** — the parse was under `VoiceIntent.confidenceThreshold`.
  lowConfidence,

  /// The action writes to Jira and the user has left "always confirm Jira
  /// writes" on (`docs/architecture.md` §6.2).
  jiraWrite,

  /// The action deletes a task. Asked **at any confidence** — there is no undo
  /// in v1.0 (`sprint-05a` validation rules).
  deletion,
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
    this.deletedTitle,
    this.resolvedApproximately = false,
  });

  final VoiceIntent intent;

  /// The task created by `createTask`, the one a local intent changed, or the
  /// one a Jira write was queued against.
  final Task? task;

  /// The queued Jira operation, for `updateJira` and `addComment` (BR-05).
  final OutboxOperation? operation;

  /// The reminder created by `createReminder`.
  final Reminder? reminder;

  /// The status `queryStatus` read back.
  final String? status;

  /// Title of the task `deleteTask` removed.
  ///
  /// The row is gone, so [task] cannot carry it, and "deleted" without saying
  /// *what* is the one outcome message a user cannot check.
  final String? deletedTitle;

  /// `true` when `taskRef` reached its task through tier 4 of §6.3.1 — the one
  /// tier that consults a threshold rather than an exact answer.
  ///
  /// Not a warning and not a different outcome: the action ran. It exists
  /// because the presentation layer names the row for every mutating local
  /// intent, and a caller that wants to know *why* a row it did not expect was
  /// named should not have to re-run the ladder to find out.
  final bool resolvedApproximately;
}

/// Nothing ran. The user has to say yes first.
final class ConfirmationRequired extends RouteOutcome {
  const ConfirmationRequired({
    required this.intent,
    required this.reason,
    this.task,
  });

  final VoiceIntent intent;
  final ConfirmationReason reason;

  /// The local task the action would act on, once `taskRef` has resolved.
  ///
  /// Resolution happens **before** the confirmation guard so the sheet can
  /// name the row: "delete a task" is not a question anybody can answer, and
  /// "delete *Ligar para Samara*" is.
  final Task? task;
}

/// Nothing ran. One required slot is missing and the app asks for that slot
/// alone.
final class SlotMissing extends RouteOutcome {
  const SlotMissing({required this.intent, required this.slot});

  final VoiceIntent intent;

  /// The slot to ask about — `issueKey`, `transition`, `comment`, `title`,
  /// `text`, `triggerAt`, `taskRef` or `change`.
  ///
  /// **A slot name, not a question.** The wording is a UI string and must
  /// come from the ARB resources in all three languages (BR-11); a router
  /// that returned "Which ticket?" would be an English literal in the
  /// application layer.
  final String slot;
}

/// Nothing ran, and nothing was changed: no task's title contains the phrase
/// the user said (`docs/architecture.md` §6.3.1, case 3).
final class TaskNotFound extends RouteOutcome {
  const TaskNotFound({required this.intent, required this.reference});

  final VoiceIntent intent;

  /// The phrase that matched nothing, so the app can say which one it was.
  final String reference;
}

/// Nothing ran. Several tasks match the phrase and the app asks which
/// (§6.3.1, case 2).
///
/// **It does not guess.** Two tasks called "Ligar para Samara" and "Ligar para
/// Samara de novo" are a question, not a coin toss — and the destructive case
/// is why: a wrong row deleted is not recoverable in v1.0.
final class TaskAmbiguous extends RouteOutcome {
  const TaskAmbiguous({
    required this.intent,
    required this.reference,
    required this.candidates,
  });

  final VoiceIntent intent;
  final String reference;

  /// Every task the phrase matched, in list order. Always two or more.
  final List<Task> candidates;
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
/// **The local intents cannot reach Jira at all** (BR-01). `commentTask` holds
/// [CommentTask], which holds a task repository and nothing else, so there is
/// no code path from a spoken note to a linked issue — S05a-UT-06 asserts the
/// outbox stays empty, and the structure is what makes that true rather than a
/// rule someone has to remember.
///
/// **The order of the guards is the safety.** Understood, then complete, then
/// *resolved*, then permitted, then executed — and each guard returns without
/// touching a use case. Resolution sits before permission on purpose: a
/// confirmation sheet that cannot name the row it is about is not a
/// confirmation.
class IntentRouter {
  const IntentRouter({
    required this.tasks,
    required this.createTask,
    required this.updateTask,
    required this.deleteTask,
    required this.commentTask,
    required this.createReminder,
    required this.updateJiraStatus,
    required this.addJiraComment,
    required this.refreshJiraStatus,
    required this.settings,
  });

  final TaskRepository tasks;
  final CreateTask createTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;
  final CommentTask commentTask;
  final CreateReminder createReminder;
  final UpdateJiraStatus updateJiraStatus;
  final AddJiraComment addJiraComment;
  final RefreshJiraStatus refreshJiraStatus;

  /// The user's confirmation preferences.
  ///
  /// The **store**, not a snapshot of it, and read on every call. A snapshot
  /// taken when the router was built has a window in which it is wrong — the
  /// one right after launch, before a stream has emitted, which is exactly
  /// when a user who turned confirmation off would be surprised to be asked.
  /// Asking the store costs one local read and has no such window.
  final VoiceSettingsStore settings;

  /// Routes [intent].
  ///
  /// [confirmed] is the user having said yes to a [ConfirmationRequired] this
  /// router returned earlier. It skips the confirmation guards and **only**
  /// those: an unknown intent stays unknown and a missing slot stays missing,
  /// because neither is something a confirmation could supply.
  ///
  /// [taskId] is the user having answered a [TaskAmbiguous] by naming one of
  /// the candidates. It replaces the `taskRef` lookup rather than refining it,
  /// so answering the question cannot re-open it.
  Future<Result<RouteOutcome>> route(
    VoiceIntent intent, {
    bool confirmed = false,
    String? taskId,
  }) async {
    if (intent.type == IntentType.unknown) {
      return const Ok<RouteOutcome>(IntentNotUnderstood());
    }

    final List<String> missing = intent.missingSlots;
    if (missing.isNotEmpty) {
      return Ok<RouteOutcome>(SlotMissing(intent: intent, slot: missing.first));
    }

    Task? target;
    bool approximate = false;
    if (intent.type.needsTaskRef) {
      final _Resolution resolution = await _resolve(intent, taskId);
      if (resolution.outcome case final RouteOutcome unresolved) {
        return Ok<RouteOutcome>(unresolved);
      }
      target = resolution.task;
      approximate = resolution.approximate;
    }

    if (!confirmed) {
      final ConfirmationReason? reason = await _confirmationFor(intent);
      if (reason != null) {
        return Ok<RouteOutcome>(
          ConfirmationRequired(intent: intent, reason: reason, task: target),
        );
      }
    }

    return switch (intent.type) {
      IntentType.createTask => _createTask(intent),
      IntentType.updateTask => _updateTask(intent, target!, approximate),
      IntentType.deleteTask => _deleteTask(intent, target!, approximate),
      IntentType.commentTask => _commentTask(intent, target!, approximate),
      IntentType.createReminder => _createReminder(intent),
      IntentType.updateJira => _updateJira(intent),
      IntentType.addComment => _addComment(intent),
      IntentType.queryStatus => _queryStatus(intent),
      IntentType.unknown => throw StateError('unreachable — guarded above'),
    };
  }

  /// Why [intent] needs a yes, or `null` when it may simply run.
  Future<ConfirmationReason?> _confirmationFor(VoiceIntent intent) async {
    // Deletion is checked first because it is the only unconditional one: it
    // asks at 0.99 as readily as at 0.40, and reporting `lowConfidence` for a
    // confident deletion would tell the user the parse was doubtful when the
    // irreversibility is the whole reason.
    if (intent.type.isDestructive) return ConfirmationReason.deletion;
    if (intent.type.writesToJira) {
      final VoiceSettings preferences = await settings.read();
      // The Jira rule is checked before the confidence one for the same
      // reason: a write at 0.99 with the setting on still asks.
      if (preferences.alwaysConfirmJiraWrites) {
        return ConfirmationReason.jiraWrite;
      }
    }
    if (!intent.canRunUnconfirmed) return ConfirmationReason.lowConfidence;
    return null;
  }

  // --- the local task intents ---------------------------------------------

  Future<Result<RouteOutcome>> _createTask(VoiceIntent intent) async {
    final Result<Task> created = await createTask(
      title: intent.slotText('title')!,
      description: intent.slotText('description'),
      // The vocabularies of §6.3.2, and the use case's own defaults when the
      // utterance carried neither — `CreateTask` already says what a task with
      // nothing said about it is.
      status: statusFrom(intent.slots['status']) ?? TaskStatus.todo,
      priority: priorityFrom(intent.slots['priority']) ?? Priority.medium,
      dueDate: _dateFrom(intent.slots['dueDate']),
    );
    return switch (created) {
      Ok<Task>(:final Task value) => Ok<RouteOutcome>(
        IntentExecuted(intent: intent, task: value),
      ),
      Err<Task>(:final Failure failure) => Err<RouteOutcome>(failure),
    };
  }

  Future<Result<RouteOutcome>> _updateTask(
    VoiceIntent intent,
    Task target,
    bool approximate,
  ) async {
    final String? description = intent.slotText('description');
    final DateTime? dueDate = _dateFrom(intent.slots['dueDate']);
    final Result<Task> updated = await updateTask(
      id: target.id,
      title: intent.slotText('title'),
      description: description == null ? null : Patch<String?>(description),
      status: statusFrom(intent.slots['status']),
      priority: priorityFrom(intent.slots['priority']),
      dueDate: dueDate == null ? null : Patch<DateTime?>(dueDate),
    );
    return switch (updated) {
      Ok<Task>(:final Task value) => Ok<RouteOutcome>(
        IntentExecuted(
          intent: intent,
          task: value,
          resolvedApproximately: approximate,
        ),
      ),
      Err<Task>(:final Failure failure) => Err<RouteOutcome>(failure),
    };
  }

  Future<Result<RouteOutcome>> _deleteTask(
    VoiceIntent intent,
    Task target,
    bool approximate,
  ) async {
    final Result<void> removed = await deleteTask(target.id);
    return switch (removed) {
      Ok<void>() => Ok<RouteOutcome>(
        IntentExecuted(
          intent: intent,
          deletedTitle: target.title,
          resolvedApproximately: approximate,
        ),
      ),
      Err<void>(:final Failure failure) => Err<RouteOutcome>(failure),
    };
  }

  Future<Result<RouteOutcome>> _commentTask(
    VoiceIntent intent,
    Task target,
    bool approximate,
  ) async {
    final Result<Task> commented = await commentTask(
      id: target.id,
      body: intent.slotText('comment')!,
    );
    return switch (commented) {
      Ok<Task>(:final Task value) => Ok<RouteOutcome>(
        IntentExecuted(
          intent: intent,
          task: value,
          resolvedApproximately: approximate,
        ),
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

  // --- the Jira intents ----------------------------------------------------

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

  /// Resolves `taskRef` (§6.3.1) into either the one task it named or the
  /// outcome that says why it named none.
  ///
  /// **The ladder of four tiers, in order, each exhausted before the next.**
  /// Exact, containment, squashed, approximate. The first that yields exactly
  /// one task wins; several inside a tier is a question, never a coin toss.
  /// The ordering is the safety: an exact spelling must never be beaten by a
  /// better-scoring approximate one, which is why the tiers are separate
  /// passes rather than one scoring function with bonuses (S05b-UT-08).
  ///
  /// A record rather than a sealed type because the alternative would be two
  /// more classes used in one place, and rather than a field because a router
  /// that remembered anything between calls would be a router two concurrent
  /// commands could confuse.
  Future<_Resolution> _resolve(VoiceIntent intent, String? taskId) async {
    final String reference = intent.slotText('taskRef')!;
    final List<Task> all = await tasks.listAll();

    if (taskId != null) {
      // The user has already answered the question. A chosen id that no longer
      // names a row is a task deleted between the question and the answer, and
      // it reads as "no such task" rather than re-opening the choice.
      for (final Task task in all) {
        if (task.id == taskId) return _Resolution.found(task);
      }
      return _Resolution.unresolved(
        TaskNotFound(intent: intent, reference: reference),
      );
    }

    _Resolution? decide(List<Task> tier, {bool approximate = false}) =>
        switch (tier.length) {
          0 => null, // this tier is exhausted; try the next
          1 => _Resolution.found(tier.single, approximate: approximate),
          _ => _Resolution.unresolved(
            TaskAmbiguous(
              intent: intent,
              reference: reference,
              candidates: List<Task>.unmodifiable(tier),
            ),
          ),
        };

    // Tier 1 — the folded title *is* the phrase. It exists so that a title
    // which is the phrase is not held hostage by a longer one containing it:
    // without it "Ligar para Samara" could never be acted on while "Ligar para
    // Samara de novo" existed.
    final String wanted = TextMatch.fold(reference);
    final _Resolution? tier1 = decide(<Task>[
      for (final Task task in all)
        if (TextMatch.fold(task.title) == wanted) task,
    ]);
    if (tier1 != null) return tier1;

    // Tier 2 — the folded title contains the phrase.
    final _Resolution? tier2 = decide(<Task>[
      for (final Task task in all)
        if (TextMatch.contains(task.title, reference)) task,
    ]);
    if (tier2 != null) return tier2;

    // From here on the comparison stops being the title as written, so the
    // digit rule applies: a candidate whose digit runs disagree with the
    // phrase's is out of tiers 3 and 4 entirely, not merely out-scored
    // (DEC-035, S05b-UT-04).
    final List<Task> comparable = <Task>[
      for (final Task task in all)
        if (_digitsAgree(reference, task.title)) task,
    ];

    // Tier 3 — separators are noise. Deterministic: no threshold is consulted,
    // because "Hero Brazil-762" for `HEROBRAZIL-762` is how a person spells an
    // identifier out loud, not something anybody misheard.
    final String squashed = TextMatch.squash(reference);
    if (squashed.isNotEmpty) {
      final _Resolution? tier3 = decide(<Task>[
        for (final Task task in comparable)
          if (TextMatch.squash(task.title).contains(squashed)) task,
      ]);
      if (tier3 != null) return tier3;
    }

    // Tier 4 — approximate, and the only tier that can be wrong. A reference
    // too short to be an approximation of anything never reaches it: "PR" run
    // through an edit-distance metric matches half the list.
    if (squashed.length >= TextMatch.minApproximateLength) {
      final List<(Task, double)> scored = <(Task, double)>[
        for (final Task task in comparable)
          if (TextMatch.similarity(task.title, reference)
              case final double score
              when score >= TextMatch.similarityThreshold)
            (task, score),
      ]..sort(((Task, double) a, (Task, double) b) => b.$2.compareTo(a.$2));

      if (scored.length == 1 ||
          (scored.length > 1 &&
              scored.first.$2 - scored[1].$2 >= TextMatch.similarityMargin)) {
        return _Resolution.found(scored.first.$1, approximate: true);
      }
      if (scored.length > 1) {
        // A near tie is a question. Picking the best of two spellings that are
        // both plausible is how the wrong row gets changed.
        return _Resolution.unresolved(
          TaskAmbiguous(
            intent: intent,
            reference: reference,
            candidates: List<Task>.unmodifiable(<Task>[
              for (final (Task task, double _) in scored) task,
            ]),
          ),
        );
      }
    }

    return _Resolution.unresolved(
      TaskNotFound(intent: intent, reference: reference),
    );
  }

  /// `true` unless [reference] and [title] both carry digit runs and the two
  /// sets differ.
  ///
  /// The asymmetry is deliberate: a phrase with no number in it says nothing
  /// about the numbers in a title, and excluding on that would stop "hero
  /// brazil" from ever finding `HEROBRAZIL-762`. It is two *different* numbers
  /// that make two different chamados.
  static bool _digitsAgree(String reference, String title) {
    final Set<String> spoken = TextMatch.digitRuns(reference);
    final Set<String> written = TextMatch.digitRuns(title);
    if (spoken.isEmpty || written.isEmpty) return true;
    return spoken.length == written.length && spoken.containsAll(written);
  }

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

  DateTime? _dateFrom(Object? value) => switch (value) {
    final String text => DateTime.tryParse(text)?.toUtc(),
    _ => null,
  };
}

/// What the ladder of §6.3.1 decided: either the one task, or the outcome
/// that says why there was not one.
///
/// Exactly one of [task] and [outcome] is ever non-null.
class _Resolution {
  const _Resolution.found(Task this.task, {this.approximate = false})
    : outcome = null;

  const _Resolution.unresolved(RouteOutcome this.outcome)
    : task = null,
      approximate = false;

  final Task? task;
  final RouteOutcome? outcome;

  /// Whether [task] was reached through tier 4 rather than an exact answer.
  final bool approximate;
}

/// The `status` vocabulary of §6.3.2, or `null` for anything else.
///
/// **An unrecognised value is absent, not a default.** A model that answered
/// `"status": "quase pronto"` has not said `todo`, and silently writing one
/// would be the app inventing a change the user never asked for (S05a-UT-02).
TaskStatus? statusFrom(Object? value) => switch (value) {
  final String name =>
    TaskStatus.values
        .where((TaskStatus status) => status.name == name)
        .firstOrNull,
  _ => null,
};

/// The `priority` vocabulary of §6.3.2, or `null` for anything else. Absent
/// rather than defaulted, for the same reason as [statusFrom].
Priority? priorityFrom(Object? value) => switch (value) {
  final String name =>
    Priority.values
        .where((Priority priority) => priority.name == name)
        .firstOrNull,
  _ => null,
};
