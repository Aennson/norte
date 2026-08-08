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

/// One follow-up extracted from a meeting, convertible into a `Task` with a
/// single tap.
///
/// [id] exists so conversion state has something to attach to: the item
/// remembers the task it produced, which is what makes a second conversion
/// refusable rather than a silent duplicate (S03-UT-05).
@freezed
abstract class ActionItem with _$ActionItem {
  const factory ActionItem({
    /// Stable within the summary that produced it.
    required String id,

    /// What has to be done. Becomes the task's title on conversion.
    required String description,

    /// Person the item was assigned to, when the transcript names one.
    String? assignee,
    DateTime? dueDate,

    /// Id of the task this item became, or `null` while it is unconverted.
    String? convertedTaskId,
  }) = _ActionItem;

  const ActionItem._();

  /// `true` once this item has produced a task — what the UI marks as
  /// "already converted" and what `ConvertActionItemToTask` refuses.
  bool get isConverted => convertedTaskId != null;
}

/// The AI-produced summary of a meeting.
///
/// The only part of a meeting that may be persisted when
/// [RetentionPolicy.ephemeral] is in force (BR-03).
///
/// [actionItems] lives here rather than on [Meeting] because the items *are*
/// output of the summarization: keeping one copy means the extracted list and
/// the conversion state can never disagree with each other. [Meeting.actionItems]
/// reads through to it.
@freezed
abstract class MeetingSummary with _$MeetingSummary {
  const factory MeetingSummary({
    /// Section title → section body, in the template's declared order.
    required Map<String, String> sections,

    /// When the summary was produced.
    required DateTime generatedAt,

    /// Follow-ups the engine extracted. Empty when the template has
    /// `extractActionItems == false`, or when the meeting produced none.
    @Default(<ActionItem>[]) List<ActionItem> actionItems,

    /// Identifier of the engine that produced it, for diagnostics.
    String? engineId,
  }) = _MeetingSummary;

  const MeetingSummary._();

  /// The item with [id], or `null` when this summary has none.
  ActionItem? itemById(String id) {
    for (final ActionItem item in actionItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// This summary with [item] replacing the one that shares its id.
  ///
  /// Returns an identical summary when no item matches, so a caller acting on
  /// a stale id cannot append a phantom follow-up.
  MeetingSummary withItem(ActionItem item) => copyWith(
    actionItems: <ActionItem>[
      for (final ActionItem existing in actionItems)
        if (existing.id == item.id) item else existing,
    ],
  );
}

/// A captured meeting: its transcript, its summary, and the follow-ups.
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
    @Default(RetentionPolicy.ephemeral) RetentionPolicy retention,
  }) = _Meeting;

  const Meeting._();

  /// The follow-ups extracted from this meeting, or empty before it has been
  /// summarized (`docs/architecture.md` §3.1).
  List<ActionItem> get actionItems =>
      summary?.actionItems ?? const <ActionItem>[];

  /// This meeting in the form BR-03 allows on disk.
  ///
  /// The whole of BR-03 in one place: an ephemeral meeting persists without
  /// its transcript, and a persisted one keeps it because the user asked for
  /// that **before** the text was processed. Every write path goes through
  /// here, so there is no route to storage that could forget (S03-UT-04).
  Meeting get forStorage =>
      retention.allowsPersistence ? this : copyWith(rawTranscript: '');
}
