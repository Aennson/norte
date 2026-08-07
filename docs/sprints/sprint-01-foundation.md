# Sprint 01 — Foundation: Domain, Persistence, and Local Tasks CRUD

**Objective:** implement the domain model, Drift persistence, and the complete **100% local** task CRUD (no Jira), with a functional Tasks screen in the design system.

**Mandatory references:** `docs/architecture.md` §3, §11 · `docs/design-system.md` §4 · BR-01

---

## Entry criteria

- [ ] Sprint 00 DoD complete (green CI, theme and components ready).
- [ ] Sprint 00 fakes and fixtures available.

## Scope

**In:** domain entities (`Task`, `JiraLink`, `Meeting`, `MeetingTemplate`, `Reminder`, `VoiceIntent` — all of them, even though only `Task` is used now) with `freezed`; enums (`TaskStatus`, `Priority`, `MeetingType`, `IntentType`, `RetentionPolicy`); `Failure` sealed classes; `TaskRepository` and `NotificationScheduler` ports (interface only); Drift schema + `DriftTaskRepository`; use cases `CreateTask`, `UpdateTask`, `DeleteTask`, `ListTasks` (filter by status/tag, sort by priority/dueDate); complete Tasks screen (list, create, edit, complete, delete, filter) with the 4 mandatory states.

**Out:** any Jira code (the `JiraLink` entity exists, but no usage), AI, voice, meetings.

## Sprint validation rules

- Immutable entities; changes via `copyWith` returning a new instance with `updatedAt` refreshed by the use case (not by the entity).
- `Task.id` is a UUID v4 generated in the use case; `createdAt`/`updatedAt` via injected clock (testable).
- The repository exposes a reactive `Stream<List<Task>>` (Drift watch) — the UI never polls.
- Task deletion asks for confirmation in the UI (destructive action, design system `error` button).
- No Drift access outside `infrastructure/persistence/`.

## Tests

#### S01-UT-01 — Valid Task creation
- **What it validates:** BR-01 (task is independent of Jira) and correct defaults.
- **Entry criteria:** `CreateTask` with mocked repository and pinned `FakeClock`.
- **Action:** execute with title "Review PR".
- **Exit criteria:** task persisted with `status = todo`, `jiraLink == null`, `createdAt == updatedAt == clock.now`, valid UUID v4 id.

#### S01-UT-02 — Title is required
- **What it validates:** use case input validation.
- **Entry criteria:** mocked `CreateTask`.
- **Action:** execute with an empty title and a whitespace-only title.
- **Exit criteria:** returns `ValidationFailure`; the repository is **not** called.

#### S01-UT-03 — Update preserves creation
- **What it validates:** `updatedAt` semantics/immutability.
- **Entry criteria:** existing task with `createdAt = T0`; clock at `T1 > T0`.
- **Action:** `UpdateTask` changing status to `inProgress`.
- **Exit criteria:** `createdAt == T0`, `updatedAt == T1`, remaining fields preserved.

#### S01-UT-04 — ListTasks filter and sorting
- **What it validates:** listing rules.
- **Entry criteria:** mocked repository with 5 tasks of varied statuses/priorities/dueDates.
- **Action:** list with filter `status = todo` and priority sorting.
- **Exit criteria:** only `todo` tasks, sorted priority desc; ties broken by `dueDate` asc, nulls last.

#### S01-IT-01 — Drift round-trip
- **What it validates:** entity ↔ table mapping without loss.
- **Entry criteria:** `DriftTaskRepository` with in-memory database.
- **Action:** save a task with every field populated (incl. tags and `jiraLink`), read it back.
- **Exit criteria:** the read object equals (==) the saved one, including tags in order and dates with millisecond precision.

#### S01-IT-02 — Reactive stream
- **What it validates:** reactive UI without polling.
- **Entry criteria:** empty in-memory database; `watchAll()` stream under subscription.
- **Action:** insert, update, and delete a task.
- **Exit criteria:** the stream emits after each mutation with the correct state (3 emissions beyond the initial one).

#### S01-IT-03 — Idempotent delete
- **What it validates:** repository robustness.
- **Entry criteria:** database with 1 task.
- **Action:** delete the same task twice.
- **Exit criteria:** the first removes it; the second throws no error and affects no other rows.

#### S01-GT-01 — Tasks screen in the 4 states
- **What it validates:** design system §6 (loading skeleton, empty, error, content).
- **Entry criteria:** providers overridden to force each state.
- **Action:** render in dark and light, mobile and desktop.
- **Exit criteria:** stable goldens; empty state uses `EmptyState`; cards use `NorteCard`/`StatusBadge`.

#### S01-E2E-01 — Full CRUD through the UI
- **What it validates:** the user flow end to end with real (in-memory) persistence.
- **Entry criteria:** app started with in-memory Drift, empty list.
- **Action:** create task "Buy coffee" (high priority) → edit title to "Buy specialty coffee" → mark as done → delete (confirming the dialog).
- **Exit criteria:** each step reflects on screen immediately; after creation the task exists in the database; after deletion the list shows `EmptyState` and the database is empty.

#### S01-E2E-02 — Deletion cancelled
- **What it validates:** destructive action confirmation.
- **Entry criteria:** app with 1 task.
- **Action:** start deletion and cancel in the dialog.
- **Exit criteria:** the task remains in the list and in the database.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [ ] All S01-* tests passing; goldens committed.
- [ ] Tasks persist across app restarts (manual verification recorded in the report).
- [ ] Report `docs/reports/sprint-01-report.md` with evidence.
