import 'package:freezed_annotation/freezed_annotation.dart';

import 'meeting.dart';

part 'meeting_template.freezed.dart';

/// One heading the summary must produce, e.g. "What went well"
/// (`docs/architecture.md` §5.3).
@freezed
abstract class TemplateSection with _$TemplateSection {
  const factory TemplateSection({
    /// Section heading, shown to the user and sent to the engine.
    required String title,

    /// Optional extra instruction for this section only.
    String? guidance,
  }) = _TemplateSection;
}

/// Instructions that drive `AiEngine.summarize`.
///
/// Templates are **data, not code** (`docs/architecture.md` §5.3): they live in
/// Drift and the user edits them. [systemPrompt] is sent as the system message,
/// which is what makes prompt caching possible in the Claude adapter.
@freezed
abstract class MeetingTemplate with _$MeetingTemplate {
  const factory MeetingTemplate({
    required String id,
    required MeetingType type,

    /// System prompt handed to the engine. Fixed payload — never carries the
    /// transcript.
    required String systemPrompt,
    @Default(<TemplateSection>[]) List<TemplateSection> sections,

    /// Whether the engine should also return `ActionItem`s.
    @Default(true) bool extractActionItems,
  }) = _MeetingTemplate;
}
