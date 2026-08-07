# Norte — Mandatory Project Rules

> **This document is law.** Every sprint, every task, and every test must obey these rules.
> The executing AI must re-read this file before starting any sprint.

---

## 1. Sprint execution flow

1. Sprints are executed **in order** (`sprint-00` → `sprint-08`). No sprint starts until the previous one has its **Definition of Done (DoD) 100% fulfilled**.
2. Each sprint has **Entry Criteria** (verifiable preconditions) and **Exit Criteria** (DoD). Both are objective checklists — there is no subjective interpretation.
3. At the end of each sprint, produce a report in `docs/reports/sprint-XX-report.md` containing:
   - DoD checklist with evidence (command executed + result).
   - Output of `flutter test --coverage` (percentage per layer).
   - List of deviations/pending items (if any exist, the sprint is **not** complete).
4. Small, frequent commits, message format: `sprint-XX: <imperative description>`, following the authorship rules in §7.1.
5. All work follows the **mandatory Git workflow in §7** — one branch/worktree per feature and a PR with 100% green CI at the end of each sprint. This is a **project premise**, not a suggestion.

## 2. Quality gates (mandatory in EVERY sprint)

A sprint is only considered delivered if **all** of the commands below pass without errors:

| Gate | Command | Acceptance criterion |
|---|---|---|
| G1 — Static analysis | `flutter analyze` | 0 errors, 0 warnings |
| G2 — Formatting | `dart format --set-exit-if-changed .` | exit code 0 |
| G3 — Tests | `flutter test` | 100% of tests passing |
| G4 — Coverage | `flutter test --coverage` | domain+application ≥ 90%; project ≥ 80% |
| G5 — Dependency rule | script `tool/check_imports.dart` (created in sprint 00) | no illegal imports between layers |
| G6 — Secrets | search for tokens/keys in code (`grep -rE "(api[_-]?key|token)\s*=\s*['\"]"` in `lib/`) | no hardcoded secrets |

## 3. Layer dependency rule (Clean Architecture)

```
presentation ──> application ──> domain <── infrastructure
```

- `domain/` **imports nothing** outside `domain/` (except Dart core and freezed).
- `application/` imports only `domain/`.
- `infrastructure/` imports `domain/` (implements the ports). It **never** imports `presentation/` or `application/`.
- `presentation/` imports `application/` and `domain/` (entities). It **never** imports `infrastructure/` directly — the wiring happens only in the composition root (`main.dart` / providers).
- An import violation = build rejected at gate G5.

## 4. Inviolable business rules

These rules come from the architecture (`docs/architecture.md`) and **must each have an automated test covering them**:

| ID | Rule | Mandatory test in |
|---|---|---|
| BR-01 | `Task` exists independently of Jira; `JiraLink` is optional and removable | Sprints 01 and 02 |
| BR-02 | A local ≠ Jira status conflict is **never** resolved automatically; the UI shows the divergence and asks for a decision | Sprint 02 |
| BR-03 | A transcript with `retention = ephemeral` lives only in memory; leaving the screen discards it (only an explicitly saved summary persists) | Sprint 03 |
| BR-04 | A `VoiceIntent` with `confidence < 0.75` requires explicit confirmation before any mutating action | Sprint 05 |
| BR-05 | Jira writes **always** go through the outbox (never a direct call from the UI) and are idempotent by `operationId` | Sprint 02 |
| BR-06 | Voice audio (commands/reminders) is discarded immediately after confirmed transcription; never written to disk in realtime flows | Sprints 05 and 06 |
| BR-07 | PII (CPF, phone, e-mail — BR patterns) is redacted before sending to any external API; redaction may be disabled only if `AiEngine.capabilities.isLocal == true` | Sprints 03 and 08 |
| BR-08 | Secrets (Jira token, Claude key) live only in secure storage; never in Drift, SharedPreferences, or logs | Sprint 02 onward |
| BR-09 | The app never mirrors Jira: it stores only `issueKey`, `siteUrl`, `lastKnownStatus` (display cache), and `lastSyncedAt` | Sprint 02 |
| BR-10 | Primary AI engine failure: 1 retry → fallback (if enabled) → clear error to the user; every switch is logged | Sprint 07 |

## 5. Testing rules

1. **Every test case documented in the sprints has a unique ID** (e.g.: `S02-UT-03`), and the test code must reference the ID in its name:
   `test('S02-UT-03: outbox does not duplicate an operation with the same operationId', ...)`.
2. Mandatory format for every test case (documented before implementation):
   - **Entry criteria** — state/fixtures required before execution.
   - **Steps/action** — what is executed.
   - **Exit criteria** — observable result that defines approval.
   - **What is being validated** — the rule/behavior covered.
