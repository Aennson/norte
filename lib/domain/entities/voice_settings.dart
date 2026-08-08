import 'package:freezed_annotation/freezed_annotation.dart';

part 'voice_settings.freezed.dart';

/// The user's choices about how voice commands behave
/// (`docs/architecture.md` §6.2).
@freezed
abstract class VoiceSettings with _$VoiceSettings {
  const factory VoiceSettings({
    /// Ask before every Jira write, however confident the parse was.
    ///
    /// **On by default, and the default is the point.** BR-04 already stops a
    /// low-confidence mutation; this covers the confident-and-wrong one. A
    /// mistaken local task is a row the user deletes in a second — a mistaken
    /// transition is a change their whole team saw, and there is no undo for
    /// the notification everyone already received. The user may turn it off;
    /// they may not have it off without knowing.
    @Default(true) bool alwaysConfirmJiraWrites,
  }) = _VoiceSettings;
}
