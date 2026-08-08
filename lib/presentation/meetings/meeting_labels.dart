import '../../application/usecases/transcribe_meeting_audio.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/failures/failure.dart';
import '../../l10n/generated/app_localizations.dart';

/// Localized name of a [MeetingType] (BR-11 — no screen holds a literal).
String meetingTypeLabel(AppLocalizations l10n, MeetingType type) =>
    switch (type) {
      MeetingType.daily => l10n.meetingTypeDaily,
      MeetingType.retro => l10n.meetingTypeRetro,
      MeetingType.planning => l10n.meetingTypePlanning,
      MeetingType.oneOnOne => l10n.meetingTypeOneOnOne,
      MeetingType.custom => l10n.meetingTypeCustom,
    };

/// What the user is told when summarizing fails.
///
/// The mapping is the point: each failure sends the user somewhere different.
/// A missing key is a trip to Settings, a rejected key is a *different* trip
/// to Settings, an unreadable answer is worth retrying, and no network is
/// worth waiting on. Collapsing them into "something went wrong" would throw
/// that away (`sprint-03` validation rules).
String meetingFailureText(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      MissingApiKeyFailure() => l10n.aiErrorMissingKey,
      AuthFailure() => l10n.aiErrorRejectedKey,
      AiResponseFailure() => l10n.aiErrorUnreadable,
      RateLimitFailure() => l10n.aiErrorRateLimited,
      NetworkFailure() => l10n.aiErrorOffline,
      TimeoutFailure() => l10n.aiErrorTimeout,
      // The failure's own `message` is diagnostic English; what the user
      // reads is chosen here, by field, so a pt-BR device never sees it
      // (BR-11).
      ValidationFailure(:final String? field) => switch (field) {
        'transcript' => l10n.newMeetingTranscriptRequired,
        'title' => l10n.newMeetingTitleRequired,
        _ => l10n.aiErrorGeneric,
      },
      AlreadyConvertedFailure() => l10n.summaryAlreadyConverted,
      StorageFailure() => l10n.aiErrorStorage,
      // Sprint 04. `MissingApiKeyFailure` and `AuthFailure` above already
      // cover both providers' key problems — the message names Settings, and
      // Settings is where both keys live, so one string serves both without
      // lying about either.
      TranscriptionFailure() => l10n.transcriptionErrorFailed,
      RecordingFailure() => l10n.recordingErrorFailed,
      _ => l10n.aiErrorGeneric,
    };

/// The name of the stage a recording-to-summary run is in.
///
/// Four names rather than one spinner: they take wildly different amounts of
/// time and fail for different reasons, and a user watching a ninety-minute
/// meeting upload deserves to know it is the upload they are waiting on.
String transcriptionStageLabel(
  AppLocalizations l10n,
  TranscriptionStage stage,
) => switch (stage) {
  TranscriptionStage.uploading => l10n.recordMeetingStageUploading,
  TranscriptionStage.transcribing => l10n.recordMeetingStageTranscribing,
  TranscriptionStage.summarizing => l10n.recordMeetingStageSummarizing,
  TranscriptionStage.done => l10n.recordMeetingStageSummarizing,
};
