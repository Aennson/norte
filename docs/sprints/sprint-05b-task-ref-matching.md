# Sprint 05b — Naming a Task Out Loud: Approximate `taskRef` Resolution

**Objective:** make a spoken task reference find the task the user meant when
the transcript spells it differently from the title — without ever acting on
the wrong row.

**Mandatory references:** `docs/architecture.md` §6.3.1 · BR-01, BR-04, BR-11 ·
DEC-035

**Why 05b and not part of 06.** This is a defect against Sprint 05a's
`taskRef` resolution, found by the Developer in manual use on 2026-08-09. Under
`docs/project-rules.md` §5.6 a discovered bug needs its regression test before
the fix, and under DEC-030's own reasoning two unrelated subjects in one sprint
means one Definition of Done that cannot fail cleanly — Sprint 06 is reminders
and notifications across three platforms. A small lettered sprint keeps this
failure's DoD its own.

---

## The defect

A task titled `HEROBRAZIL-762`. The user says "coloca a atividade Hero
Brazil-762 para o status de pronto". Scribe transcribes `Hero Brazil-762`, the
parse is correct, and the app answers **"No task called 'Hero Brazil-762'"**.

`TextMatch.fold` normalises case and accents, so the comparison is
`herobrazil-762`.contains(`hero brazil-762`) → false. **One space is the entire
cause.** Nothing was misheard and nothing was misparsed; the reference was
spelled the way a person spells an identifier out loud and the title was
spelled the way a tracker writes one.

The harder class the Developer described in the same report is a genuine
transcription difference — a Brazilian speaker saying "Hero Brasil" against a
title written `HEROBRAZIL`. That one needs approximation; the reported case
does not.

## Entry criteria

