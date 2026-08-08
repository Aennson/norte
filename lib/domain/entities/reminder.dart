import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder.freezed.dart';

/// A short, voice-captured reminder scheduled as a local notification
/// (`docs/architecture.md` §8).
@freezed
abstract class Reminder with _$Reminder {
  const factory Reminder({
    required String id,

    /// Transcribed text. The audio it came from is discarded immediately after
    /// the transcription is confirmed (BR-06) — no field here ever holds it.
    required String text,

    /// When the notification should fire.
    required DateTime triggerAt,
    required DateTime createdAt,

    /// `true` once the notification has been delivered.
    @Default(false) bool isFired,

    /// Transient handle to the capture that produced [text]
    /// (`docs/architecture.md` §3.1). It is cleared as soon as the
    /// transcription is confirmed and **must never be persisted** (BR-06) —
    /// the Sprint 06 repository drops this field on write.
    String? sourceAudioNote,
  }) = _Reminder;
}
