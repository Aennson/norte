import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting.freezed.dart';

/// Kind of meeting, which selects the `MeetingTemplate` used to summarize it
/// (`docs/architecture.md` §3.1).
enum MeetingType { daily, retro, planning, oneOnOne, custom }

/// What happens to [Meeting.rawTranscript] when the user leaves the screen.
///
/// **BR-03** — [ephemeral] is the default and lives only in memory: the
/// transcript is discarded on exit and only an explicitly saved
/// [MeetingSummary] survives.
enum RetentionPolicy {
  /// Memory only; never written to Drift.
  ephemeral,

  /// The user explicitly opted in to keeping the transcript.
  persisted;

  /// `true` when the transcript may touch disk.
  bool get allowsPersistence => this == RetentionPolicy.persisted;
}

/// One follow-up extracted from a meeting, convertible into a [Task] with a
/// single tap.
@freezed
abstract class ActionItem with _$ActionItem {
  const factory ActionItem({
    required String description,

    /// Person the item was assigned to, when the transcript names one.
    String? assignee,
    DateTime? dueDate,
  }) = _ActionItem;
}

/// The AI-produced summary of a meeting.
///
/// The only part of a meeting that may be persisted when
/// [RetentionPolicy.ephemeral] is in force (BR-03).
@freezed
abstract class MeetingSummary with _$MeetingSummary {
  const factory MeetingSummary({
    /// Section title → section body, in the template's declared order.
    required Map<String, String> sections,

    /// When the summary was produced.
    required DateTime generatedAt,

    /// Identifier of the engine that produced it, for diagnostics.
    String? engineId,
  }) = _MeetingSummary;
}

/// A captured meeting: its transcript, its summary, and the follow-ups.
///
/// Declared here in full even though Sprint 01 does not use it — the domain
/// model lands as one piece (`sprint-01` scope).
@freezed
abstract class Meeting with _$Meeting {
  const factory Meeting({
    required String id,
    required String title,
    required DateTime createdAt,
    @Default(MeetingType.custom) MeetingType type,

    /// Pasted by the user or produced by a transcription engine. Held in
    /// memory only while [retention] is [RetentionPolicy.ephemeral] (BR-03).
    @Default('') String rawTranscript,
    MeetingSummary? summary,
    @Default(<ActionItem>[]) List<ActionItem> actionItems,
    @Default(RetentionPolicy.ephemeral) RetentionPolicy retention,
  }) = _Meeting;
}
