import 'dart:io';

import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';

/// Raw model answers, loaded from `test/fixtures/summaries/`.
///
/// Files rather than string literals so the fixtures read like what a model
/// actually returns — fences, prose, and all — and so a change to one is
/// visible in a diff rather than buried in a test.
String summaryFixture(String name) =>
    File('test/fixtures/summaries/$name').readAsStringSync();

/// The retro template, as the seed writes it.
MeetingTemplate get retroTemplate => defaultMeetingTemplates.firstWhere(
  (MeetingTemplate template) => template.type == MeetingType.retro,
);

/// The daily template, as the seed writes it.
MeetingTemplate get dailyTemplate => defaultMeetingTemplates.firstWhere(
  (MeetingTemplate template) => template.type == MeetingType.daily,
);

/// A retro transcript with no personal data in it — the ordinary case, used
/// wherever a test is about something other than redaction.
const String retroTranscript = '''
Ana: the outbox went out on Tuesday and nothing broke. Pairing on the
dispatcher is why the retry logic was right first time.
Bruno: agreed. My complaint is review latency — PR 41 sat for three days.
Ana: that is a staffing problem, not a notification problem.
Bruno: I do not think we agree on that. Leaving it open.
Ana: I will update the runbook.
Bruno: I will set up a review reminder in Slack before the fifteenth.
''';

/// A transcript carrying every pattern BR-07 names, plus the near-misses that
/// must survive: dates, issue keys and version numbers.
///
/// **Every value here is synthetic** (`docs/testing-strategy.md` §3): the CPFs
/// are format-valid and belong to nobody, the numbers are in the reserved
/// documentation style, and the addresses are `example.com`.
const String transcriptWithPii = '''
Ana: my CPF is 123.456.789-09 and Bruno's is 12345678909.
Bruno: call me on +55 11 98765-4321, or the office on (11) 3555-0100.
Ana: my mobile without punctuation is 11987654321.
Bruno: mail me at bruno@example.com or bruno.silva+jira@sub.example.org.
Ana: PROJ-123 is blocked until 2026-08-08, and we are on version 1.2.3.
Bruno: the release on 08/08/2026 also covers NORTE-4567.
''';
