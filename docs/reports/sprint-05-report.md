# Sprint 05 — Realtime Voice: Scribe, IntentParser, 5 Intents, and Confirmation · Report

**Branch:** `sprint-05/realtime-voice` · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Pro 26200 (Developer's machine) · **CI:** `ubuntu-latest`

This is the first sprint whose branch carries the name `docs/project-rules.md`
§7.1 specifies. Sprints 00–04 each needed a decision (DEC-003, 009, 013, 015,
023) recording that the execution environment pinned them to a `claude/…`
branch. That constraint is gone, so there is no DEC for it here.

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 04 DoD complete | Closed 2026-08-08; PR #6 merged into `master` at `02fe538`, all six checks green. Verified at the start of this sprint by re-running the gates at that commit: analyze clean, 577 tests, imports OK | ✅ |
| `FakeRealtimeTranscription` available | Written in Sprint 00 against the provisional port; promoted to the real one as the first act of this sprint, and now a **subject** of S05-CT-01 rather than a convenience | ✅ |
| PT-BR dataset ≥ 50 utterances, ≥ 10 ambiguous | `test/fixtures/intents/ptbr_dataset.json` — **52 rows**, 42 actionable across the five intents and **10** whose ground truth is `unknown` | ✅ |
| en and it smoke datasets ≥ 10 each | `en_dataset.json` and `it_dataset.json` — **13 rows each**, covering all five intents plus two ambiguous ones (BR-11) | ✅ |

### The datasets are deliberately imperfect

Every fixture is a *raw model answer* replayed through the production
`IntentCodec`, and several of them are wrong on purpose: a question read as a
command (`ptbr-039`), a comment read as a task (`ptbr-018`), a truncated
comment, an untranslated transition name, prose with no JSON, JSON missing
`intent`, an `intent` outside the enum.

A dataset that answered perfectly would report 100% forever, and the sprint's
`≥ 90%` / `≥ 85%` thresholds would never distinguish a healthy parser from a
broken one. The PT-BR set currently sits at 96.2% and 88.5% — close enough to
the line that a regression in the codec crosses it.

## 2. Quality gates

Every command run at `HEAD` of the sprint branch, on the Developer's Windows
machine, and again on `ubuntu-latest` in CI.

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 4.5s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --output=none --set-exit-if-changed .` | exit 0 ✅ |
| G3 — tests | `flutter test` | `00:36 +644: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **93.2%** (517/555) · project **84.1%** (3995/4753) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match ✅ |
| E2E | `flutter test integration_test/<suite>`, one per file (DEC-010) | 9 suites, 33 scenarios, all passing on the Linux runner ✅ |

Coverage excludes machine-generated sources (DEC-008).

**No real credential is anywhere in the tree.** No Scribe key, no Whisper key
and no Claude key was used at any point: every test drives a fake engine, a
loopback fake server or `FakeRealtimeSocket`, and the only key string in the
repository is the synthetic `'synthetic-key'`.

### One gate failed on the first run

G4 came in at **79.2%**, eight tenths of a point under the project threshold.
The cause was structural rather than accidental: the voice presentation layer —
`voice_providers.dart`, `voice_host.dart`, `voice_labels.dart` — is exercised
almost entirely by `integration_test/`, and the E2E suites run in a separate
invocation that contributes nothing to `lcov.info`.

The fix was `test/presentation/voice_session_test.dart`, which drives the same
pipeline through a widget tree and covers the branches an E2E scenario reaches
only one at a time: every slot question, every intent description, every
failure mapping. 79.2% → **83.9%**.

## 3. Tests

| ID | What it covers | Where |
|---|---|---|
| S05-UT-01 | Parser: valid JSON → the intent it names, exact slots, confidence 0.92 — plus fenced JSON and JSON behind prose | `test/application/intent_parser_test.dart` |
| S05-UT-02 | Parser: prose, JSON without `intent`, and an intent outside the enum all become `unknown` at confidence 0, with no exception escaping | same |
| S05-UT-03 | Router: 0.74 requires confirmation and the use case is **never called**; 0.76 executes (BR-04) | `test/application/intent_router_test.dart` |
| S05-UT-04 | Router: a Jira write at 0.99 still confirms with the setting on, and executes via the outbox with it off | same |
| S05-UT-05 | Router: a missing slot is named on its own, nothing runs, and supplying it completes the intent | same |
| S05-UT-06 | `ScribeRealtimeEngine`: three seconds of an outage re-sent whole, seven seconds trimmed to the last five, no byte on disk | `test/infrastructure/scribe_realtime_engine_test.dart` |
| S05-CT-01 | `RealtimeTranscription` contract on `FakeRealtimeTranscription` and `ScribeRealtimeEngine` | `test/contracts/realtime_transcription_contract_test.dart` |
| S05-CT-02 | `AiEngine.parseIntent` contract on `FakeAiEngine` and `ClaudeApiEngine` | `test/contracts/ai_engine_contract_test.dart` |
| S05-EV-01 | Multilingual intent eval over the three datasets | `test/evals/intent_dataset_eval_test.dart` |
| S05-GT-01 | `VoiceOverlay` (partial, committed, asking) and `ConfirmSheet` (low confidence, Jira policy), dark and light | `test/presentation/goldens/voice_components_golden_test.dart` |
| S05-E2E-01 | "muda o PROJ-123 para concluído" → sheet → confirm → outbox; scenario B cancels; scenario C runs with the setting off | `integration_test/voice_command_test.dart` |
| S05-E2E-02 | "cria tarefa revisar PR do conector" → no sheet, task in the list | same |
| S05-E2E-03 | "faz aquilo lá que combinamos" → rephrase, nothing created; scenario B proves the pipeline still works afterwards | same |

Beyond the specification, under `docs/project-rules.md` §5.4: the reminder
stub's boundary (`create_reminder_test.dart`), the two new Drift adapters and
schema 4 (`voice_persistence_test.dart`), the latency percentile
(`voice_latency_log_test.dart`), and the voice presentation layer
(`voice_session_test.dart`).

## 4. The eval

`build/eval/s05_ev_01_report.md`, regenerated on every run:

| Dataset | Utterances | Intent accuracy | Exact slots | Ambiguous kept `unknown` |
|---|---|---|---|---|
| pt-BR | 52 | **96.2%** (50/52) | **88.5%** (46/52) | **10/10** |
| en | 13 | 100% | 100% | 2/2 |
| it | 13 | 100% | 100% | 2/2 |

Thresholds: intent ≥ 90%, exact slots ≥ 85%, ambiguous **100%**.

The ambiguous count is a count, not a percentage, and that is the point. An
utterance the model did not understand becoming an action is the failure the
whole confirmation design exists to prevent; one is one too many.

**What the eval measures, honestly.** The fixtures are replayed, so this is a
regression eval over the *parsing pipeline* — schema validation, the
fenced/prose tolerance, slot normalisation, and the refusal to turn an
unreadable answer into an action. It is not a measurement of the model, which
would need the network and could not run in CI (§5.4). The manual pass in §7 is
where the model itself is exercised.

## 5. Business rules

| Rule | How this sprint honours it | Test |
|---|---|---|
| **BR-04** | `confidence < 0.75` on a mutating intent returns `ConfirmationRequired` **before any use case is touched** — the spy assertion, not an assertion on a return value | S05-UT-03 |
| **BR-05** | Every Jira intent goes through the Sprint 02 use cases into the outbox. The router holds no gateway and cannot reach one | S05-UT-04, S05-E2E-01 |
| **BR-06** | `Microphone` is a port that knows no path; `ScribeRealtimeEngine` imports no `dart:io`; the reconnection buffer is memory capped at five seconds; `reminders` has no audio column. Verified at runtime by an `IOOverrides` spy that records the *attempt* rather than the leftovers | S05-UT-06 |
| **BR-11** | 28 new strings in all three ARB files at key parity; `SlotMissing` carries a slot name and the wording lives in `voice_labels.dart`; the eval covers en and it | S00-UT-06, S05-EV-01 |

## 6. Goldens

Ten new files, dark and light:
`voice_overlay_partial`, `voice_overlay_committed`, `voice_overlay_asking`,
`voice_confirm_sheet_low`, `voice_confirm_sheet_jira`.

The Linux set was minted by the `goldens.yml` workflow
([run 31281263473](https://github.com/Aennson/norte/actions/runs/31281263473))
and committed from the artifact (DEC-011). **Ten files added; none of the
seventy-one existing files changed.** That byte-identical result is the useful
part: the shell now wraps its child in a `Stack` whether or not there is a
voice panel to put in it, and a set that came back unchanged is what proves the
change moved nothing on any existing screen.

## 7. Manual script — **executed**

Run by the Developer on Windows, 2026-08-09, with their own Scribe and Claude
keys. **A spoken command created a task.** The pipeline works end to end:
microphone → PCM → Scribe → committed transcript → intent → use case → row in
the database.

It took six attempts, and every one of them found a defect. That is the honest
headline of this sprint, and §7.1 is the list.

### 7.1 What the manual pass found

Six defects, none of which any automated test could have caught, because every
one lives in the seam between the app and something outside it.

| # | Defect | Why no test saw it |
|---|---|---|
| 1 | The Scribe key shared the Whisper storage slot (DEC-028) | `main()` is untested by construction |
| 2 | The API key was never sent on the handshake (DEC-029) | `realtime_socket.dart` had 0 of 14 lines covered — every test drove the fake transport |
| 3 | Audio was sent as binary; the protocol wants base64 JSON (DEC-026) | The fake spoke the invented dialect, so the contract suite agreed with itself |
| 4 | The audio meter threw on an unaligned frame and killed the session (§7.4) | No test fed it a frame at an odd byte offset — the platform does |
| 5 | The intent schema carried `minimum`/`maximum`, which the API rejects | A schema is a request, and nothing asserted the request was legal |
| 6 | One sentence arrived as several segments and executed twice | VAD segments on silence; the fake emitted one segment per utterance |

**The pattern is one pattern.** Every fake in this sprint was written from what
the code expected rather than from what the world does, and each was
consequently more forgiving than reality on exactly the axis that mattered. A
fake that speaks a dialect the service does not manufactures confidence, and
five of the six above were invisible precisely because the suite was green.

### 7.2 The p95, measured — and **above target**

Three consecutive commands, real engine, real speech:

| Run | committed → intent ready |
|---|---|
| 1 | 3973 ms |
| 2 | 3435 ms |
| 3 | 3627 ms |

**p95 = 3973 ms against a target of < 3 s** (`docs/architecture.md` §15). The
target is missed, and the sprint records that rather than rounding it.

What is already in place: `effort: 'low'` on the intent request, the system
prompt marked `cache_control` and byte-identical across every command, and a
512-token ceiling. What has **not** been tried: shortening the prompt itself,
which is the largest remaining variable, and measuring the split between
Scribe's commit latency and Claude's response — the instrument records only the
total, so the two are currently indistinguishable.

That split is the first thing Sprint 05a should measure, because optimising the
wrong half is the obvious way to spend a day for nothing.

### 7.3 How the wire format was settled

Three rounds, and the order is the lesson.

**Writing the instructions** found defects 1 and 2 — not by testing, but by
writing down the steps a person would follow and discovering that step 2 had no
answer.

**A live probe** with a short-lived key corrected four assumptions and produced
**one confident wrong answer**: that audio is raw binary. Thirteen candidate
message types were each refused; `input_audio_chunk` was not among them, and
even it would have been refused without its required fields — because *refused
by name* and *refused for a missing field* are indistinguishable from outside.

**Reading a working implementation** settled the rest in minutes. The Developer
pointed at `zefa-ia`, their own ElevenLabs integration: base64 in a JSON text
frame, `audio_format=pcm_16000`, `commit_strategy=vad`, a fourth transcript
type, and a commit that rides on an audio chunk rather than not existing.

**What generalises.** A black-box probe can refute but never confirm: an
accepted message proves its shape works, a refused one proves nothing about
*why*. Where a working implementation exists, read it first. This sprint spent
an afternoon establishing what a colleague's repository already knew, and then
shipped a wrong conclusion from it.

### 7.4 The defect the feedback work introduced

The audio meter added mid-sprint read PCM through `Int16List.view`, which
requires a two-byte-aligned offset. `record` hands out frames that are views
into a larger buffer at whatever offset the platform picked, so the first frame
threw — and because the level is computed inside a `map` on the microphone
stream, the throw became a stream error and killed the session. The console
showed it exactly: one frame captured, `session failed after 0 audio frames`,
then 426 further frames captured by a microphone nobody was listening to.

Fixed by reading through `ByteData`, and — the part that generalises — by making
the measurement incapable of breaking the pipeline it measures. **A diagnostic
that can kill the thing it observes is worse than no diagnostic.**

### 7.5 Scope added during the manual pass

On the Developer's instruction after the first successful command, three
behaviours changed beyond the sprint's written scope. They are recorded as
decisions rather than folded in silently:

- **DEC-031** — the microphone stays open until the user stops it and commands
  execute as they are spoken. It used to close on every commit, making each
  command a separate press of the button; and a misunderstanding used to cost
  the session as well as the command.
- **DEC-032** — hesitation is filtered twice and asymmetrically: `no_verbatim`
  at the service, `SpeechFiller` locally, and only a segment that is *entirely*
  filler is dropped.
- **§6.3 of the architecture** — a task is this app's own unless Jira is named.
  The prompt says so; the intents themselves arrive in Sprint 05a (DEC-030).

## 8. Deviations and open items

| Item | Status |
|---|---|
| Manual script | **Executed** — §7, 2026-08-09, a spoken command created a task |
| **p95 latency 3973 ms against a < 3 s target** | **Open, and missed** — §7.2. Measured, reported, not rounded. The prompt length and the Scribe/Claude split are untried |
| Scribe key shared the Whisper slot | **Fixed before merge** — DEC-028, §7.1. Found by writing §7.2, not by a test |
| The realtime key was never sent on the handshake | **Fixed before merge** — DEC-029, §7.1. `realtime_socket.dart` had zero coverage |
| Scribe wire format unverified | **Settled** — DEC-026, §7.3, against `zefa-ia`, a working implementation. Audio is base64 JSON, not binary |
| The audio meter killed the session | **Fixed** — §7.4. An unaligned frame threw inside a `map` on the microphone stream |
| Wall-clock reminder times (`tomorrow 09:00`) | **Deliberately deferred** — DEC-025 hands them to Sprint 06 with a failing case attached, rather than implementing S06-IT-02's timezone work without its tests |
| iOS never built or tested; no `macos/` golden set | **Still open** — inherited from DEC-020, unchanged by this sprint. Sprint 08 is where a three-platform or two-platform v1.0 has to be decided |

## 9. Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90% — §2, **93.0%**
- [x] All S05-* tests passing; eval S05-EV-01 in CI with fixtures — §3, §4
- [x] p95 latency (committed → intent) measured with the real engine in a manual test — §7.2, **3973 ms**. The measurement is done; **the < 3 s target is not met**, and the box is ticked for the measurement it asks for, not for the number it hoped to see
- [x] Report `docs/reports/sprint-05-report.md` — this document
- [x] Linux golden set committed from the workflow artifact (DEC-011) — §6
- [x] GitHub Actions 100% green on the sprint PR — §10, **all six checks pass**

## 10. CI

All three jobs green, on the branch push and again on the pull request, at
`67b4535` — the commit that carries the DEC-028 credential fix:

| Job | Branch push ([run 31284679235](https://github.com/Aennson/norte/actions/runs/31284679235)) | Pull request ([run 31284681007](https://github.com/Aennson/norte/actions/runs/31284681007)) |
|---|---|---|
| G1 analyze · G2 format · G5 imports · G6 secrets | pass, 41s | pass, 45s |
| G3 tests · G4 coverage · goldens | pass, 1m51s | pass, 1m39s |
| E2E (Linux desktop host) | pass, 5m31s | pass, 5m49s |

No skips, no re-runs (`docs/project-rules.md` §7.3). The E2E job runs each
suite in its own invocation (DEC-010) — nine suites, thirty-three scenarios,
including the seven this sprint added.

**Worth naming:** the golden job compares against the Linux set committed in
§6, and it passed on the first attempt after the voice components were added.
The earlier red run on this branch was that job, before the set existed — a
missing golden, not a differing one.

[PR #7](https://github.com/Aennson/norte/pull/7) reports mergeable. Merging is
the Developer's, not the executing AI's.

---

**Every box is ticked, and one of them carries a number that misses its
target.** The p95 is 3973 ms against < 3 s. It is measured, reported, and left
open in §8 rather than rounded into a pass — a sprint that closes by adjusting
its own target has not closed anything.

Everything a machine can verify has been verified — 644 unit, golden and
contract tests, 33 E2E scenarios on a Linux desktop host, an eval whose
thresholds sit close enough to the results to bite. What remains needs a microphone, two API
keys and a person, and reporting it as done would be reporting a wish.
