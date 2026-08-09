# Sprint 05b — Naming a Task Out Loud: Approximate `taskRef` Resolution · Report

**Branch:** `sprint-05b/task-ref-matching` · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Pro 26200 (Developer's machine) · **CI:** `ubuntu-latest`

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 05a DoD complete and merged (PR #10) | Merged at `d12213d`; `docs/reports/sprint-05a-report.md` closes all four boxes. This branch starts from `master` at `d12213d` | ✅ |
| `TextMatch` in `domain/services/` with `fold` and `contains` (DEC-034) | `lib/domain/services/text_match.dart`, shipped in Sprint 05a and shared by the voice lookup and the search box | ✅ |
| `IntentRouter._resolve` returning `TaskNotFound` / `TaskAmbiguous` / one task, with the exact-title tier ahead of containment | `lib/application/voice/intent_router.dart`; S05a-UT-04's third scenario is the exact-title rule | ✅ |

## 2. Quality gates

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 8.1s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --set-exit-if-changed .` | `Formatted 253 files (0 changed)`, exit 0 ✅ |
| G3 — tests | `flutter test` | `01:02 +751: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **93.9%** (692/737) · project **84.5%** (4378/5183) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match (exit 1) ✅ |
| E2E | `flutter test integration_test/<suite>`, one per file (DEC-010) | **11 suites, 39 scenarios**, all passing ✅ |

The suite grew from 721 to 751 tests. Domain+application coverage rose from
93.2% to 93.9% while the layer grew by 73 lines — the new code is the ladder
and the three string functions, and every branch of both is exercised.

## 3. Tests

| ID | Where | Result |
|---|---|---|
| S05b-UT-01 | `test/application/task_ref_matching_test.dart` | ✅ 2 scenarios — the defect, and that it resolved *exactly* |
| S05b-UT-02 | same | ✅ 4 scenarios, one per spelling |
| S05b-UT-03 | same | ✅ |
| S05b-UT-04 | same | ✅ 2 scenarios — the tie that is not a tie, and the missing chamado |
| S05b-UT-05 | same | ✅ |
| S05b-UT-06 | same | ✅ |
| S05b-UT-07 | same | ✅ 2 scenarios (fixture amended — §6) |
| S05b-UT-08 | same | ✅ |
| S05b-UT-09 | `test/domain/text_match_test.dart` | ✅ 11 scenarios across `squash`, `digitRuns` and `similarity` |
| S05b-GT-01 | `test/presentation/goldens/voice_components_golden_test.dart` | ✅ 2 scenarios, 1 golden file × 2 themes × 2 platforms |
| S05b-E2E-01 | `integration_test/task_ref_matching_test.dart` | ✅ |
| S05b-E2E-02 | same | ✅ |
| S05b-EV-01 | `test/evals/intent_dataset_eval_test.dart` | ✅ 3 PT-BR rows routed over the decoy list |

### S05b-UT-04 cannot pass by luck

The sprint asked for an assertion that `HEROBRAZIL-762` is *absent from the
candidates* rather than merely out-scored, and the numbers make that assertion
sharp without exposing any internals. Against the reference `Hero Brasil-763`:

| Candidate | Score | Above `similarityThreshold` (0.82)? |
|---|---|---|
| `HEROBRAZIL-763` | 0.923 | yes |
| `HEROBRAZIL-762` | 0.846 | yes |

The gap is **0.077**, below `similarityMargin` (0.08). So an implementation
that ranked the two would be obliged to ask — `TaskAmbiguous` — and only one
that excludes 762 outright can execute. The test asserts both numbers before
it routes, so a future change to either threshold fails here first, loudly,
rather than silently turning the exclusion into a ranking.

## 4. What was built

**Domain.** `TextMatch` gained `squash` (fold minus every non-alphanumeric
rune), `digitRuns`, and `similarity` — normalised Damerau–Levenshtein over
`squash`, with transpositions at one edit — plus `similarityThreshold` (0.82),
`similarityMargin` (0.08) and `minApproximateLength` (4) as named constants, so
a test states the threshold it exercises rather than repeating a literal.

**Application.** `_resolve` is the four-tier ladder of §6.3.1: exact →
containment → squashed → approximate, each tier exhausted before the next, a
tie inside any tier a question. Tiers 3 and 4 are preceded by the digit filter.
`IntentExecuted` carries `resolvedApproximately`, which is how S05b-UT-03
distinguishes tier 4 from tier 3 — the outcome of the action is otherwise
identical, and that is the point.

**Presentation.** `updateTask` and `commentTask` now name the row they acted
on, in all three languages. The two ARB keys gained a `title` placeholder;
`voiceDoneTaskDeleted` already had one.

### The one thing the ladder deliberately does not do

Tier 3 answers the reported defect and consults no threshold. Tier 4 exists
only for the harder class the Developer described in the same report — a
Brazilian speaker saying "Hero Brasil" against a title written `HEROBRAZIL`.
Keeping them separate is what lets `HEROBRAZIL-762` heard as "Hero Brazil-762"
resolve with the same certainty as an exact title, instead of being decided by
a number that could be tuned wrong.

## 5. The manual pass against the real Scribe — **OUTSTANDING**

**This is the one box that is not ticked, and it cannot be ticked by anyone but
the Developer.** The DoD asks for it explicitly and the reason is in the
`sprint-05` report §5: no fake found the bug, so no fake can confirm the fix.
Every test above replays a `taskRef` somebody typed into a fixture; the defect
was a `taskRef` a person said out loud, and the whole class of failure this
sprint addresses lives in the gap between those two.

The automated evidence goes as far as it can. S05b-E2E-01 replays the exact
utterance of 2026-08-09 through the real composition root — real database, real
router, real screens — with the transcript the real Scribe produced that
morning hard-coded into the fake. What it cannot prove is that Scribe still
produces that transcript, or what it produces for the five references below
that nobody has spoken into it yet.

### The script to run

Seed the list with `HEROBRAZIL-762` (in progress), `HEROBRAZIL-763` (todo),
`Ligar para Samara` and `Preparar a demo`, then speak, in pt-BR:

| # | Say | Expected | What it proves |
|---|---|---|---|
| 1 | "coloca a atividade Hero Brazil-762 para o status de pronto" | `HEROBRAZIL-762` → done, named back in the overlay | The exact failure of 2026-08-09, tier 3 |
| 2 | "coloca a atividade Hero Brasil-762 em progresso" | `HEROBRAZIL-762` → in progress, named back | Tier 4 on a real transcript |
| 3 | "marca a Hero Brasil-763 como bloqueada" | `HEROBRAZIL-763` → blocked, and **762 never offered** | The digit rule, which is the one that stops the wrong chamado being closed |
| 4 | "apaga a atividade Hero Brasil-762" | Confirmation sheet naming `HEROBRAZIL-762`; cancel; the task survives | BR-04's floor survived the ladder |
| 5 | "comenta na atividade ligar pra Samára: cliente retornou" | `Ligar para Samara`, named back | An accent and a contraction, tier 4 |
| 6 | "muda a PR" | No task called "PR" — `Preparar a demo` is **not** matched | `minApproximateLength` |

Record for each: what Scribe transcribed into `taskRef`, which tier answered,
and the line the overlay showed. A row that resolves to the wrong task, or
command 3 offering 762, is a defect against this sprint and not a tuning
question.

**Until this section is filled in with a real session, the sprint's Definition
of Done is incomplete and the PR should not merge.**

## 6. Deviations

One, and it is a fixture, not a behaviour.

**S05b-UT-07's second task was specified as `Preparar a demo`.** The fold of
that title contains `pr` — "**pr**eparar" — so tier 2 returns two matches and
both halves of the documented exit criteria become unreachable: the first
scenario would be a `TaskAmbiguous` rather than a resolution, and the second
would resolve rather than return `TaskNotFound`. The rule under test is
`minApproximateLength`, so the title was changed to `Fazer a demo`, which does
not contain the reference. The assertions are unchanged and nothing was
weakened — a title that *does* contain the reference is already tier 2's
subject in S05b-UT-02. The amendment is recorded in
`docs/sprints/sprint-05b-task-ref-matching.md` next to the test.

Nothing else in the sprint document was altered.

## 7. Notes for the next sprint

**Three PT-BR eval rows are correct on purpose**, which raised the headroom
slightly (95.3% → 95.5% intent, 87.5% → 88.1% slots). They measure resolution,
not parsing — the parse was never what failed — so making them wrong would have
tested nothing this sprint built. Sprint 08's eval work should keep the
distinction: `resolvesTo` rows answer "did the reference find the row", the
rest answer "did the codec read the answer".

**`similarity` is O(title × reference) per candidate and runs over the whole
list.** At the size of a personal task list this is nothing, and tiers 1–3
answer most references before tier 4 is reached. If the list ever grows by an
order of magnitude, the cheap fix is to skip candidates whose length differs
from the reference by more than the threshold allows — no behaviour changes,
because such a candidate cannot clear it.

**`primeCache()` is still unverified** — carried forward from Sprint 05a §7 and
Sprint 05's handoff §3, untouched by this sprint.

## 8. Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90% — **93.9%**, §2.
- [x] All S05b-* tests passing — 13 IDs, 30 scenarios, §3.
- [x] The eval dataset carries at least three rows whose `taskRef` is spelled
      differently from any plausible title, and the thresholds still hold —
      `ptbr-065..067`, routed over a list carrying `HEROBRAZIL-763` as a decoy;
      PT-BR at **95.5% / 88.1%** against 90% / 85%, §3 and §7.
- [ ] Report `docs/reports/sprint-05b-report.md`, including a **manual pass**
      against the real Scribe — the report is this document; **the manual pass
      is outstanding**, §5. It is the last box, it is the Developer's to tick,
      and the sprint is not closed until it is.

## 9. CI

Linux goldens were regenerated by the `goldens.yml` workflow
([run 31338116118](https://github.com/Aennson/norte/actions/runs/31338116118))
and committed on this branch, per DEC-006 — `--update-goldens` only ever writes
the running platform's directory, so the Windows set generated on the
Developer's machine could not stand in for it. The `goldens/sprint-05b` branch
existed only to mint the files and was deleted afterwards.
