import 'package:freezed_annotation/freezed_annotation.dart';

part 'voice_intent.freezed.dart';

/// The v1.0 voice intents plus the catch-all (`docs/architecture.md` §6.3).
///
/// **Local first, Jira on request.** The four local-task intents are the ones
/// an utterance about work reaches by default; the three Jira ones are reached
/// only when an issue key or the word "Jira" is spoken. A wrong local task is a
/// row the user deletes, a wrong Jira write is a change their whole team saw.
enum IntentType {
  /// Transition a Jira issue — a mutation, always confirmed.
  updateJira,

  /// Comment on a Jira issue — a mutation, always confirmed.
  addComment,

  /// Create a local task.
  createTask,

  /// Change a local task's status, priority, title, description or due date.
  updateTask,

  /// Delete a local task. **Always confirmed**, whatever the confidence
  /// (§6.3.1) — there is no undo in v1.0.
  deleteTask,

  /// Append a local [TaskComment]. Never reaches Jira (§3.2).
  commentTask,

  /// Create a reminder plus its notification.
  createReminder,

  /// Read-only status lookup.
  queryStatus,

  /// Unparseable utterance. Never triggers a mutating action.
  unknown;

  /// `true` when acting on the intent changes state somewhere.
  ///
  /// Mutating intents confirm by default, and [unknown] may never become one
  /// (`docs/testing-strategy.md` §5).
  bool get isMutating => switch (this) {
    IntentType.updateJira ||
    IntentType.addComment ||
    IntentType.createTask ||
    IntentType.updateTask ||
    IntentType.deleteTask ||
    IntentType.commentTask ||
    IntentType.createReminder => true,
    IntentType.queryStatus || IntentType.unknown => false,
  };

  /// `true` when the intent names its target by part of a task title rather
  /// than by an unambiguous handle (§6.3.1).
  ///
  /// The three that do share one resolution rule, and it is the rule that
  /// never guesses: one match acts, several ask, none changes nothing.
  bool get needsTaskRef =>
      this == IntentType.updateTask ||
      this == IntentType.deleteTask ||
      this == IntentType.commentTask;

  /// `true` when acting on the intent destroys data the user cannot get back.
  ///
  /// The confidence threshold of BR-04 is a **floor** for this one, not a
  /// gate: `deleteTask` confirms at 0.99 as readily as at 0.40, because a
  /// deletion the user did not mean has no undo in v1.0.
  bool get isDestructive => this == IntentType.deleteTask;

  /// `true` when acting on the intent reaches Jira.
  ///
  /// The distinction the "always confirm Jira writes" setting turns on: a
  /// mistaken local task is a row the user deletes, a mistaken transition is a
  /// change their team sees (`docs/architecture.md` §6.2).
  bool get writesToJira =>
      this == IntentType.updateJira || this == IntentType.addComment;

  /// Slots without which the intent cannot be acted on at all.
  ///
  /// The app asks for **only** what is missing from this list and re-parses
  /// with the answer, rather than making the user say the whole command again
  /// (`sprint-05` validation rules, S05-UT-05). Optional slots — a task's
  /// priority, a due date — are deliberately absent: they refine an action,
  /// they do not gate it.
  List<String> get requiredSlots => switch (this) {
    IntentType.updateJira => const <String>['issueKey', 'transition'],
    IntentType.addComment => const <String>['issueKey', 'comment'],
    IntentType.createTask => const <String>['title'],
    // `taskRef` alone. What an `updateTask` changes is whichever of the
    // optional slots the utterance carried, and demanding a particular one
    // would make "muda a prioridade de X para baixa" and "marca X como
    // concluída" two different intents.
    IntentType.updateTask => const <String>['taskRef'],
    IntentType.deleteTask => const <String>['taskRef'],
    IntentType.commentTask => const <String>['taskRef', 'comment'],
    IntentType.createReminder => const <String>['text', 'triggerAt'],
    IntentType.queryStatus => const <String>['issueKey'],
    IntentType.unknown => const <String>[],
  };

  /// The wire value [name] read back, or [unknown] for anything else.
  ///
  /// A value outside the enum is not an error to raise but an intent to
  /// refuse: the point of `unknown` is that an answer nobody recognises never
  /// becomes an action (`sprint-05` validation rules).
  static IntentType fromWire(Object? value) => IntentType.values.firstWhere(
    (IntentType type) => type.name == value,
    orElse: () => IntentType.unknown,
  );
}

/// What the AI understood from a spoken utterance.
@freezed
abstract class VoiceIntent with _$VoiceIntent {
  const VoiceIntent._();

  const factory VoiceIntent({
    required IntentType type,

    /// Extracted parameters, e.g. `{issueKey: PROJ-123, transition: Done}`.
    ///
    /// The one place `dynamic` is allowed in a public signature
    /// (`docs/project-rules.md` §6) — the slot set is defined by the intent.
    @Default(<String, dynamic>{}) Map<String, dynamic> slots,

    /// Model confidence in `0.0..1.0`.
    @Default(0.0) double confidence,
  }) = _VoiceIntent;

  /// **BR-04** — below 0.75 the user must confirm before anything mutates.
  static const double confidenceThreshold = 0.75;

  /// `true` when the intent may be executed without asking the user first.
  ///
  /// Read-only intents run unconfirmed; mutating ones never do while the
  /// confidence is under [confidenceThreshold] (BR-04).
  bool get canRunUnconfirmed =>
      !type.isMutating || confidence >= confidenceThreshold;

  /// Required slots this intent does not carry, in the order they are asked
  /// for.
  ///
  /// A slot present but blank counts as missing — a model that answered
  /// `{"issueKey": ""}` has not identified a ticket, and treating that as an
  /// answer would send an empty key to Jira.
  List<String> get missingSlots => <String>[
    for (final String slot in type.requiredSlots)
      if (!_hasSlot(slot)) slot,
    // An `updateTask` that names a task and no change is a sentence the model
    // read as a command and the app cannot act on. Asked as a slot rather than
    // refused as unknown, because the user did name a task: they said what,
    // and the app only needs to know what to.
    if (type == IntentType.updateTask && !_hasAnyChange) changeSlot,
  ];

  /// The pseudo-slot [missingSlots] reports when an `updateTask` names nothing
  /// to change. Not a value the model returns — a question the app asks.
  static const String changeSlot = 'change';

  /// The slots an `updateTask` can act on. One of them has to be present.
  static const List<String> updatableSlots = <String>[
    'status',
    'priority',
    'title',
    'description',
    'dueDate',
  ];

  bool get _hasAnyChange => updatableSlots.any(_hasSlot);

  /// `true` when every required slot is present.
  bool get isComplete => missingSlots.isEmpty;

  /// The value of [slot] as trimmed text, or `null` when it is absent, blank,
  /// or not text at all.
  String? slotText(String slot) => switch (slots[slot]) {
    final String value when value.trim().isNotEmpty => value.trim(),
    _ => null,
  };

  bool _hasSlot(String slot) => switch (slots[slot]) {
    null => false,
    final String value => value.trim().isNotEmpty,
    _ => true,
  };
}
