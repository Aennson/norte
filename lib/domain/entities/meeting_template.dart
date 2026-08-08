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

  const MeetingTemplate._();

  /// The section headings, in the order the summary must produce them.
  List<String> get sectionTitles => <String>[
    for (final TemplateSection section in sections) section.title,
  ];
}

/// The four templates every install starts with (`docs/architecture.md` §5.3).
///
/// Seeded into Drift by `MeetingTemplateRepository.seedDefaults`, after which
/// they are ordinary editable rows — the ids are stable so a re-seed can tell
/// "already present" from "the user made a new one" (S03-IT-02).
///
/// **These are in English and are not ARB resources.** BR-11 governs the app's
/// own interface, every string of which is localized. A template is user data:
/// its prompt is sent to a model and its section titles become the keys of the
/// stored summary, so translating them at render time would either rewrite the
/// user's edits or make a saved summary unreadable after a locale change. The
/// user edits them into whatever language they run their meetings in, which is
/// the only answer that stays true for a bilingual team.
const List<MeetingTemplate> defaultMeetingTemplates = <MeetingTemplate>[
  MeetingTemplate(
    id: 'builtin.daily',
    type: MeetingType.daily,
    systemPrompt:
        'You are summarizing a software team daily stand-up. Be terse: a '
        'stand-up summary that is longer than the stand-up has failed. Record '
        'what each person reported under the matching section, keep names as '
        'the transcript gives them, and never invent progress that was not '
        'stated. Blockers are the section that matters — if someone is stuck, '
        'say who and on what.',
    sections: <TemplateSection>[
      TemplateSection(
        title: 'Done since yesterday',
        guidance: 'Completed work, one line per person.',
      ),
      TemplateSection(
        title: 'Planned for today',
        guidance: 'Stated intentions, not inferred ones.',
      ),
      TemplateSection(
        title: 'Blockers',
        guidance: 'Who is blocked, on what, and who can unblock them.',
      ),
    ],
  ),
  MeetingTemplate(
    id: 'builtin.retro',
    type: MeetingType.retro,
    systemPrompt:
        'You are an agile facilitator summarizing a retrospective. Group the '
        'discussion into the sections below, preserving disagreement rather '
        'than smoothing it — a retro where everyone agreed is usually a retro '
        'nobody spoke at. Attribute nothing to a person unless the transcript '
        'does. Every improvement the team committed to belongs in the action '
        'items, with the owner if one was named.',
    sections: <TemplateSection>[
      TemplateSection(
        title: 'What went well',
        guidance: 'Practices worth keeping, with the evidence given for them.',
      ),
      TemplateSection(
        title: 'What to improve',
        guidance: 'Problems raised, including ones left unresolved.',
      ),
      TemplateSection(
        title: 'Action items',
        guidance: 'Concrete commitments, each with an owner where stated.',
      ),
    ],
  ),
  MeetingTemplate(
    id: 'builtin.planning',
    type: MeetingType.planning,
    systemPrompt:
        'You are summarizing a sprint planning session. Capture what was '
        'committed to and — just as important — what was explicitly deferred '
        'and why, because that is the part nobody remembers a week later. '
        'Record estimates and open questions as they were said; do not resolve '
        'an open question yourself.',
    sections: <TemplateSection>[
      TemplateSection(
        title: 'Scope agreed',
        guidance: 'Items taken into the sprint, with estimates if given.',
      ),
      TemplateSection(
        title: 'Deferred',
        guidance: 'What was left out, and the reason stated for leaving it.',
      ),
      TemplateSection(
        title: 'Risks and open questions',
        guidance: 'Unresolved dependencies and unanswered questions.',
      ),
      TemplateSection(
        title: 'Action items',
        guidance: 'Follow-ups needed before or during the sprint.',
      ),
    ],
  ),
  MeetingTemplate(
    id: 'builtin.oneOnOne',
    type: MeetingType.oneOnOne,
    systemPrompt:
        'You are summarizing a one-to-one between a developer and their '
        'manager. This is the most sensitive transcript this app handles: '
        'summarize only what was said, keep the wording neutral, and do not '
        'characterize anyone. Omit personal matters that are not follow-ups. '
        'If the conversation was mostly personal, it is correct for the '
        'sections to be nearly empty.',
    sections: <TemplateSection>[
      TemplateSection(
        title: 'Topics discussed',
        guidance: 'Subjects raised, neutrally stated.',
      ),
      TemplateSection(
        title: 'Feedback',
        guidance: 'Feedback given in either direction, as it was phrased.',
      ),
      TemplateSection(
        title: 'Action items',
        guidance: 'Commitments made by either person.',
      ),
    ],
  ),
];