- [ ] Sprint 05a DoD complete and merged (PR #10).
- [ ] `TextMatch` in `domain/services/` with `fold` and `contains` (DEC-034).
- [ ] `IntentRouter._resolve` returning `TaskNotFound` / `TaskAmbiguous` /
      one task, with the exact-title tier already ahead of containment.

## Scope

**In:**

*Domain* — `TextMatch` gains `squash` (fold minus every non-alphanumeric rune),
`digitRuns`, and `similarity` (normalised Damerau–Levenshtein over `squash`).

*Application* — `IntentRouter._resolve` becomes the four-tier ladder of
§6.3.1: exact, containment, **squashed**, **approximate**. First tier that
yields exactly one task wins; a tie inside a tier is `TaskAmbiguous` as today.

*Presentation* — the outcome of a mutating local intent **names the row it
acted on**, so an approximate match is visible the moment it happens. New ARB
keys in all three languages (BR-11).

**Out:** phonetic matching (Soundex, Metaphone) · matching against the
description or tags · passing task titles to the model as context (DEC-035
rejects it) · any change to `queryTasks`, bulk operations or undo · any change
to how Jira intents identify their target — an issue key is exact and stays
exact.

## Sprint validation rules

- **Digits are never approximate.** If both the reference and a candidate carry
  digit runs and the sets differ, that candidate is excluded from tiers 3 and 4
  outright — it may still win tier 1 or 2 on an exact spelling.
- **The ladder is ordered and each tier is exhausted before the next.** An
  exact match must never be beaten by a better-scoring approximate one.
- **A tie is a question.** Inside the approximate tier the best score wins only
  if it clears the runner-up by the documented margin; otherwise
  `TaskAmbiguous`, listing the candidates.
- **A reference shorter than 4 squashed characters never reaches tier 4.**
  "PR" is not an approximation of anything.
- **`deleteTask` still confirms unconditionally**, however it resolved. This
  sprint does not touch that rule and must not weaken it.
- Every user-facing string comes from the ARB resources, in all three
  languages (BR-11).

## Parameters

Named constants on `TextMatch`, not literals at the call site, so a test can
state the threshold it is exercising:

| Constant | Value | Why |
|---|---|---|
| `similarityThreshold` | `0.82` | `herobrasil762` vs `herobrazil762` scores 0.923; a two-character difference in a thirteen-character reference scores 0.846 |
| `similarityMargin` | `0.08` | Below this gap between first and second, the app asks |
| `minApproximateLength` | `4` | Squashed characters |

A change to any of the three is a change to behaviour and needs S05b-UT-04
updated with it.

## Tests

#### S05b-UT-01 — The reported defect, as a regression test
- **What it validates:** the failure of 2026-08-09; `docs/project-rules.md`
  §5.6 requires this test before the fix.
- **Entry criteria:** a task titled `HEROBRAZIL-762`; an `updateTask` intent
  with `taskRef: "Hero Brazil-762"` and `status: "done"`.
- **Action:** route.
- **Exit criteria:** the task resolves and its status becomes `done`. **Not
  `TaskNotFound`.**

#### S05b-UT-02 — Separators are ignored, in both directions
- **What it validates:** tier 3, which is deterministic and needs no threshold.
- **Entry criteria:** titles `HEROBRAZIL-762` and `Ligar para Samara`; the
  references `hero brazil 762`, `HEROBRAZIL762`, `Hero-Brazil-762`, and
  `ligarparasamara`.
- **Action:** resolve each.
- **Exit criteria:** every one finds its task; no threshold is consulted, so
  the result does not depend on `similarityThreshold`.

#### S05b-UT-03 — A misheard letter still finds the task
- **What it validates:** tier 4.
- **Entry criteria:** title `HEROBRAZIL-762`; reference `Hero Brasil-762`
  (a Brazilian speaker's spelling of an English word).
- **Action:** resolve.
- **Exit criteria:** the task is found, and the outcome reports that it
  resolved approximately.

#### S05b-UT-04 — **Digits are not fuzzy**
- **What it validates:** the sprint's central safety rule. This is the test
  that has to pass before any of the others matter.
- **Entry criteria:** tasks `HEROBRAZIL-762` and `HEROBRAZIL-763`; the
  reference `Hero Brasil-763`.
- **Action:** resolve.
- **Exit criteria:** `HEROBRAZIL-763` and **only** it. `HEROBRAZIL-762` must be
  excluded from the approximate tier entirely, not merely out-scored — assert
  it is absent from the candidates, because both score identically under any
  edit-distance metric and an implementation that ranked them would pass a
  weaker assertion by luck.
- **Second scenario:** with only `HEROBRAZIL-762` stored and the reference
  `Hero Brazil-763`, the result is `TaskNotFound`. A one-digit difference is a
  different ticket, and answering "close enough" is how the wrong chamado gets
  closed.

#### S05b-UT-05 — A near tie asks rather than picking
- **What it validates:** `similarityMargin`.
- **Entry criteria:** tasks `Revisar o conector` and `Revisar o coletor`; the
  reference `revisar o conetor`.
- **Action:** resolve.
- **Exit criteria:** `TaskAmbiguous` naming both; no use case called.

#### S05b-UT-06 — Nothing close enough is still nothing
- **What it validates:** that the ladder did not become a fallback that always
  finds something.
- **Entry criteria:** tasks `Ligar para Samara` and `Revisar PR`; the reference
  `comprar café`.
- **Action:** resolve.
- **Exit criteria:** `TaskNotFound`, naming the phrase back, and nothing
  written.

#### S05b-UT-07 — A short reference never reaches the approximate tier
- **What it validates:** `minApproximateLength`.
- **Entry criteria:** tasks `Revisar PR` and `Preparar a demo`; the reference
  `PR`.
- **Action:** resolve.
- **Exit criteria:** tier 2 finds `Revisar PR` by containment. With only
  `Preparar a demo` stored, `PR` returns `TaskNotFound` rather than
  approximating its way to it.

#### S05b-UT-08 — The exact tier is never beaten by a better score
- **What it validates:** the ordering.
- **Entry criteria:** tasks `Ligar para Samara` and `Ligar para Samra` (a typo
  the user made when creating it); the reference `Ligar para Samara`.
- **Action:** resolve.
- **Exit criteria:** the exactly-titled task, with no question asked — even
  though the second is a very close approximate match.

#### S05b-UT-09 — `TextMatch.squash`, `digitRuns` and `similarity`
- **What it validates:** the three new domain functions on their own, so a
  router test failing is unambiguous about which layer is wrong.
- **Entry criteria:** a table of pairs including the accents `fold` already
  handles.
- **Exit criteria:** `squash('Hero Brazil-762') == 'herobrazil762'`;
  `digitRuns('HEROBRAZIL-762') == {'762'}`; `digitRuns('Ligar para Samara')`
  is empty; `similarity` is symmetric, is `1.0` for identical input, and is
  `0.0` for disjoint input.

#### S05b-GT-01 — The outcome names the row
- **What it validates:** the presentation rule.
- **Entry criteria:** the voice overlay after an `updateTask` that resolved
  approximately.
- **Action:** render dark/light.
- **Exit criteria:** stable goldens in which the line reads "Task updated:
  HEROBRAZIL-762" rather than "Task updated".

#### S05b-E2E-01 — The Developer's session, end to end
- **What it validates:** the defect, through the real app.
- **Entry criteria:** app with fakes; a task titled `HEROBRAZIL-762` in
  progress; the utterance "coloca a atividade Hero Brazil-762 para o status de
  pronto".
- **Action:** voice command.
- **Exit criteria:** the card shows `DONE`, and the overlay names
  `HEROBRAZIL-762` back.

#### S05b-E2E-02 — Deletion by an approximate reference still asks
- **What it validates:** that the ladder did not weaken BR-04's floor.
- **Entry criteria:** a task titled `HEROBRAZIL-762`; "apaga a atividade Hero
  Brasil-762" at 0.98.
- **Action:** voice command.
- **Exit criteria:** the confirmation sheet appears, names `HEROBRAZIL-762`
  (the title, not the phrase), and the task survives a cancellation.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [ ] All S05b-* tests passing.
- [ ] The eval dataset carries at least three rows whose `taskRef` is spelled
      differently from any plausible title, and the thresholds still hold.
- [ ] Report `docs/reports/sprint-05b-report.md`, including a **manual pass**
      against the real Scribe: the defect was found by a person speaking, and
      no fake can confirm the fix for the same reason no fake found the bug
      (`sprint-05` report §5).
