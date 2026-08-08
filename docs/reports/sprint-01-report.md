# Sprint 01 — Foundation: Domain, Persistence, and Local Tasks CRUD · Report

**Branch:** `claude/fase-dois-aco-427fc6` (see DEC-009) · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Pro 26200 (Developer's machine) · **CI:** `ubuntu-latest`

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 00 DoD complete (green CI, theme and components ready) | `docs/reports/sprint-00-report.md` closes every box; PR #1 merged into `master` with all three Actions jobs green | ✅ |
| Sprint 00 fakes and fixtures available | `test/fakes/` ships `FakeClock`, `FakeAiEngine`, `FakeJiraGateway`, `FakeNotificationScheduler` and both transcription fakes, exported from `test/fakes/fakes.dart` | ✅ |

## 2. Quality gates

Every command run at `HEAD` of the sprint branch, on the Developer's Windows machine.

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 9.0s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --output=none --set-exit-if-changed .` | exit 0 ✅ |
| G3 — tests | `flutter test` | `00:11 +125: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **93.4%** (113/121) · project **88.7%** (962/1084) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match ✅ |
| E2E | `flutter test integration_test/<suite> -d windows` | navigation smoke `+2`, tasks CRUD `+3` — 5/5 scenarios passing ✅ |

Coverage excludes machine-generated sources (DEC-008); the excluded group is
printed on every run as `generated (excl.) 252/708`.

## 3. Documented tests

| ID | Behaviour | Cases | Result |
|---|---|---|---|
| S01-UT-01 | Valid task creation — BR-01, defaults, pinned clock, UUID v4 | 3 | ✅ |
| S01-UT-02 | Title is required; repository untouched on rejection | 3 (+9 on `Result`/`Failure`) | ✅ |
| S01-UT-03 | Update preserves `createdAt`, refreshes `updatedAt` | 4 | ✅ |
| S01-UT-04 | `ListTasks` filter and sorting | 6 | ✅ |
| S01-IT-01 | Drift round-trip with every field populated | 3 | ✅ |
| S01-IT-02 | Reactive stream — 3 emissions beyond the initial one | 1 | ✅ |
| S01-IT-03 | Idempotent delete | 2 | ✅ |
| S01-GT-01 | Tasks screen in the 4 states, dark+light, mobile+desktop | 16 goldens + 10 widget cases | ✅ |
| S01-E2E-01 | Full CRUD through the UI | 2 | ✅ |
| S01-E2E-02 | Deletion cancelled | 2 | ✅ |

**125 tests, 0 skipped, 0 weakened.** No documented case was removed or relaxed.

### Notes on specific exit criteria

- **S01-UT-01** — `task.id` is asserted against the canonical UUID v4 pattern
  (`[0-9a-f]{8}-…-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-…`), not merely "non-empty".
  `createdAt == updatedAt == clock.now` holds exactly: both use cases stamp
  `clock.now().toUtc()`, and `FakeClock.fixed()` is already UTC.
- **S01-IT-01** — the fixture carries non-zero milliseconds in all four
  timestamps. Drift's default `DateTime` column stores whole seconds, which
  would have truncated them silently, so the schema stores epoch milliseconds
  as integers instead. Equality is asserted on the whole entity (`read == saved`),
  with the individually loseable fields — tag order, Jira link, millisecond
  components — named separately.
- **S01-IT-02** — exactly 4 emissions: the initial empty state plus insert,
  update and delete, each asserted for content, not just for arrival.
- **S01-GT-01** — the four states are rendered through the **real** `TasksScreen`
  with the repository replaced at the same override point the composition root
  uses, at 390×844 and 1280×800 in both themes. Empty uses `EmptyState`; the
  cards use `NorteCard` and `StatusBadge`.

## 4. Sprint validation rules

| Rule | How it is met |
|---|---|
| Immutable entities; `copyWith` refreshes `updatedAt` in the use case | `Task` is `freezed`; `UpdateTask` sets `updatedAt: clock.now().toUtc()`. S01-UT-03 asserts the original instance is unchanged. |
| `Task.id` is a UUID v4 from the use case; timestamps via injected clock | `IdGenerator` port + `UuidV4Generator` (`Random.secure`, version and variant bits pinned). No entity calls `DateTime.now()`. |
| Reactive `Stream<List<Task>>`; the UI never polls | `TaskRepository.watchAll()` → Drift `watch()` → `ListTasks` → `taskListProvider`. No timer or refresh call anywhere in `presentation/`. |
| Deletion asks for confirmation with the `error` button | `DeleteTaskDialog` + `NorteButtonVariant.destructive`; S01-E2E-02 proves cancelling keeps the row. |
| No Drift access outside `infrastructure/persistence/` | Gate G5 green; `presentation/tasks/task_providers.dart` declares `taskRepositoryProvider` as unimplemented and `main.dart` supplies the adapter. |

## 5. Persistence across restarts

The E2E and integration suites use an in-memory database, so the DoD's restart
requirement is evidenced in three layers.

**Automated — `test/infrastructure/database_restart_test.dart`.** A task with
every field populated is written through `DriftTaskRepository` to a real file,
the database is closed, and a **new** `NorteDatabase` is opened over the same
file — the exact sequence `openNorteDatabase()` performs on each launch. The
task reads back equal to what was written, and a deletion likewise survives the
reopen. This covers the storage path, which is where the risk actually lives.

```
00:00 +2: All tests passed!
```

**Automated — the app creates its database.** `flutter build windows --debug`
succeeds and the launched executable creates the file at the platform's
application-support directory:

```
√ Built build\windows\x64\runner\Debug\norte.exe
…\com.aennson\norte\norte.sqlite
```

**Manual — the app-level pass.** Script, in the format of
`docs/testing-strategy.md` §7:

- **Entry:** the built Windows app, launched with no `norte.sqlite` present.
- **Action:** create three tasks (one urgent with tags, one with a due date, one
  in progress), mark one done, close the window, relaunch.
- **Exit:** all three reappear with their status, priority, due date and tags
  intact; the completed one still shows the `done` badge and struck-through
  title.

> ⏳ **Pending the Developer's pass.** This is the one Definition-of-Done box
> the executing AI cannot check for itself — it needs a human at the window.
> The box in §7 stays unticked, and the sprint stays open, until the result is
> recorded here.

## 6. Deviations

Four decisions were recorded in `docs/reports/decisions.md`; none weakens a
documented criterion.

| ID | Summary |
|---|---|
| DEC-008 | Machine-generated sources excluded from gate G4. Thresholds unchanged at 90%/80%; counting `drift_dev`'s output made the gate unreachable at any level of real testing. |
| DEC-009 | Sprint developed on the environment-pinned branch, as in DEC-003. |
| DEC-010 | The CI E2E job runs one `flutter test` per file — the desktop launcher cannot start a second app while the first is exiting. |
| DEC-011 | The Linux golden set is minted by a dedicated workflow on the CI runner, the only Linux whose font stack matches what CI compares against. |

**No scope was left undone**, and nothing from a future sprint was implemented:
the `JiraLink` entity exists and round-trips, but no code reads or writes Jira.

## 7. Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%
- [ ] All S01-* tests passing; goldens committed
- [ ] Tasks persist across app restarts (§5)
- [ ] Report with evidence
- [ ] GitHub Actions 100% green on the sprint PR
