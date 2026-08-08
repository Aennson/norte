# Sprint 04 — Whisper Batch: Audio Recording and Meeting Transcription · Report

**Branch:** `claude/sprint-verification-04e4a6` (see DEC-023) · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Pro 26200 (Developer's machine) · **CI:** `ubuntu-latest`

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 03 DoD complete | Closed 2026-08-08; PR #5 merged into `master` at `48281f3` with all three CI jobs green. Verified independently at the start of this sprint by re-running every gate at that commit: analyze clean, 419 tests, coverage 95.2% / 85.2%, imports OK | ✅ |
| `FakeBatchTranscription` available | Written in Sprint 00 against the provisional port; promoted to the real one as the first act of this sprint, and now a **subject** of S04-CT-01 rather than merely a convenience | ✅ |

### Five open items settled before the sprint opened

An audit of Sprints 00–03 found five pendencies carried in prose rather than in
the decision log, two of which left `architecture.md` describing code that does
not exist. They were closed in a separate `docs:` commit **before** any Sprint 04
code was written, because a sprint that begins by reading a false architecture
document is building on sand.

| ID | What it settled |
|---|---|
| DEC-016 | The Sprint 02 manual Jira pass **was executed** and reported as passing. It supersedes DEC-014, which had discharged the box into S09-MT-01 — a v1.1 sprint, so the debt could not otherwise have been settled until after the release it belonged to. Sprint 09 no longer inherits another sprint's obligation |
| DEC-017 | `AiEngine.complete(AiRequest)` is not implemented and `parseIntent` keeps its `String` return until Sprint 05. `architecture.md` §7.1 amended |
| DEC-018 | `ActionItem` lives on `MeetingSummary`, with a read-through getter on `Meeting`. `architecture.md` §3.1 amended |
| DEC-019 | Template prompts and section headings are user data, outside BR-11's scope |
| DEC-020 | **"Available platform" means Windows and Android** for every v1.0 manual script. iOS remains a declared but unverified target, together with the missing `macos/` golden set, until a macOS host exists |

DEC-020 is what makes this sprint's manual box answerable at all: §7 asks for a
recording "on each available platform", and without that decision the phrase had
no agreed meaning.

## 2. Quality gates

Every command run at `HEAD` of the sprint branch, on the Developer's Windows machine.

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 7.3s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --output=none --set-exit-if-changed .` | `Formatted 194 files (0 changed)`, exit 0 ✅ |
| G3 — tests | `flutter test` | `00:43 +491: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **94.5%** (378/400) · project **83.1%** (3016/3630) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match ✅ |
| E2E | `flutter test integration_test/<suite> -d windows`, one per file (DEC-010) | 8 suites, 26 scenarios, all passing ✅ |

Coverage excludes machine-generated sources (DEC-008).

**No real credential is anywhere in the tree.** No Whisper key and no Claude key
was used at any point in development: every test drives either
`FakeBatchTranscription` or a loopback `FakeWhisperServer`, and the only key
string in the repository is the synthetic `'synthetic-key'`. Both BYOK keys live
in the platform secure store, under separate storage keys, and neither is ever
read back into the UI (BR-08).

### One gate failed on the first run

G4 came in at **89.8%**, two tenths of a point under the threshold. The
uncovered lines were the `==`, `hashCode` and `toString` of the three value
types this sprint added to the domain. The fix was a test, not a threshold:
`test/domain/transcription_values_test.dart` covers them, and it earns its place
independently — `RecordingProgress` is compared on every tick of the recording
indicator, so a wrong `==` would either redraw the screen five times a second or
stop redrawing it, and neither failure looks like a failure anywhere else. The
`toString` case asserts that a transcript reports its size and never its
contents, which is what keeps one out of a log line.

## 3. Documented tests

| ID | Behaviour | Cases | Result |
|---|---|---|---|
| S04-UT-01 | Flow orchestration — transcribe → summarize without duplication | 5 | ✅ |
| S04-UT-02 | A transcription failure preserves the audio | 3 | ✅ |
| S04-UT-03 | Cleanup after success and after discard | 4 | ✅ |
| S04-IT-01 | `WhisperBatchEngine`: the request, and every failure it must classify | 18 | ✅ |
| S04-CT-01 | The `BatchTranscription` contract, 6 cases × 2 subjects | 6 declared → **12 executed** | ✅ |
| S04-GT-01 | The recording screen, ten states, dark + light | 22 (20 goldens) | ✅ |
| S04-E2E-01 | Record → transcribe → summarize, and what it left on disk | 4 | ✅ |
| S04-E2E-02 | The permission UX, and the flow it must not break | 4 | ✅ |

Sprint-04 files contribute **72 unit/contract/golden cases** and **8 E2E
scenarios**. The suite total rose from 419 to **491**, 0 skipped, 0 weakened.

### Notes on specific exit criteria

- **S04-UT-01** — the exit criterion is that `SummarizeMeeting` receives
  *exactly* the engine's transcript, so the spy delegates to the **production**
  use case rather than stubbing it. A stub could have agreed with the assertion
  while the app summarized something else. A third case asserts the AI engine
  was reached exactly once, which is what "no duplicated code" looks like from
  below: a second pipeline would show up as a second call or as no call at all.
- **S04-UT-02** — the sprint asks that a *transcription* failure preserve the
  audio. A second case extends it to a **summarize** failure, which the sprint
  does not name but which follows from the same reasoning: transcription is the
  expensive half, and re-running it to recover from an AI hiccup would charge
  the user twice for one meeting.
- **S04-UT-03** — both documented scenarios, plus the case the rule implies: a
  store that *cannot* delete must not turn a summary the user is about to read
  into an error. The file is in a directory the platform clears anyway; the
  summary is what they asked for.
- **S04-IT-01** — driven through a real loopback socket, so the suite exercises
  the URL, the authorization header and the multipart body rather than a mock's
  opinion of them. Two cases matter most: a `200` carrying HTML instead of JSON
  is a failure rather than a transcript, and an **empty** transcript is a
  failure rather than a short meeting — passing that one on would hand the
  summarizer an empty string and produce a confident summary of nothing.
- **S04-CT-01** — two subjects, and the fake is not a spectator. Every use-case,
  widget and E2E test in this sprint drives `FakeBatchTranscription`; a fake
  more forgiving than the adapter would let all of them pass while the app
  failed. One case asserts the property the retry rule rests on — *a failure
  leaves the audio file alone* — against both, because it is a property of the
  port rather than of one implementation.
- **S04-GT-01** — the screen renders from one immutable state object, so the
  goldens are driven by substituting it rather than by racing a timer to the
  right millisecond; a ticking clock would produce a different image every run.
  The mono timer is asserted by a **matcher** as well as by an image, because an
  image can be regenerated around a font regression and a matcher cannot.
- **S04-E2E-01** — the assertion the suite exists for is the last one of the
  first scenario: after a successful run the audio is **not in the store**.
  Everything before it could pass while the app quietly kept an hour of recorded
  meeting on disk.
- **S04-E2E-02** — the scenario is not that an error appears. It is that a
  refusal produces an explanation and a route out, that nothing crashes, and —
  the part that is easy to break and easy to miss — that **going back and
  pasting still works**. A user who cannot record must not be left with an app
  that cannot summarize either.

## 4. Sprint validation rules

| Rule | How it is met |
|---|---|
| The audio file is temporary; never in the documents directory | Enforced by **address, not by check**. `TempAudioStore` resolves exactly one directory — `getTemporaryDirectory()/norte_recordings` — and `getApplicationDocumentsDirectory` is not referenced anywhere in the file. A rule expressed as an address that was never written down cannot be forgotten by a later edit the way a conditional can. |
| A completed transcript enters the Sprint 03 pipeline with no duplicated code | `TranscribeMeetingAudio` **holds** `SummarizeMeeting` rather than reimplementing it, so BR-03 and BR-07 are obeyed here because they are obeyed there — the redactor still runs before the engine and the use case still persists nothing. The convergence continues in the presentation layer: the recorder hands its meeting to `MeetingComposer`, so both input flows share one summary screen, one save path and one BR-03 gate. |
| Microphone permission denied → explanatory screen with a link to system settings; never a crash | A screen, not an error — there is nothing to retry until the user changes something outside the app. `MicrophonePermission` distinguishes *denied* from *permanently denied*, and the "Allow" button is **not rendered** in the second case: a control that produces no prompt is worse than no control. That distinction is the entire reason for DEC-022. |
| Upload/transcription failure → the audio is kept and the user can retry without re-recording | Deletion happens on exactly two events: a successful run, and an explicit discard. The port forbids the *engine* from deleting the caller's file, and S04-CT-01 asserts that against both adapters. The screen says so in words, and the retry button is conditional on the audio actually being there. |
| Recording interruption → paused and recoverable | `RecordAudioRecorder` follows `record`'s own state stream rather than trusting its last instruction, because the platform pauses capture underneath the app on a call or a backgrounding. Elapsed time accumulates closed segments rather than subtracting a start instant from now, so paused minutes are charged neither to the timer nor to the ninety-minute ceiling — and the ceiling is re-armed against what is left when the take resumes. |

## 5. Deviations

Three decisions were recorded in `docs/reports/decisions.md`, plus the five
pre-sprint ones listed in §1.

| ID | Summary |
|---|---|
| DEC-021 | `BatchTranscription` takes a `String path`, not a `dart:io` `File`. The layer rule permits `dart:` imports, so a `File` on a domain port would not have failed the gate — it would have been wrong quietly. |
| DEC-022 | `permission_handler` added to the stack, used only by `RecordAudioRecorder`. `record` reports permission as a boolean, which cannot express the one distinction the permission screen is made of. |
| DEC-023 | Sprint developed on the environment-pinned branch, as in DEC-003, DEC-009, DEC-013 and DEC-015. |

**Nothing was left undone and nothing from a future sprint was implemented.**
Realtime transcription, system audio capture and the intent pipeline all remain
untouched; `RealtimeTranscription` is still provisional, awaiting Sprint 05.
No documented criterion was weakened.

Two smaller choices are recorded here rather than as decisions, because neither
changes a documented rule:

- **A second credential store, not a second field.** `TranscriptionCredentialStore`
  is its own port with its own storage key. They are different providers with
  different lifetimes: a user may summarize pasted transcripts for months before
  recording anything, and a rejected Whisper key must not read as a broken
  Claude one.
- **The recording flow is entered from the new-meeting screen**, not from its own
  tab. The template and the BR-03 retention choice apply to both inputs and are
  made once, above the fork. Giving recording its own entry point would have
  meant duplicating both — and duplicating the retention toggle is duplicating
  the place BR-03 can be got wrong.

### One pre-existing test adjusted

The Sprint 00 fakes sanity suite asserted that an unknown path made
`FakeBatchTranscription` throw a `StateError`. It now asserts `NotFoundFailure`.
This is a strengthening, not a weakening: the fixture map is the fake's
filesystem, so an unknown path is a *missing file*, and S04-CT-01 requires both
subjects to answer it the same way. Under the old behaviour the fake could not
have been a contract subject at all. The suite is not a documented sprint case —
it was added under `docs/project-rules.md` §5.4.

## 6. Goldens

20 new goldens (10 states × 2 themes). The Windows set is committed. Two
pre-existing images — `new_meeting_dark.png` and `new_meeting_light.png` — moved
because that screen gained the "Record audio" button; **the other 49 were
regenerated byte-identical**, which is the evidence that nothing else shifted.

The Linux set — the one CI compares against — is produced on the CI runner image
by the `Generate Linux goldens` workflow and committed from its artifact,
exactly as DEC-011 prescribes. A set generated anywhere else, including a local
WSL distribution, will not match.

## 7. Manual test against a real recording and a real Whisper key

The Definition of Done requires a real ~1 minute recording on each available
platform plus a real transcription with the Developer's own key — the one thing
no fake can stand in for, because it is a real microphone, a real encoder and a
real model being tested rather than ours against ours.

Per **DEC-020**, "available platform" is **Windows and Android**. iOS is a
declared target that has never been built, for want of a macOS host; it is
carried as an open platform obligation, not silently ticked.

**Script**, in the format of `docs/testing-strategy.md` §7:

- **Entry:** the built app on the platform under test; a Whisper API key the
  Developer holds. **The key is typed into the app by the Developer and is never
  committed.**
- **Action:**
  1. Settings → Transcription → paste the key → **Save**. Expect *Key configured*.
  2. Meetings → **New meeting** → choose **Daily** → leave *Save the transcript
     too* **off** → **Record audio**.
  3. Grant the microphone when asked. Speak for about a minute. **Pause**, wait
     ten seconds, **Resume**, speak a little more.
  4. **Stop and transcribe.** Watch the stages: uploading → transcribing →
     summarizing.
  5. Read the result. **Save summary**, go back, and open the saved meeting.
  6. Check the app's temp directory.
- **Exit:** the timer counts captured audio only — the ten paused seconds are
  not in it; the daily's sections describe what was actually said; the saved
  meeting shows *Transcript discarded*; **no `.m4a` remains in
  `<temp>/norte_recordings`**; no key appears in any log.

### Result

**Executed by the Developer on 2026-08-08 against a real microphone and the
real Whisper API, and reported as passing.** The recording flow works end to
end with a real key: the audio was captured, uploaded and transcribed, the
summary came back in the daily template's sections, and the recording was gone
from the temp directory afterwards.

This is the Developer's own attestation, not something the executing AI
observed — which is the nature of this box. No Whisper key was shared with the
AI, none reached this repository, and none appears in any commit.

What the automated suite could not have caught, and this pass therefore covers:
that a real microphone, a real AAC encoder and the real model produce a file the
adapter can upload and a transcript the summarizer can read. Every automated
case proves the pipeline against fixtures; only this one proves the fixtures
resemble a recording.

**Scope of the attestation.** Recorded here as the Developer reported it. Per
**DEC-020** the script covers Windows and Android; **iOS remains unverified**
for want of a macOS host, and stays an open platform obligation carried by
DEC-020 rather than discharged here.

## 8. Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90% — §2, **94.5%**
- [x] All S04-* tests passing — §3, 491 tests and 26 E2E scenarios
- [x] Manual script: a real ~1 min recording (Windows and Android, DEC-020) plus
      a real Whisper transcription with the Developer's own key — §7, **executed
      by the Developer on 2026-08-08 and reported as passing**; key not
      committed
- [x] Report `docs/reports/sprint-04-report.md` — this document
- [x] Linux golden set committed from the workflow artifact (DEC-011) — §6,
      [run 31273625525](https://github.com/Aennson/norte/actions/runs/31273625525):
      twenty files added, exactly two changed, forty-nine byte-identical
- [x] GitHub Actions 100% green on the sprint PR — **PR #6**, all six checks
      `pass` on the branch push
      ([run 31273722794](https://github.com/Aennson/norte/actions/runs/31273722794))
      and again on the pull request
      ([run 31273739671](https://github.com/Aennson/norte/actions/runs/31273739671)):
      analyze/format/imports/secrets, tests + coverage + goldens, and the E2E
      job across all eight suites. The PR reports `MERGEABLE` / `CLEAN`

**Every box is checked**, and each one on evidence rather than on a promise —
which is the standard §1's audit of the earlier sprints was carried out to
restore. The sprint is complete and PR #6 is ready for the Developer to merge;
merging is theirs to do, not the executing AI's.

**One obligation leaves this sprint still open**, and is carried explicitly
rather than closed by silence: **iOS has never been built or tested**, and the
`test/presentation/goldens/images/macos/` set does not exist. DEC-020 holds both
until a macOS host does. Sprint 08 (hardening) is where that decision — a
three-platform v1.0 or a two-platform one — has to be made.
