# Sprint 05a — Task Commands: Local Intents, Rich Creation, Filters and Search

**Objective:** make the app's own task list fully operable by voice — create
with every attribute, change status, comment, delete under confirmation — and
give the Tasks screen the multi-status filter and description search that make
a growing list usable.

**Mandatory references:** `docs/architecture.md` §3.1, §4, §6.3 · BR-01, BR-04,
BR-05, BR-11

**Why 05a and not 06.** Sprint 05 is complete against its own documented scope
and its PR is green; Sprints 06–08 are already specified and 09 opens v1.1, so
there is no free number before the v1.0 boundary. A lettered sprint keeps the
execution order unambiguous without renumbering documents that other files
reference (DEC-030).

---

## Entry criteria

- [x] Sprint 05 DoD complete and merged.
- [x] `IntentParser`, `IntentRouter` and the `ConfirmSheet` in place, with the
      continuous-listening session of DEC-031.
- [x] `TaskQuery.statuses` already a set (it is — the application layer has
      supported multiple statuses since Sprint 01; only the UI restricted it).

## Scope

**In:**

*Domain and application* — `TaskComment` on `Task` (§3.1) with a Drift table
and schema 5; `UpdateTask` extended to accept status, priority, title,
description and due date individually; `DeleteTask` reused; `CommentTask` use
case; `TaskQuery.search` matching **title and description**, and `ListTasks`
honouring it.

*Voice* — four local intents (`updateTask`, `deleteTask`, `commentTask`, and
`createTask` carrying `description` and `status`), the `taskRef` resolution of
§6.3.1, the status and priority vocabularies of §6.3.2, and routing that
prefers a local intent when Jira is not named.

*Presentation* — `TaskFilterBar` becomes multi-select; `TaskSearchField` added;
both wired to `TaskQuery`.

**Out:** listing or reading tasks aloud (`queryTasks`), bulk operations
("apaga todas as concluídas"), undo, and any change to the Jira intents.

## Sprint validation rules

- **BR-01 holds throughout.** None of the four local intents touches Jira, and
  a `TaskComment` is never pushed to a linked issue (§3.2). A user who wants
  that says "comenta no PROJ-123", which is `addComment` and goes through the
  outbox (BR-05).
- **Jira is opt-in by naming.** An utterance carrying neither an issue key nor
  the word "Jira" may not produce a Jira intent. Ambiguity resolves to the
  local intent.
- **`deleteTask` always confirms**, at any confidence. BR-04's threshold is a
  floor here, not a gate: a deletion the user did not mean has no undo in v1.0.
- **`taskRef` never guesses.** Several matches is a question listing them; no
  match changes nothing and says so (§6.3.1).
- `status` and `priority` arrive as domain enum names, never as translations.
- Filters compose: two active status chips show the union, and the search
  narrows whatever the chips left.
- An empty search result and an empty database use **different** wording
  (`docs/design-system.md` §4).

## Tests

#### S05a-UT-01 — Rich creation from one utterance
- **What it validates:** §6.3, the sprint's headline example.
- **Entry criteria:** `FakeAiEngine` returning `createTask` with
  `{title: "Ligar para Samara", description: "confirmar o orçamento",
  status: "inProgress", priority: "urgent"}` at 0.95.
- **Action:** route the intent.
- **Exit criteria:** one task created carrying **all four** attributes; no
  confirmation sheet (a local intent above the threshold executes).

#### S05a-UT-02 — Status and priority vocabularies
- **What it validates:** §6.3.2.
- **Entry criteria:** intents whose `status` slot is each of `todo`,
  `inProgress`, `done`, `blocked`, and whose `priority` is each of `low`,
  `medium`, `high`, `urgent`.
- **Action:** route each.
- **Exit criteria:** every value maps to its domain enum; an unrecognised
  value is treated as absent rather than defaulted silently.

