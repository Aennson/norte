import 'package:freezed_annotation/freezed_annotation.dart';

part 'voice_intent.freezed.dart';

/// The five v1.0 voice intents plus the catch-all
/// (`docs/architecture.md` §6.3).
enum IntentType {
  /// Transition a Jira issue — a mutation, always confirmed.
  updateJira,

  /// Comment on a Jira issue — a mutation, always confirmed.
  addComment,

  /// Create a local task.
  createTask,

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
    IntentType.createReminder => true,
    IntentType.queryStatus || IntentType.unknown => false,
  };
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
}
