# Sprint 03 — Meetings: Pasted Transcript, Templates, AI Summary, and ActionItems→Tasks · Report

**Branch:** `claude/next-phase-273c71` (see DEC-015) · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Pro 26200 (Developer's machine) · **CI:** `ubuntu-latest`

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 02 DoD complete | Closed 2026-08-08. Every box accounted for; the one that could not be executed — the manual pass against a real Jira — is recorded as *not performed* and carried into S09-MT-01 by **DEC-014**, because a Zscaler gateway makes it impossible on the Developer's network. `docs/reports/sprint-02-report.md` §6–7 | ✅ |
| `FakeAiEngine` with summary fixtures (`test/fixtures/summaries/`) | The fake existed from Sprint 00 but against the *provisional* port; the fixtures did not exist at all. Both were completed as the first act of this sprint: `test/fakes/fake_ai_engine.dart` now implements the real `AiEngine`, and `test/fixtures/summaries/` holds five raw model answers (retro, daily, malformed prose, wrong-sections, fenced) | ✅ |

## 2. Quality gates

Every command run at `HEAD` of the sprint branch, on the Developer's Windows machine.

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 5.2s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --output=none --set-exit-if-changed .` | `Formatted 171 files (0 changed)`, exit 0 ✅ |
| G3 — tests | `flutter test` | `00:28 +419: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **96.1%** (343/357) · project **85.2%** (2670/3134) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match ✅ |
| E2E | `flutter test integration_test/<suite> -d windows`, one per file (DEC-010) | 6 suites, 18 scenarios, all passing ✅ |

Coverage excludes machine-generated sources (DEC-008).

**No real credential is anywhere in the tree.** No Claude API key was used at any
point in development: every test drives either `FakeAiEngine` or a loopback
`FakeClaudeServer`, and the only key string in the repository is the synthetic
`'synthetic-key'`. The BYOK key lives in the platform secure store and is never
read back into the UI (BR-08).

## 3. Documented tests

| ID | Behaviour | Cases | Result |
|---|---|---|---|
| S03-UT-01 | PII redaction, and the false positives that must survive — BR-07 | 9 | ✅ |
| S03-UT-02 | Redaction runs before the engine, and only when it must | (in 19) | ✅ |
| S03-UT-03 | The template structures the prompt; the transcript stays out of it | (in 19) | ✅ |
| S03-UT-04 | Ephemeral retention, along the whole path to a stored row — BR-03 | 9 | ✅ |
| S03-UT-05 | ActionItem → Task, once and once only | 15 | ✅ |
| S03-UT-06 | One retry, then a refusal — never a silent partial summary | (in 19) | ✅ |
| S03-IT-01 | The Messages API request, its cached prefix, and its event stream | 16 | ✅ |
| S03-IT-02 | Seeding the four defaults, against a real in-memory database | 13 | ✅ |
| S03-CT-01 | The `AiEngine` contract, 13 cases × 2 subjects | 13 declared → **26 executed** | ✅ |
| S03-GT-01 | The meeting screens, four states, dark + light | 14 (14 goldens) | ✅ |
| S03-E2E-01 | Paste → summarize → convert → save, and what BR-03 left behind | 3 | ✅ |
| S03-E2E-02 | The failure UX, and the retry that recovers it | 4 | ✅ |

Sprint-03 files contribute **121 unit/contract/golden cases** and **7 E2E
scenarios**. The suite total rose from 293 to **419**, 0 skipped, 0 weakened.

### Notes on specific exit criteria

- **S03-UT-01** — the sprint asks for two CPFs, three phone numbers, two
  e-mails and nearby false positives. All are present in one fixture, and the
  false-positive assertions are positive (`PROJ-123` *is* still there) rather
  than merely "no crash". One genuine ambiguity is asserted rather than hidden:
  eleven bare digits are a CPF or a mobile number, Brazil gives them the same
  length, and the mandatory `9` after the area code is the only discriminator.
  A CPF whose third digit is `9` is labelled `[PHONE]`. That is a wrong label on
  removed data, never a leak, and the test says so.
- **S03-UT-06** — scenario A is asserted as *exactly* two calls, and scenario B
  as exactly two and then a stop. A third attempt would spend the user's money
  on a model that has already demonstrated it will not comply. A failure a retry
  cannot fix — a rejected key, a missing key — is not retried at all, which the
  same group asserts.
- **S03-CT-01** — two subjects, and the fake is not a mock of the parser: it
  runs the production `MeetingSummaryCodec`. Without that, the fake could be
  quietly more forgiving than the adapter and every widget and E2E test above it
  would be testing something the app does not do. One case asserts exactly this
  property. `CopilotCliEngine` joins as a third subject in Sprint 07.
- **S03-IT-01** — driven through a real loopback socket, so the suite exercises
  the URL, the headers, the `cache_control` placement and the SSE reader rather
  than a mock's opinion of them. Two cases matter most: the cached prefix is
  byte-identical across two different meetings, and an `error` event arriving
  mid-stream after a `200` is a failure rather than a short summary.
- **S03-IT-02** — insert-if-absent delivers all three documented exit criteria
  at once, and a fourth case covers the case the sprint implies but does not
  name: a default the user *deleted* comes back, which is what "restore the
  built-in templates" has to mean.
- **S03-E2E-01** — the BR-03 assertion is made against the database, not the
  screen: the saved meeting has an empty `rawTranscript`. Its counterpart
  asserts that opting in keeps the text, so the toggle is shown to be a real
  choice rather than a decoration.
- **S03-E2E-02** — the assertion the scenario exists for is not that an error
  appears; it is that `transcript.controller!.text` still equals what was
  pasted.

## 4. Sprint validation rules

| Rule | How it is met |
|---|---|
| **BR-03** — ephemeral by default; leaving discards | Enforced in **one place**, `Meeting.forStorage`, which every write path passes through. `SummarizeMeeting` holds no repository at all, so a summary cannot be persisted as a side effect of producing one; `SaveMeeting` is the only writer and applies the gate. Leaving the result screen calls `MeetingComposer.reset()`. The choice is offered *before* processing, because afterwards the user is deciding whether to keep evidence rather than whether to keep notes. |
| **BR-07** — redact before any external API | In `SummarizeMeeting`, not in an adapter. One implementation therefore covers every engine written later, including `CopilotCliEngine`, whose `isLocal == true` is the single condition that relaxes it. |
| A template is data, not code | `systemPrompt` is the system message, the transcript is the user message, and the template's sections key the returned summary. The four defaults are seeded rows the user can edit or delete; the editor exposes the prompt and the headings, which is what actually shapes a summary. |
| No API key → `MissingApiKeyFailure` pointing at Settings | A distinct failure class, not `AuthFailure`: a key that is absent and a key that is rejected send the user to Settings for different reasons, and the UI says which. |
| Malformed response → 1 retry → `AiResponseFailure` with a retry option | `SummarizeMeeting.maxAttempts == 2`. The screen renders the failure in place with the transcript intact and a **Try again** button. A response that is valid JSON but matches none of the template's headings is refused too — that is the silent partial summary the rule is really about. |
| Conversion: title, `meeting` tag, meeting reference if saved, marked as converted, individual | All asserted in S03-UT-05 and again through the UI in S03-E2E-01. The reference is set only when the meeting is actually in storage, checked rather than assumed, so a task never points at a meeting that was discarded. A converted item keeps its row and loses its button — the record stays visible and there is no control left to make a duplicate with. |

## 5. Deviations

Two decisions were recorded in `docs/reports/decisions.md`.

| ID | Summary |
|---|---|
| DEC-014 | The Sprint 02 manual Jira pass is discharged into S09-MT-01. Recorded during sprint-02 closure, immediately before this sprint opened. |
| DEC-015 | Sprint developed on the environment-pinned branch, as in DEC-003, DEC-009 and DEC-013. |

**Nothing was left undone and nothing from a future sprint was implemented.**
No documented criterion was weakened.

Three smaller choices are recorded here rather than as decisions, because none
changes a documented rule:

- **`AiEngine.complete(AiRequest)`** from `architecture.md` §7.1 is not
  implemented. Nothing in Sprint 03 calls it, and an unused method with no test
  is dead code that would sit in the coverage figure pretending to be work.
  `parseIntent` keeps its provisional `String` return until Sprint 05 promotes
  it to `VoiceIntent`, which is the plan the provisional port itself records.
- **`ActionItem` moved from `Meeting` to `MeetingSummary`.** The port returns a
  `MeetingSummary`, and the items *are* output of summarization; holding them in
  two places would let the extracted list and the conversion state disagree.
  `Meeting.actionItems` remains as a read-through getter, so `architecture.md`
  §3.1's accessor still reads true.
- **Template prompts and section headings are English, not ARB resources.**
  BR-11 governs the app's interface, and every string of it is localized in all
  three languages. A template is *user data*: its prompt goes to a model and its
  headings become the keys of a stored summary, so translating them at render
  time would either rewrite the user's edits or make a saved summary unreadable
  after a locale change. The user edits them into whatever language their team
  runs meetings in — the only answer that stays true for a bilingual team.

### Three defects found and fixed during the sprint

**The summary screen said "Action items" twice.** The retro template has a
section by that name, and the convertible list had the same heading, so the
result screen showed two identical `title`-styled headings a few hundred pixels
apart. Found by S03-E2E-01, whose `findsOneWidget` turned up two candidates.
Two identical headings on one screen read as a rendering bug rather than as
structure, so the list is now **Follow-ups** — `Encaminhamentos` in pt-BR,
`Follow-up` in it. The template section keeps its own name, because that name is
the user's.

**`NorteScreen` had no way back.** Sprints 00–02 never pushed a route — the four
destinations are tabs — so nobody had needed one. Sprint 03 pushes two screens,
and on desktop the composer was a dead end: no system back gesture, no chrome,
no control. Found by S03-E2E-01, where `tester.pageBack()` could not find a
back button because there was none to find. `NorteScreen` now takes an optional
`onBack`; it is `null` for the four tab destinations, and **every pre-existing
golden regenerated byte-identical**, which is the evidence that nothing else
moved.

**A new failure type would have been retried forever.** `OutboxDispatcher`
classifies every `Failure` as retryable or not through an exhaustive `switch`.
Adding three AI failures to the domain broke that switch at compile time —
which is exactly what it is for. None of them can reach the Jira queue, but they
are listed explicitly rather than swept up by a wildcard, so the next failure
added to the domain still has to be classified rather than silently defaulting
to "retry forever".

## 6. Goldens

14 new goldens (7 states × 2 themes). The Windows set is committed; the Linux
set — the one CI compares against — must be produced on the CI runner image by
the `Generate Linux goldens` workflow and committed from its artifact, exactly
as DEC-011 prescribes and as was done in Sprint 01. A set generated anywhere
else, including a local WSL distribution, will not match.

> ⏳ **Pending.** Until the Linux artifact is committed, the `test` job fails on
> the 14 missing files. This is a procedural step, not a defect, and the sprint
> does not close until it is done.

## 7. Manual test against the real Claude API

The Definition of Done requires one summary produced with the Developer's own
key — the one thing no fake can stand in for, because it is the real model's
output being tested against the real parser, not ours against ours.

**Script**, in the format of `docs/testing-strategy.md` §7:

- **Entry:** the built app; a Claude API key the Developer holds. **The key is
  typed into the app by the Developer and is never committed.**
- **Action:**
  1. Settings → Claude → paste the key → **Save**. Expect *Key configured*.
  2. Meetings → **New meeting** → choose **Retro** → paste a real transcript
     (any meeting; a genuine one is the point) → leave *Save the transcript too*
     **off** → **Summarize**.
  3. Read the result. Convert one action item.
  4. **Save summary**, go back, and open the saved meeting.
  5. Open the Tasks tab.
- **Exit:** the retro's three sections are present and describe the meeting that
  was actually pasted; the action item became a task tagged `meeting`; the saved
  meeting shows *Transcript discarded*; the task list contains the follow-up.
  No key appears in any log.

### Result

**Executed by the Developer on 2026-08-08 against the real Claude API, and
reported as passing.** The pipeline works end to end with a real key and a real
transcript: the summary came back in the template's sections, the conversion
produced a task, and the saved meeting kept its summary.

This is the Developer's own attestation, not something the executing AI
observed — which is the nature of the box. No key was shared with the AI, none
reached this repository, and none appears in any commit.

What the automated suite could not have caught, and this pass therefore covers:
that the real model, given the real system prompt, returns an answer the real
codec can read. Every automated case proves the parser against fixtures; only
this one proves the fixtures resemble the model.

## 8. Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90% — §2, **96.1%**
- [x] All S03-* tests passing — §3, 419 tests and 18 E2E scenarios
- [x] Manual test with the real Claude API — §7, executed by the Developer on
      2026-08-08 and reported as passing; key not committed
- [x] Report `docs/reports/sprint-03-report.md` — this document
- [ ] Linux golden set committed from the workflow artifact — §6
- [ ] GitHub Actions 100% green on the sprint PR

**Three boxes remain.** Two are procedural (the Linux goldens, and the CI run
that depends on them); one needs a human, a key, and a real meeting. The sprint
is not closed until all three are recorded here.