#### S05a-UT-03 — `taskRef` resolves to exactly one task
- **What it validates:** §6.3.1, cases 1 and 3.
- **Entry criteria:** tasks "Ligar para Samara" and "Revisar PR"; intents
  referring to "samara" (differing in case and accent) and to "nada disso".
- **Action:** route both.
- **Exit criteria:** the first updates the Samara task; the second returns a
  "no such task" result and **writes nothing**.

#### S05a-UT-04 — Ambiguous `taskRef` asks rather than guesses
- **What it validates:** §6.3.1, case 2.
- **Entry criteria:** tasks "Ligar para Samara" and "Ligar para Samara de
  novo"; an `updateTask` intent referring to "ligar para samara".
- **Action:** route.
- **Exit criteria:** a result naming **both** candidates, no use case called;
  answering with one of them completes the command.

#### S05a-UT-05 — Deletion always confirms
- **What it validates:** the sprint's deletion rule.
- **Entry criteria:** `deleteTask` at 0.99 and at 0.40 (2 scenarios).
- **Action:** route each.
- **Exit criteria:** both return `ConfirmationRequired`; the repository is
  untouched until confirmation; confirming deletes exactly one task.

#### S05a-UT-06 — A local comment never reaches Jira
- **What it validates:** BR-01, §3.2.
- **Entry criteria:** a task **linked** to PROJ-123; a `commentTask` intent.
- **Action:** route.
- **Exit criteria:** the comment is on the task; **the outbox is empty** and
  the Jira gateway was never called.

#### S05a-UT-07 — Jira is not chosen without being named
- **What it validates:** the opt-in rule.
- **Entry criteria:** the eval dataset's local utterances, none of which names
  a key or says Jira.
- **Action:** parse each through the real prompt with `FakeAiEngine` fixtures.
- **Exit criteria:** none produces `updateJira`, `addComment` or `queryStatus`.

#### S05a-UT-08 — Filters compose
- **What it validates:** the multi-status rule.
- **Entry criteria:** tasks across all four statuses; a query with
  `{todo, blocked}` and the search term "ligar".
- **Action:** run `ListTasks`.
- **Exit criteria:** only todo-or-blocked tasks whose title **or description**
  contains "ligar"; order unchanged by filtering.

#### S05a-UT-09 — Search reads the description too
- **What it validates:** the search rule.
- **Entry criteria:** a task whose title does not contain "orçamento" and
  whose description does.
- **Action:** search "orçamento".
- **Exit criteria:** the task is found; the match is case- and
  accent-insensitive.

#### S05a-IT-01 — Comments survive a round-trip
- **What it validates:** schema 5.
- **Entry criteria:** in-memory Drift; a task with three comments.
- **Action:** save, read back, delete the task.
- **Exit criteria:** comments return in insertion order with their timestamps;
  deleting the task removes its comments and nothing else.

#### S05a-GT-01 — Filter bar and search field
- **What it validates:** `docs/design-system.md` §4.
- **Entry criteria:** bar with two chips active; search field with text; the
  "nothing matched" empty state.
- **Action:** render dark/light.
- **Exit criteria:** stable goldens; an active chip is visibly distinct from
  an inactive one; the two empty states read differently.

#### S05a-E2E-01 — "cria a atividade Ligar para Samara…" (spoken in PT-BR)
- **What it validates:** the headline requirement, end to end.
- **Entry criteria:** app with fakes; the full utterance with title,
  description, status and priority.
- **Action:** voice command.
- **Exit criteria:** the task appears in the list with all four attributes
  visible; no confirmation sheet.

#### S05a-E2E-02 — Change, comment, then delete the same task by voice
- **What it validates:** the local intents together, in one continuous session.
- **Action:** three commands spoken without pressing the button again.
- **Exit criteria:** status changed, comment attached, deletion confirmed
  through the sheet; cancelling the deletion (scenario B) leaves the task.

## Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [x] All S05a-* tests passing.
- [x] The eval dataset extended with the local intents, still ≥ 90% / ≥ 85%.
- [x] Report `docs/reports/sprint-05a-report.md`.
