import '../../application/voice/intent_router.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/failures/failure.dart';
import '../../l10n/generated/app_localizations.dart';

/// The question to ask for a missing slot (BR-11 — no screen holds a
/// literal).
///
/// This is where `SlotMissing.slot` becomes "Which ticket?", in whichever of
/// the three languages the user is running. The application layer deliberately
/// stops at the slot name so that this mapping — the only part that is
/// wording — lives with the other wording (S05-UT-05).
String slotQuestion(AppLocalizations l10n, String slot) => switch (slot) {
  'issueKey' => l10n.voiceAskIssueKey,
  'transition' => l10n.voiceAskTransition,
  'comment' => l10n.voiceAskComment,
  'title' => l10n.voiceAskTitle,
  'text' => l10n.voiceAskText,
  'triggerAt' => l10n.voiceAskTriggerAt,
  'taskRef' => l10n.voiceAskTaskRef,
  VoiceIntent.changeSlot => l10n.voiceAskChange,
  // Every slot in `IntentType.requiredSlots` is covered above. A new one
  // reaching here would be a missing translation, and showing the raw name is
  // more use to whoever has to fix it than an empty sheet.
  _ => slot,
};

/// What the app understood, in one line, for the confirmation sheet.
///
/// Rendered in `mono` (`docs/design-system.md` §4): it is the interpreted
/// command, and the user is being asked to check it the way they would check a
/// command line.
///
/// [task] is the row a local intent resolved to, when it has resolved. It
/// wins over the spoken `taskRef` on purpose: the user is being asked to
/// approve a deletion, and the title of the row that will actually go is a
/// better thing to check than the three words they happened to say.
String intentDescription(
  AppLocalizations l10n,
  VoiceIntent intent, {
  Task? task,
}) {
  final String reference = task?.title ?? intent.slotText('taskRef') ?? '';
  return switch (intent.type) {
    IntentType.updateJira => l10n.voiceActionUpdateJira(
      intent.slotText('issueKey') ?? '',
      intent.slotText('transition') ?? '',
    ),
    IntentType.addComment => l10n.voiceActionAddComment(
      intent.slotText('issueKey') ?? '',
      intent.slotText('comment') ?? '',
    ),
    IntentType.createTask => l10n.voiceActionCreateTask(
      intent.slotText('title') ?? '',
    ),
    IntentType.updateTask => l10n.voiceActionUpdateTask(reference),
    IntentType.deleteTask => l10n.voiceActionDeleteTask(reference),
    IntentType.commentTask => l10n.voiceActionCommentTask(
      reference,
      intent.slotText('comment') ?? '',
    ),
    IntentType.createReminder => l10n.voiceActionCreateReminder(
      intent.slotText('text') ?? '',
      intent.slotText('triggerAt') ?? '',
    ),
    IntentType.queryStatus => l10n.voiceActionQueryStatus(
      intent.slotText('issueKey') ?? '',
    ),
    IntentType.unknown => l10n.voiceNotUnderstood,
  };
}

/// Why the app is asking before it acts.
String confirmationReasonText(
  AppLocalizations l10n,
  ConfirmationReason reason,
) => switch (reason) {
  ConfirmationReason.jiraWrite => l10n.voiceReasonJiraWrite,
  ConfirmationReason.deletion => l10n.voiceReasonDeletion,
  ConfirmationReason.lowConfidence => l10n.voiceReasonLowConfidence,
};

