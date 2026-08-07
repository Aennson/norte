# Sprint 02 — Jira Integration: JiraLink, REST Adapter, Outbox, and Refresh

**Objective:** link tasks to Jira Cloud issues (external layer, never a mirror), with idempotent offline-first writes via outbox and status refresh on demand + in the background.

**Mandatory references:** `docs/architecture.md` §4 · BR-01, BR-02, BR-05, BR-08, BR-09

---

## Entry criteria

- [ ] Sprint 01 DoD complete.
- [ ] `FakeJiraGateway` available with issue fixtures (`test/fixtures/jira_issues.json`).

## Scope

**In:** `JiraGateway` port (getIssue, transitionIssue, addComment, createIssue, getStatus); `JiraRestAdapter` (dio, Basic auth with API token, Jira Cloud REST v3); credential storage in `flutter_secure_storage` + Jira configuration screen in Settings; `outbox` table in Drift + `OutboxDispatcher` (exponential retry, idempotency by `operationId`); use cases `LinkTaskToJira`, `UnlinkTask`, `UpdateJiraStatus`, `AddJiraComment`, `CreateJiraIssueFromTask`, `RefreshJiraStatus`; background refresh every 15 min (workmanager on mobile / timer+isolate on Windows) only for linked, non-completed tasks; UI: `JiraChip` on the task, `DivergenceBanner` for status conflict.

**Out:** OAuth, automatic bidirectional sync, mirroring Jira fields beyond the 4 in `JiraLink`.

## Sprint validation rules

- **BR-09:** `JiraLink` persists only `issueKey`, `siteUrl`, `lastKnownStatus`, `lastSyncedAt`. No other Jira column/field in the schema.
- **BR-05:** every Jira mutation (transition, comment, create) goes into the outbox; no direct write call from use case → adapter.
- **BR-02:** a status divergence is never resolved on its own; the banner offers "Keep local" / "Adopt from Jira".
- **BR-08:** token only in secure storage; dio logs redact the `Authorization` header and credential bodies.
- Outbox: exponential backoff 2s/4s/8s/16s (max 5 attempts); afterwards mark `failed` and show a UI indicator with a manual retry action.
- Linking a ticket requires online validation (`GET /issue/{key}`): nonexistent key → clear error; no network → "requires connection" error (the link is not queued).

## Tests

#### S02-UT-01 — Linking and unlinking preserves the task
- **What it validates:** BR-01.
- **Entry criteria:** existing local task; `FakeJiraGateway` with valid issue `PROJ-123`.
- **Action:** `LinkTaskToJira(task, "PROJ-123")`, then `UnlinkTask`.
- **Exit criteria:** after linking, `jiraLink.issueKey == "PROJ-123"` and the task's other fields are intact; after unlinking, `jiraLink == null` and the task still exists with its local title/status.

#### S02-UT-02 — Linking a nonexistent key
- **What it validates:** online link validation.
- **Entry criteria:** fake configured to return 404 for `NOPE-1`.
- **Action:** `LinkTaskToJira(task, "NOPE-1")`.
- **Exit criteria:** `JiraIssueNotFoundFailure`; task remains unlinked; nothing in the outbox.

#### S02-UT-03 — Mutations go to the outbox, never direct
- **What it validates:** BR-05.
- **Entry criteria:** linked task; spy fake gateway.
- **Action:** `UpdateJiraStatus(task, "Done")` **without** running the dispatcher.
- **Exit criteria:** 1 pending operation in the outbox with the correct payload; **zero** calls recorded on the gateway.

#### S02-UT-04 — Divergence detection
- **What it validates:** BR-02 (detection).
- **Entry criteria:** task with local status `done`, `lastKnownStatus = "In Progress"`; fake returns remote status `"To Do"`.
- **Action:** `RefreshJiraStatus(task)`.
- **Exit criteria:** the result flags a divergence (local ≠ remote); local status is **not** changed; `lastKnownStatus` updated to `"To Do"` and `lastSyncedAt` = clock.now.

#### S02-IT-01 — Outbox idempotency
- **What it validates:** BR-05 (idempotency by `operationId`).
- **Entry criteria:** in-memory Drift outbox with operation `op-1`; fake gateway counting calls.
- **Action:** dispatch; simulate a response timeout after server-side success (lost response); re-dispatch `op-1`.
- **Exit criteria:** the gateway applied the operation exactly once (the fake deduplicates by `operationId` and the test asserts 1 effective application); the operation ends `completed`, with no duplicate in the queue.

#### S02-IT-02 — Retry with backoff and final failure
- **What it validates:** the outbox retry policy.
- **Entry criteria:** fake gateway always returning 429; `FakeClock` controlling time.
- **Action:** dispatch one operation and advance the clock through the intervals.
- **Exit criteria:** attempts at offsets 0s/2s/4s/8s/16s (5 total); after the 5th, state `failed`; no further attempts without a manual retry.

#### S02-IT-03 — FIFO order per issue
- **What it validates:** consistency of sequential mutations.
- **Entry criteria:** outbox with a transition and a comment for the same issue, created in that order.
- **Action:** dispatch with the network up.
- **Exit criteria:** the gateway receives the transition before the comment.

#### S02-IT-04 — Credential redaction in logs
- **What it validates:** BR-08.
- **Entry criteria:** `JiraRestAdapter` with its log interceptor captured in memory; request with Basic auth.
- **Action:** execute `getIssue` against a fake HTTP server.
- **Exit criteria:** the log contains neither the token nor the `Authorization` header in plaintext (`[REDACTED]` appears instead).

#### S02-CT-01 — JiraGateway contract
- **What it validates:** `JiraRestAdapter` (against a fake server) and `FakeJiraGateway` obey the same contract.
- **Entry criteria:** parameterized suite receiving an adapter factory.
- **Action:** run the same cases (issue exists, 404, 401, 429, comment ok) on both adapters.
- **Exit criteria:** the same return types/failures for the same stimuli on both.

#### S02-GT-01 — JiraChip and DivergenceBanner
- **What it validates:** the Jira components in the design system (§4).
- **Entry criteria:** linked task with and without divergence.
- **Action:** render the task card in dark/light.
- **Exit criteria:** stable goldens; the banner uses the `warning` color and two decision buttons.

#### S02-E2E-01 — Offline → online flow
- **What it validates:** offline-first (BR-05) end to end.
- **Entry criteria:** app with a task linked to `PROJ-123`; fake gateway in "no network" mode.
- **Action:** through the UI, change status to Done (Jira action) → verify the "pending sync" indicator → restore the fake's network → wait for the dispatcher.
- **Exit criteria:** with the network down, the UI shows the pending state and nothing reaches the gateway; with the network up, the operation is applied once, the indicator disappears, `lastKnownStatus` reflects "Done".

#### S02-E2E-02 — Divergence decision
- **What it validates:** BR-02 in the UI.
- **Entry criteria:** local task `done`; fake with remote status "In Progress".
- **Action:** refresh through the UI → banner appears → choose "Adopt from Jira".
- **Exit criteria:** before the choice nothing changes; after it, the local status becomes `inProgress`; choosing "Keep local" (scenario B, repeated) keeps `done` and queues a transition in the outbox.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [ ] All S02-* tests passing; the CT contract runs for both adapters in CI.
- [ ] Manual test against a real Jira Cloud (test site): link, comment, transition — script and evidence in the report. **A real token is never committed.**
- [ ] Report `docs/reports/sprint-02-report.md`.
