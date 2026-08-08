# Sprint 02 — Jira Integration: JiraLink, REST Adapter, Outbox, and Refresh · Report

**Branch:** `claude/proxima-fase-e56000` (see DEC-013) · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Pro 26200 (Developer's machine) · **CI:** `ubuntu-latest`

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 01 DoD complete | `docs/reports/sprint-01-report.md` §7 closes every box; the manual persistence pass of §5 was executed by the Developer on 2026-08-07 and passed; PR #3 merged into `master` with all six checks `SUCCESS` | ✅ |
| `FakeJiraGateway` available with issue fixtures | `test/fakes/fake_jira_gateway.dart` + `test/fixtures/jira_issues.json` (4 synthetic issues, no real project or site) | ✅ |

## 2. Quality gates

Every command run at `HEAD` of the sprint branch, on the Developer's Windows machine.

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 4.3s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --output=none --set-exit-if-changed .` | exit 0 ✅ |
| G3 — tests | `flutter test` | `00:20 +287: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **96.4%** (242/251) · project **91.4%** (1826/1997) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match ✅ |
| E2E | `flutter test integration_test/<suite> -d windows`, one per file (DEC-010) | 4 suites, 11 scenarios, all passing ✅ |

Coverage excludes machine-generated sources (DEC-008).

**No real credential is anywhere in the tree.** The Developer supplied a token
during the sprint; it was neither stored nor committed, and the Developer was
advised to revoke it. Every fixture and test credential is synthetic
(`synthetic-token`, `dev@example.com`, `example.atlassian.net`).

## 3. Documented tests

| ID | Behaviour | Cases | Result |
|---|---|---|---|
| S02-UT-01 | Linking and unlinking preserve the task — BR-01, BR-09 | 11 | ✅ |
| S02-UT-02 | A nonexistent key, no network, a blank key — none of them queue anything | (same file) | ✅ |
| S02-UT-03 | Every mutation reaches the outbox and nothing else — BR-05 | 12 | ✅ |
| S02-UT-04 | Divergence detected, never resolved — BR-02 | 9 | ✅ |
| S02-IT-01 | Outbox idempotency across a lost response — BR-05 | 15 | ✅ |
| S02-IT-02 | Backoff schedule and final failure, then manual retry | (same file) | ✅ |
| S02-IT-03 | FIFO per issue, including within one millisecond | (same file) | ✅ |
| S02-IT-04 | Credential redaction in logs — BR-08 | 18 | ✅ |
| S02-CT-01 | `JiraGateway` contract across 3 subjects | 12 declared → **30 executed** | ✅ |
| S02-GT-01 | `JiraChip` and `DivergenceBanner`, dark + light | 8 declared → **12 executed** (8 goldens) | ✅ |
| S02-E2E-01 | Offline → online, through the UI | 3 | ✅ |
| S02-E2E-02 | Divergence decision, both ways | 3 | ✅ |

Plus 53 undocumented cases added for cover and regression (the Jira actions,
the settings form, the status mapping, the credential redaction) — the
strategy permits adding, never removing (`docs/testing-strategy.md` §2.4).

**287 tests, 0 skipped, 0 weakened.**

### Notes on specific exit criteria

- **S02-IT-02** — the sprint states the retry policy twice, as "backoff
  2s/4s/8s/16s (max 5 attempts)" and as "attempts at offsets 0s/2s/4s/8s/16s
  (5 total)". Both describe the same schedule read as *offsets from the
  previous attempt*, and that is what is implemented and asserted: the test
  walks a pinned clock one second at a time for a minute and records the gap
  between consecutive attempts, giving exactly `[0s, 2s, 4s, 8s, 16s]`.
- **S02-IT-01** — the fake applies the write and *then* throws, which is what
  a lost response looks like from the client. The re-dispatch reuses the same
  `operationId`; the gateway records one effective application, and the queue
  ends with one `completed` row rather than two.
- **S02-CT-01** — three subjects, not two: `FakeJiraGateway`, the REST adapter
  configured as Cloud, and the REST adapter configured as Data Center
  (DEC-012). The REST subjects run against a real loopback HTTP server, so the
  suite exercises URL building, headers, status classification and JSON
  reading rather than a mock's opinion of them.
- **S02-GT-01** — the diverging card golden is the one that matters: it is
  what stops the banner quietly turning into something that resolves itself.
- **S02-E2E-01/02** — both boot the real composition root with only the
  database and the gateway replaced, and every step asserts the user-visible
  effect *and* the stored one (`docs/testing-strategy.md` §4.4).

## 4. Sprint validation rules

| Rule | How it is met |
|---|---|
| **BR-09** — only 4 Jira fields persisted | `JiraLink` is unchanged from Sprint 01; the schema holds four nullable columns and no others. `RefreshJiraStatus` keeps the status name and discards everything else the site returns. |
| **BR-05** — every mutation through the outbox | The three write use cases hold an `OutboxRepository` and no gateway; they *cannot* call Jira. S02-UT-03 asserts zero gateway calls after each. `OutboxDispatcher` is the only class in the app that writes to a site. |
| **BR-02** — divergence never auto-resolved | `RefreshJiraStatus` has no code path that writes `Task.status`. The banner is derived from stored state, so it survives a restart and waits. S02-E2E-02 asserts nothing has moved before the user chooses. |
| **BR-08** — token only in secure storage; logs redacted | `SecureJiraCredentialStore` is the only writer; the token is never held in an adapter field, never read back into the settings form, and `JiraCredentials.toString` is redacted. The log interceptor drops bodies entirely and sweeps every line. S02-IT-04 asserts the header reached the wire *and* not the log. |
| Outbox backoff 2/4/8/16, max 5, then `failed` + manual retry | `OutboxDispatcher.backoff` / `.maxAttempts`; the "sync failed" strip offers **Retry**. A failure time cannot fix (401, 404, an invalid transition) fails immediately instead of burning five attempts. |
| Linking requires online validation | `LinkTaskToJira` calls `getIssue` first: a nonexistent key is `JiraIssueNotFoundFailure`, no network is `NetworkFailure`, and neither is queued. S02-UT-02 asserts the outbox stays empty. |

## 5. Deviations

Two decisions were recorded in `docs/reports/decisions.md`.

| ID | Summary |
|---|---|
| DEC-012 | **Scope extension, authorised by the Developer mid-sprint.** The target site is Jira Server/Data Center, not Cloud; the adapter now supports both, chosen explicitly in Settings. Cloud remains the default, and the contract suite runs against both configurations. |
| DEC-013 | Sprint developed on the environment-pinned branch, as in DEC-003 and DEC-009. |

**Nothing was left undone and nothing from a future sprint was implemented.**
No documented criterion was weakened.

### One defect found and fixed during the sprint

The three enqueueing use cases let a `StorageFailure` from the queue propagate
past them, so a user whose outbox refused an operation was told their action
was safely waiting when it was not. Found by a widget test, fixed by returning
it as a `Result`, and covered by a regression case
(`test/presentation/jira_task_actions_test.dart`, *a rejected enqueue is
reported, not swallowed*) — as `docs/project-rules.md` §5.6 requires.

## 6. Manual test against a real Jira

The Definition of Done requires a pass against a real site — the one thing no
automated suite can stand in for, because it is the site's own workflow,
authentication and field validation being tested, not ours.

**Script**, in the format of `docs/testing-strategy.md` §7:

- **Entry:** the built app; a Jira site the Developer can write to; a freshly
  generated token (Cloud API token, or Data Center personal access token).
  **The token is typed into the app by the Developer and is never committed.**
- **Action:**
  1. Settings → Jira → choose **Cloud** or **Server / Data Center**, enter the
     site URL, the account e-mail (Cloud only) and the token → **Connect**.
     Expect *Connected as …*.
  2. On a task, the link control → **Link to Jira** → enter a real issue key.
  3. The link control → **Comment on Jira** → type a comment → confirm.
  4. The link control → **Send status to Jira**.
  5. Wait for the sync indicator to clear, then check the issue in a browser.
  6. The link control → **Refresh from Jira**.
- **Exit:** the chip shows the key; the comment appears on the issue with the
  text that was typed; the issue's status is the task's; the "waiting to sync"
  strip disappears once both operations are applied; the refresh brings the
  cached status in line. Nothing in the app's logs contains the token.

> ⏳ **Pending the Developer's pass.** This is the one Definition-of-Done box
> the executing AI cannot check for itself — it needs a human, a real site and
> a token that must never reach this repository. The box in §7 stays unticked,
> and the sprint stays open, until the result is recorded here.

## 7. Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90% — §2, 96.4%
- [x] All S02-* tests passing; the CT contract runs for both adapters in CI — §3
- [ ] Manual test against a real Jira — §6, awaiting the Developer
- [x] Report `docs/reports/sprint-02-report.md` — this document
- [ ] GitHub Actions 100% green on the sprint PR