/// What the user is told after a command ran.
String executedText(AppLocalizations l10n, IntentExecuted executed) =>
    switch (executed.intent.type) {
      IntentType.createTask => l10n.voiceDoneTask,
      // Every mutating local intent names the row it acted on (Sprint 05b).
      // The ladder of §6.3.1 can resolve a spoken reference to a title spelled
      // differently, and "Task updated" would leave the user to find out which
      // one the next time they read the list — by which point the wrong row
      // has been wrong for a while.
      IntentType.updateTask => l10n.voiceDoneTaskUpdated(
        executed.task?.title ?? '',
      ),
      IntentType.deleteTask => l10n.voiceDoneTaskDeleted(
        executed.deletedTitle ?? '',
      ),
      // Says where the note went, and onto what. The same sentence with an
      // issue key in it would have reached the user's whole team, and the
      // difference is the one thing worth reporting back (BR-01, §3.2).
      IntentType.commentTask => l10n.voiceDoneTaskCommented(
        executed.task?.title ?? '',
      ),
      IntentType.createReminder => l10n.voiceDoneReminder,
      // BR-05 in one sentence: the write is queued, not sent. Saying "done"
      // would promise something the outbox has not delivered yet.
      IntentType.updateJira || IntentType.addComment => l10n.voiceDoneQueued,
      IntentType.queryStatus => l10n.voiceDoneStatus(
        executed.intent.slotText('issueKey') ?? '',
        executed.status ?? '',
      ),
      IntentType.unknown => l10n.voiceNotUnderstood,
    };

/// What the user is told when a spoken `taskRef` resolved to nothing
/// (`docs/architecture.md` §6.3.1, case 3).
///
/// It names the phrase back. "No such task" alone leaves the user unable to
/// tell a task they do not have from a word the service misheard.
String taskNotFoundText(AppLocalizations l10n, TaskNotFound outcome) =>
    l10n.voiceTaskNotFound(outcome.reference);

/// The question asked when several tasks match (§6.3.1, case 2).
///
/// Every candidate is listed, because the user cannot choose between options
/// they cannot see — and the app is deliberately not choosing for them.
String taskAmbiguousText(AppLocalizations l10n, TaskAmbiguous outcome) =>
    l10n.voiceTaskAmbiguous(
      outcome.candidates.map((Task task) => task.title).join(', '),
    );

/// What the user is told when a voice command fails.
///
/// As with `meetingFailureText`, the mapping is the point: each failure sends
/// the user somewhere different, and "something went wrong" would throw that
/// away. [NotLinkedFailure] gets its own line because the fix is neither a
/// retry nor a trip to Settings — it is linking the ticket.
String voiceFailureText(
  AppLocalizations l10n,
  Failure failure, {
  String? issueKey,
}) => switch (failure) {
  NotLinkedFailure() => l10n.voiceErrorNotLinked(issueKey ?? ''),
  // The one validation this sprint raises on its own initiative: a reminder
  // time it cannot resolve until Sprint 06 (DEC-025). It knows exactly what is
  // wrong, so falling through to a generic error would be the app withholding
  // what it knows — and it suggests the phrasing that does work.
  ValidationFailure(field: 'triggerAt') => l10n.voiceTimeUnsupported,
  MissingApiKeyFailure() => l10n.aiErrorMissingKey,
  AuthFailure() => l10n.aiErrorRejectedKey,
  AiResponseFailure() => l10n.aiErrorUnreadable,
  TranscriptionFailure() => l10n.transcriptionErrorFailed,
  MicrophonePermissionFailure() => l10n.recordMeetingPermissionBody,
  RecordingFailure() => l10n.recordingErrorFailed,
  RateLimitFailure() => l10n.aiErrorRateLimited,
  NetworkFailure() => l10n.aiErrorOffline,
  TimeoutFailure() => l10n.aiErrorTimeout,
  StorageFailure() => l10n.aiErrorStorage,
  // Sprint 07. A voice command goes through the same engine chain a summary
  // does, so it meets the same three failures — and a user who is talking to
  // the app is the least placed to go and read a log about it.
  AiUnavailableFailure() => l10n.aiErrorEngineUnavailable,
  AiProcessFailure() => l10n.aiErrorEngineNotInstalled,
  AiTimeoutFailure() => l10n.aiErrorEngineTooSlow,
  _ => l10n.aiErrorGeneric,
};
