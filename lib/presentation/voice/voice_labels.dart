import '../../application/voice/intent_router.dart';
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
String intentDescription(AppLocalizations l10n, VoiceIntent intent) =>
    switch (intent.type) {
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
      IntentType.createReminder => l10n.voiceActionCreateReminder(
        intent.slotText('text') ?? '',
        intent.slotText('triggerAt') ?? '',
      ),
      IntentType.queryStatus => l10n.voiceActionQueryStatus(
        intent.slotText('issueKey') ?? '',
      ),
      IntentType.unknown => l10n.voiceNotUnderstood,
    };

/// Why the app is asking before it acts.
String confirmationReasonText(
  AppLocalizations l10n,
  ConfirmationReason reason,
) => switch (reason) {
  ConfirmationReason.jiraWrite => l10n.voiceReasonJiraWrite,
  ConfirmationReason.lowConfidence => l10n.voiceReasonLowConfidence,
};

/// What the user is told after a command ran.
String executedText(AppLocalizations l10n, IntentExecuted executed) =>
    switch (executed.intent.type) {
      IntentType.createTask => l10n.voiceDoneTask,
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
  _ => l10n.aiErrorGeneric,
};
