# Sprint 03 — Meetings: Pasted Transcript, Templates, AI Summary, and ActionItems→Tasks

**Objective:** complete meeting summarization pipeline from a transcript **pasted** by the user: configurable templates, PII redaction, `ClaudeApiEngine.summarize`, summary review, and one-tap conversion of action items into tasks.

**Mandatory references:** `docs/architecture.md` §5, §7.1–7.2 (ClaudeApiEngine) · BR-03, BR-07, BR-08

---

## Entry criteria

- [ ] Sprint 02 DoD complete.
- [ ] `FakeAiEngine` with summary fixtures (`test/fixtures/summaries/`).

## Scope

**In:** complete `AiEngine` port (interface from `architecture.md §7.1`); `ClaudeApiEngine` (dio, `POST /v1/messages`, system prompt with prompt caching, streaming for summaries, BYOK — key in secure storage + field in Settings); `PiiRedactor` (BR regex: CPF, phone, e-mail); `MeetingSummary`, `ActionItem`, `TemplateSection` entities; templates in Drift with the 4 embedded defaults (daily, retro, planning, 1:1) + template CRUD in Settings; `SummarizeMeeting` use case; `ConvertActionItemToTask` use case; screens: new meeting (paste text, choose type, "save transcript" toggle), summary result by sections, saved meetings list.

**Out:** audio recording/Whisper (Sprint 04), `CopilotCliEngine` (Sprint 07).

## Sprint validation rules

- **BR-03:** default `retention = ephemeral` — the transcript never touches Drift unless the user enables "save transcript" before processing; leaving the result screen discards the ephemeral transcript (only a saved summary remains, if the user saved it).
- **BR-07:** `SummarizeMeeting` applies the `PiiRedactor` **before** calling the `AiEngine` whenever `capabilities.isLocal == false`.
- A template is data, not code: the `systemPrompt` is sent as the system message; the transcript as the user message; the template's sections must structure the output.
- `ClaudeApiEngine` without a configured API key → `MissingApiKeyFailure` with a message pointing to Settings (never a crash).
- A malformed AI response (invalid summary JSON) → 1 retry; if it persists, `AiResponseFailure` with a retry option — never a silent partial summary.
- Each converted `ActionItem` creates a task with the item's title, the `meeting` tag, and a reference to the meeting id (if saved); conversion is individual and visually marked as "already converted".

## Tests

#### S03-UT-01 — PII redaction (BR patterns)
- **What it validates:** BR-07 (regex).
- **Entry criteria:** `PiiRedactor`; fixture text with 2 CPFs (masked and unmasked), 3 phone numbers (`+55`, `(11) 9...`, `11987654321`), 2 e-mails, and nearby false positives (dates, issue keys `PROJ-123`, versions `1.2.3`).
- **Action:** redact.
- **Exit criteria:** all PII replaced with `[CPF]`/`[PHONE]`/`[EMAIL]`; false positives intact; remaining text unchanged.

#### S03-UT-02 — Redaction applied before the AI
- **What it validates:** BR-07 (integration in the use case).
- **Entry criteria:** `SummarizeMeeting` with a spy `FakeAiEngine` (`isLocal == false`); transcript containing a CPF.
- **Action:** execute.
- **Exit criteria:** the text received by the engine does not contain the CPF (contains `[CPF]`); with an `isLocal == true` engine, the text arrives untouched.

#### S03-UT-03 — Template structures the prompt
- **What it validates:** §5.3 (template as data).
- **Entry criteria:** retro template with 3 sections; spy `FakeAiEngine`.
- **Action:** `SummarizeMeeting` with that template.
- **Exit criteria:** system prompt sent == the template's `systemPrompt`; user message == the redacted transcript; the action-item extraction flag is respected.

#### S03-UT-04 — Ephemeral retention
- **What it validates:** BR-03.
- **Entry criteria:** meeting with `retention = ephemeral`; spy meetings repository.
- **Action:** summarize and save the summary.
- **Exit criteria:** the persisted object has an empty/null `rawTranscript`; with `retention = persisted`, the transcript is persisted.

#### S03-UT-05 — ActionItem → Task
- **What it validates:** one-tap conversion.
- **Entry criteria:** summary with action item "Update the runbook".
- **Action:** `ConvertActionItemToTask`.
- **Exit criteria:** task created with title "Update the runbook", status `todo`, tag `meeting`; item marked as converted; converting the same item again is rejected (`AlreadyConvertedFailure`).

#### S03-UT-06 — Malformed AI response
- **What it validates:** the retry/error policy.
- **Entry criteria:** `FakeAiEngine` programmed: 1st response invalid, 2nd valid (scenario A); both invalid (scenario B).
- **Action:** `SummarizeMeeting`.
- **Exit criteria:** A → valid summary with exactly 2 calls; B → `AiResponseFailure` after 2 calls, no summary persisted.

#### S03-IT-01 — ClaudeApiEngine: request and caching
- **What it validates:** conformance with the Messages API + prompt caching (§7.2).
- **Entry criteria:** fake HTTP server capturing the request; fake key in fake secure storage.
- **Action:** `summarize()`.
- **Exit criteria:** POST `/v1/messages` with auth and version headers; system prompt marked with `cache_control`; transcript in the user message; the fake's response parsed into a correct `MeetingSummary`.

#### S03-IT-02 — Embedded default templates
- **What it validates:** seeding of the 4 templates.
- **Entry criteria:** freshly created in-memory database.
- **Action:** initialize the templates repository.
- **Exit criteria:** daily, retro, planning, and 1:1 present with sections per §5.3; re-initializing does not duplicate; a user-edited template is not overwritten by the seed.

#### S03-CT-01 — AiEngine contract (summarize)
- **What it validates:** `ClaudeApiEngine` (fake server) and `FakeAiEngine` return the same shape.
- **Entry criteria:** contract suite with a fixed transcript and template.
- **Action:** `summarize()` on each adapter.
- **Exit criteria:** both return a `MeetingSummary` with the template's sections and a (possibly empty) list of action items; errors mapped to the same `Failure`s.

#### S03-GT-01 — Meeting screens
- **What it validates:** new-meeting and result screens in the 4 states (design system §6).
- **Entry criteria:** providers overridden per state.
- **Action:** render dark/light.
- **Exit criteria:** stable goldens; summary sections in `NorteCard`; action items with a conversion button; transcript displayed in the `mono` font.

#### S03-E2E-01 — Paste → summarize → convert
- **What it validates:** the complete Pillar 2 pipeline.
- **Entry criteria:** app with `FakeAiEngine` (retro fixture with 2 action items); retro transcript in a fixture.
- **Action:** new meeting → paste transcript → retro type → process → review sections → convert 1 action item → save summary → go back and open the Tasks tab.
- **Exit criteria:** the retro's 3 sections appear; the action item's task exists in the tasks list with the `meeting` tag; the saved meeting appears in the meetings list **without** a persisted transcript (verified in the database — BR-03).

#### S03-E2E-02 — AI failure with recovery
- **What it validates:** the pipeline's error UX.
- **Entry criteria:** `FakeAiEngine` programmed to fail twice and then work.
- **Action:** process → see the error → tap "Try again".
- **Exit criteria:** error screen with retry (no crash, pasted transcript preserved in the field); the retry produces the summary.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [ ] All S03-* tests passing.
- [ ] Manual test with the real Claude API (1 summary with your own key) recorded in the report; key not committed.
- [ ] Report `docs/reports/sprint-03-report.md`.
