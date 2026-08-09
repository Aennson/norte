# Sprint 05a — Task Commands: Local Intents, Rich Creation, Filters and Search · Report

**Branch:** `sprint-05a/task-commands` · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Pro 26200 (Developer's machine) · **CI:** `ubuntu-latest`

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 05 DoD complete and merged | PR #7 merged at `57a3cc9` and its tail PR #8 at `9bf6776`; `docs/reports/sprint-05-report.md` closed with one open number (§8 below). This branch starts from `master` at `6f026d7`, which carries both | ✅ |
| `IntentParser`, `IntentRouter` and `ConfirmSheet` in place, with continuous listening | All three shipped in Sprint 05; DEC-031's continuous session is what S05a-E2E-02 depends on to speak three commands without pressing the button again | ✅ |
| `TaskQuery.statuses` already a set | `lib/application/usecases/list_tasks.dart` has held a `Set<TaskStatus>` since Sprint 01. Only `TaskQueryNotifier.filterByStatus` and the chip bar restricted it to one, and both are replaced here | ✅ |

## 2. Quality gates

Every command run at `HEAD` of the sprint branch on the Developer's Windows
machine, and again on `ubuntu-latest` in CI.

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 6.7s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --set-exit-if-changed .` | `Formatted 251 files (0 changed)`, exit 0 ✅ |
| G3 — tests | `flutter test` | `00:40 +721: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **93.2%** (619/664) · project **84.2%** (4303/5108) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match (exit 1) ✅ |
| E2E | `flutter test integration_test/<suite>`, one per file (DEC-010) | **10 suites, 37 scenarios**, all passing ✅ |

Coverage excludes machine-generated sources (DEC-008). The suite grew from 644
to 721 tests; domain+application coverage held at 93.2% while the layer itself
grew by 109 lines.

## 3. Tests

Every documented case, with the file it lives in.

| ID | Where | Result |
|---|---|---|
| S05a-UT-01 | `test/application/task_commands_test.dart` | ✅ 2 scenarios |
| S05a-UT-02 | same | ✅ 9 scenarios — four statuses, four priorities, and the unrecognised value |
| S05a-UT-03 | same | ✅ 2 scenarios |
| S05a-UT-04 | same | ✅ 3 scenarios |
| S05a-UT-05 | same | ✅ 3 scenarios — 0.99, 0.40, and the confirmation |
| S05a-UT-06 | same + `test/application/comment_task_test.dart` | ✅ 7 scenarios |
| S05a-UT-07 | same + `test/evals/intent_dataset_eval_test.dart` | ✅ 8 scenarios across three languages |
| S05a-UT-08 | `test/application/task_commands_test.dart` | ✅ 3 scenarios |
| S05a-UT-09 | same | ✅ 2 scenarios |
| S05a-IT-01 | `test/infrastructure/task_comments_test.dart` | ✅ 5 scenarios |
| S05a-GT-01 | `test/presentation/goldens/task_filters_golden_test.dart` | ✅ 7 scenarios, 6 golden files × 2 platforms |
| S05a-E2E-01 | `integration_test/task_commands_test.dart` | ✅ |
| S05a-E2E-02 | same | ✅ 3 scenarios, including the cancelled deletion (B) |

Supporting tests not in the sprint document, added under
`docs/project-rules.md` §5.4: `test/domain/text_match_test.dart` (the fold both
features share) and the extensions to `voice_session_test.dart` for the new
slot question and the third confirmation reason.

### The router tests drive real use cases, not spies

Sprint 05's `intent_router_test.dart` mocks every use case, which is the right
shape for asserting *that* a branch was taken. `task_commands_test.dart` asserts
what the branch *did* — all four attributes on the stored task, the outbox that
stayed empty, the row that survived a cancelled deletion — so it runs the real
use cases over `FakeTaskRepository`. A spy cannot fail those assertions,
because a spy has no state to be wrong about. That is Sprint 05 §5's lesson
applied rather than restated.

### S05a-IT-01 stamps its comments out of order on purpose

Insertion order is stored in a `position` column rather than derived from
`createdAtMs`. Sorting by the timestamp would be *nearly* right and wrong
exactly where it matters: every comment written under a pinned test clock
shares a millisecond, so a reader that sorted by time would come back in
whatever order SQLite chose and no test with a `FakeClock` could see it. The
fixture therefore stamps its middle comment five minutes *earlier* than its
first, so insertion order and chronological order disagree and the assertion
can tell them apart.

## 4. The eval

| Dataset | Rows | Intent | Exact slots | Ambiguous |
|---|---|---|---|---|
| pt-BR | 64 (was 52) | **95.3%** (61/64) | **87.5%** (56/64) | 10/10 |
| en | 16 (was 13) | 100% | 100% | 2/2 |
| it | 16 (was 13) | 100% | 100% | 2/2 |

Thresholds: ≥ 90% intent, ≥ 85% exact slots, 100% ambiguous. Report artifact at
`build/eval/s05_ev_01_report.md`.

**Two of the twelve new PT-BR rows are wrong on purpose**, and both are the
local mirror of a mistake the Jira rows already record. `ptbr-056` returns
`"status": "bloqueada"` — the speaker's word instead of the enum name §6.3.2
asks for, exactly as `ptbr-004` does for an untranslated Jira transition.
`ptbr-062` reads a note on an existing task as a new task, as `ptbr-018` reads a
Jira comment as one; the confusion is between *creating* and *annotating*, and
it survives the move from Jira to the local list.

Adding perfect rows only would have raised the headroom from 96.2% to 98.4% and
made the thresholds easier to hit, which is the opposite of what they are for.
Both figures moved *down* and stayed above the line.

## 5. Sprint validation rules

| Rule | How it is enforced | Where |
|---|---|---|
| BR-01 holds throughout — no local intent touches Jira | `CommentTask` holds a task repository, a clock and an id generator. It has no gateway and no outbox, so there is no code path from a spoken note to a linked issue. The guarantee is structural, not a rule someone remembers | S05a-UT-06, S05a-E2E-02 (C) |
| Jira is opt-in by naming | The prompt says so; the eval re-parses every dataset row whose utterance carries neither an issue key nor the word "Jira" and fails if any produced `updateJira`, `addComment` or `queryStatus` | S05a-UT-07 |
| `deleteTask` always confirms | `_confirmationFor` checks `isDestructive` **first**, before the Jira rule and before BR-04. The reason reported is `deletion`, not `lowConfidence`: telling a user their 0.99 parse was doubtful would blame them for the app's policy | S05a-UT-05 |
| `taskRef` never guesses | One match acts; several return `TaskAmbiguous` naming every candidate; none returns `TaskNotFound` and writes nothing | S05a-UT-03, S05a-UT-04 |
| `status` and `priority` are enum names, never translations | `statusFrom`/`priorityFrom` return `null` for anything outside the vocabulary, and the router passes `null` through as "unchanged" | S05a-UT-02 |
| Filters compose | Two chips are a union; the search runs over what the chips left | S05a-UT-08 |
| An empty search and an empty database read differently | Three sentences, not two: an empty database, a filter that matched nothing, and a search that matched nothing — the last names the term back | S05a-GT-01 |

### One rule needed a decision the sprint file did not anticipate

**An exact title beats a longer one that contains it.** §6.3.1 says several
matches are a question, and taken literally that makes "Ligar para Samara"
permanently unreachable while "Ligar para Samara de novo" exists: every
reference to the shorter task also matches the longer one, so the app would ask
forever and the user could never answer. The resolution keeps the rule and adds
one step before it — a title that *is* the phrase, folded, wins outright; only
when the phrase is a prefix of several and equal to none does the app ask.
S05a-UT-04's third scenario pins it.

## 6. Deviations

**One addition beyond the written scope: the task card now shows its
description.** S05a-E2E-01's exit criterion is "the task appears in the list
with **all four** attributes visible", and three of the four were already
rendered. Adding the fourth is also what makes the search honest: a list that
can be filtered by a word it will not display is a list answering questions it
will not show its working for. Two lines, `textSecondary`, ellipsised — the
title still leads. It moved eight existing goldens.

**One pseudo-slot that is not in the architecture: `change`.** An `updateTask`
that names a task and nothing to change is a sentence the model read as a
command and the app cannot act on. It is reported as a missing slot rather than
refused as `unknown`, because the user *did* name a task — they said what, and
the app only needs to know what to. `VoiceIntent.changeSlot` and
`l10n.voiceAskChange` carry it.

Nothing else. No item of the "Out" list — reading tasks aloud, bulk operations,
undo, any change to the Jira intents — was touched.

## 7. Open, and carried forward

**The p95 from Sprint 05 is still above target and is not addressed here.**
Warm totals run 3185–3853 ms against the 3 s target of `architecture.md` §15.
Sprint 05's handoff lists the two remaining levers — trimming the required
nullable slots in `IntentCodec.schema`, and a smaller model — and this sprint
moved the first one in the *wrong* direction: the schema went from eight
declared slots to eleven, because `taskRef`, `description` and `status` are
real slots the local intents need. Every intent still emits the ones that are
not its own as `null`.

That cost is measurable and unmeasured: no manual pass was run this sprint, so
the effect of three more output tokens per answer on the warm median is not
known. It is recorded here rather than estimated.

**`primeCache()` is still unverified** — Sprint 05's handoff §3 asks for one
manual pass showing `cache read 1509` on the *first* command of a session. No
automated test can confirm it and none was added; the evals run against
`FakeAiEngine`.

## 8. Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90% — **93.2%**, §2.
- [x] All S05a-* tests passing — 13 IDs, 45 scenarios, §3.
- [x] The eval dataset extended with the local intents, still ≥ 90% / ≥ 85% —
      **95.3% / 87.5%** on PT-BR after adding twelve rows, two of them wrong on
      purpose, §4.
- [x] Report `docs/reports/sprint-05a-report.md` — this document.

## 9. CI

Linux goldens were regenerated by the `goldens.yml` workflow
([run 31325465151](https://github.com/Aennson/norte/actions/runs/31325465151))
and committed at `d6aec09`, per DEC-006 — `--update-goldens` only ever writes
the running platform's directory, so the Windows set generated on the
Developer's machine could not stand in for it.