3. **Test types and ID naming:**
   - `UT` unit (domain/application, ports mocked with `mocktail`).
   - `CT` contract (same suite applied to all adapters of a port).
   - `IT` integration (real in-memory Drift, fake HTTP servers).
   - `GT` golden (main screens, `flutter_test` golden files).
   - `E2E` end-to-end (`integration_test/`, real app with fake adapters injected at the composition root).
4. **E2E never calls real APIs.** Fake adapters (`FakeAiEngine`, `FakeJiraGateway`, `FakeTranscriptionEngine`) are injected via Riverpod overrides and respond with deterministic fixtures defined in `test/fixtures/`.
5. Tests must not depend on the network, the real clock (use `clock`/injected `DateTime.now`), or execution order.
6. A discovered bug = a new regression test before the fix.

## 6. Code rules

- Dart 3.x, strict null-safety, `freezed` for immutable domain entities.
- No `dynamic` in public signatures (except `VoiceIntent.slots`, defined by the architecture).
- Domain errors modeled as `Failure` sealed classes in `domain/failures/` — never throw raw exceptions across layers.
- Every port (`abstract interface class`) documented with dartdoc describing its contract, possible errors, and guarantees.
- Structured logs with automatic redaction of sensitive payloads (never log transcripts, tokens, keys, or AI request bodies).
- UI strings in PT-BR for this v1.0 (the product's target language), centralized (prepared for future l10n).

## 7. Mandatory Git workflow — branches, worktrees, PRs, and 100% CI

> **Project premise: everything 100%.** No merge happens with any failing test, any warning,
> any red gate, or any pending Actions job. There is no such thing as a "merge with caveats".

### 7.1 Branches and authorship

1. **`master` is the main, protected branch.** Never commit directly to `master` — all code arrives via Pull Request.
2. **Commit authorship:** every commit is authored by the **Developer** (`Aennson <aennson@gmail.com>` — set `git config user.name/user.email` at the start of each session). The AI assistant participates as a **contributor** via a trailer at the end of the message:
   ```
   Co-Authored-By: <AI name> <AI noreply email>
   ```
3. Branch naming:
   - Sprint: `sprint-XX/<slug>` (e.g.: `sprint-02/jira`)
   - Feature within the sprint: `feature/sprint-XX-<slug>` (e.g.: `feature/sprint-02-outbox`)

### 7.2 Worktrees — one per feature

**Every new feature must be developed on a separate branch created as a worktree**, to speed up verification (it allows running `flutter analyze`/`flutter test` in one worktree while developing in another, without switching branches or dirtying the main directory):

```bash
# open the sprint worktree from master
git worktree add ../norte-sprint-XX -b sprint-XX/<slug> master

# sprint features: worktrees created from the sprint branch
git worktree add ../norte-feat-<slug> -b feature/sprint-XX-<slug> sprint-XX/<slug>

# when the feature is complete: merge into the sprint branch and remove the worktree
git worktree remove ../norte-feat-<slug>
```

Rules:
- The repository's main directory stays on `master`; development **always** happens in the worktrees.
- Feature complete = gates G1–G6 green **inside the worktree** before merging into the sprint branch.
- Worktrees are removed after the merge (do not accumulate dead worktrees; `git worktree prune` at the end of the sprint).

### 7.3 Pull Request at the end of each sprint

1. At the end of each sprint, open **one PR** from the `sprint-XX/<slug>` branch to `master`.
2. The PR description must contain: the delivered scope, the completed DoD checklist, and a link to the report `docs/reports/sprint-XX-report.md` (committed on the branch itself).
3. **Merging is only allowed when GitHub Actions is 100% green** — all CI workflow jobs (analyze, format, check_imports, tests + coverage, goldens, E2E) approved, no exception, no `skip`, and no re-run masking a flake (a flaky test is a bug: fix it before merging).
4. Actions failed → fix on the sprint branch itself and wait for a new green run. The sprint is **not complete** while the PR is not mergeable with 100% CI.
5. After the merge, the next sprint starts from an updated `master` (`git fetch && git worktree add ... master`).

## 8. What the executing AI must NOT do

- ❌ Implement functionality from a future sprint ("while I'm at it...").
- ❌ Skip a documented test or mark it `skip` to close a sprint.
- ❌ Replace dependencies defined in the stack (`docs/architecture.md §2.1`) without recording the decision in `docs/reports/decisions.md`.
- ❌ Call real APIs in tests or commit keys/fixtures containing real data.
- ❌ Resolve a local×Jira conflict automatically (violates BR-02).
- ❌ Persist an ephemeral transcript or voice audio (violates BR-03/BR-06).
