# Sprint 07 — CopilotCliEngine (Windows), Fallback, and Engine Settings

**Objective:** the second AI adapter — Copilot CLI as a local subprocess on Windows — with a watchdog, fallback to `ClaudeApiEngine`, and engine selection in settings.

**Mandatory references:** `docs/architecture.md` §7.2–7.3, §12 · BR-07, BR-10

---

## Entry criteria

- [ ] Sprint 06 DoD complete.
- [ ] The `AiEngine` contract suites (S03-CT-01, S05-CT-02) exist and are parameterizable per adapter.

## Scope

**In:** `CopilotCliEngine` (`Process.start`, programmatic mode, parsed stdout, stderr logged with redaction); 30s timeout + watchdog (hung process → kill + controlled failure); `capabilities.isLocal = true`; the provider selection/fallback policy (`architecture.md §7.3`): primary fails (timeout, process error, rate limit) → 1 retry → fallback if enabled → clear error; local log of every engine switch; on Android/iOS the adapter reports `unavailable` and the UI hides the option; "AI Engine" section in Settings (engine choice — only Windows shows Copilot —, fallback toggle, per-engine usage counter).

**Out:** other local engines, streaming in the Copilot CLI (if the CLI does not support it, batch responses are acceptable).

## Sprint validation rules

- **BR-10:** exact sequence primary → retry → fallback → error; every switch logged with its reason.
- **BR-07:** with `isLocal == true`, the `PiiRedactor` may be disabled (setting), but the default remains **enabled**.
- The subprocess never receives secrets via argv (visible in the process list); the process environment is restricted to what is necessary.
- The watchdog kill must not leak zombie processes (verify termination).
- No platform code (`Platform.isWindows`) outside the composition root and the adapter itself.

## Tests

#### S07-UT-01 — Selection by platform and preference
- **What it validates:** the selection provider (§7.3).
- **Entry criteria:** provider with injectable platform and preference.
- **Action:** evaluate the 4 combinations (copilot/claude pref × Windows/non-Windows).
- **Exit criteria:** (copilot, Windows) → `CopilotCliEngine` with Claude fallback; all others → `ClaudeApiEngine`.

#### S07-UT-02 — Fallback chain (BR-10)
- **What it validates:** the primary → retry → fallback → error policy.
- **Entry criteria:** programmable fake primary engine (fails N times), spy fake fallback, spy logger.
- **Action:** scenario A: primary fails once and works on retry; B: primary fails twice, fallback works; C: both fail; D: fallback disabled and primary fails twice.
- **Exit criteria:** A → success with 2 calls to the primary, fallback untouched; B → success via fallback with the switch logged (reason included); C → `AiUnavailableFailure` with a clear message; D → failure without touching the fallback.

#### S07-UT-03 — Timeout and watchdog
- **What it validates:** a hung CLI does not hang the app.
- **Entry criteria:** fake process that never responds; controlled clock/timers.
- **Action:** `summarize()` and advance 30s.
- **Exit criteria:** `AiTimeoutFailure` at 30s; kill sent to the process; no process left behind.

#### S07-UT-04 — stdout parsing
- **What it validates:** robustness of the CLI parsing.
- **Entry criteria:** stdout fixtures: valid response, response with noise before/after the payload, empty output, exit code ≠ 0.
- **Action:** parse each fixture.
- **Exit criteria:** valid and noisy → payload extracted correctly; empty/exit ≠ 0 → `AiProcessFailure` (triggers the fallback chain).

#### S07-UT-05 — unavailable on mobile
- **What it validates:** §7.2 (Android/iOS hide the option).
- **Entry criteria:** adapter with the platform injected as Android.
- **Action:** query availability; render settings (widget test).
- **Exit criteria:** `unavailable == true`; the Copilot option is absent from the Settings UI.

#### S07-CT-01 — AiEngine contract on the CopilotCliEngine
- **What it validates:** both engines pass the **same** suite (architecture §13).
- **Entry criteria:** the existing contract suites (summarize + parseIntent) parameterized with `CopilotCliEngine` over a fake process with fixtures.
- **Action:** run the full suite.
- **Exit criteria:** same inputs → valid output shape identical to the contract; same `Failure`s for the same errors.

#### S07-IT-01 — Relaxed redactor with a local engine
- **What it validates:** BR-07 conditioned on `isLocal`.
- **Entry criteria:** `SummarizeMeeting` with a fake Copilot (`isLocal = true`), redaction setting at default (on) and off (2 scenarios); transcript containing a CPF.
- **Action:** summarize.
- **Exit criteria:** default on → CPF redacted even locally; off + local → CPF passes intact; off + remote engine → redaction **remains active** (the setting only applies to local).

#### S07-GT-01 — Engine settings
- **What it validates:** the per-platform Settings UI.
- **Entry criteria:** settings rendered as Windows and as mobile.
- **Action:** golden dark/light.
- **Exit criteria:** Windows shows the engine choice + fallback toggle + usage counter; mobile does not show Copilot.

#### S07-E2E-01 — Summary with transparent fallback
- **What it validates:** BR-10 in the real experience.
- **Entry criteria:** app "as Windows" with the fake Copilot programmed to hang and the fake Claude OK; preferred engine: Copilot; fallback on.
- **Action:** process a pasted meeting.
- **Exit criteria:** the summary appears (via fallback) with no error shown to the user; the diagnostics log records the switch; the usage counter increments on the engine that answered.

#### S07-E2E-02 — Both engines down
- **What it validates:** the clear error (§7.3).
- **Entry criteria:** both fakes failing.
- **Action:** process a meeting.
- **Exit criteria:** an actionable error message (names the problem and suggests checking Settings); transcript preserved in the field; retry available.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [ ] All S07-* tests passing; the contract suite covers both engines in CI.
- [ ] Manual test on Windows with the real Copilot CLI installed: 1 summary + 1 intent parse + 1 forced fallback (CLI uninstalled/renamed) — evidence in the report.
- [ ] Report `docs/reports/sprint-07-report.md`.
