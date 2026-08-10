# Handoff — Sprint 07 mid-flight, moving to another machine

Written 2026-08-10. **Sprint 07 is not finished.** This says exactly what is
true right now, what is left, and the traps waiting in the parts that are left.
Read `docs/project-rules.md` and `docs/sprints/sprint-07-copilot-cli.md` first,
as always.

---

## 1. State

| | |
|---|---|
| Branch | `sprint-07/copilot-cli`, pushed to `origin` |
| Worktree here | `.claude/worktrees/sprint-07-copilot-cli` |
| Base | `origin/master` at `7bb2888` (Sprint 06 merged, PR #12) |
| PR | **none opened yet** — deliberately, the sprint is not closeable |
| Tests | **860 passing**, up from 828 at Sprint 06 |

### Commits, oldest first

| | |
|---|---|
| `677ca7d` | DEC-037 — the Copilot CLI is a remote engine, and `isLocal` says so |
| `40f0f18` | `CliAiEngine` + the two profiles + the BR-10 chain |
| `0b26d77` | The Settings section, the model picker, the provider refactor |
| `dfb51c0` | S07-UT-01…UT-05, and the stdout truncation they found |
| *(this)* | DEC-038 and this handoff |

### Gates as they stand

| Gate | Result |
|---|---|
| G1 `flutter analyze` | `No issues found!` ✅ |
| G2 `dart format --set-exit-if-changed .` | 0 changed, exit 0 ✅ |
| G3 `flutter test` | 860 passing ✅ |
| G4 coverage | domain+application **91.4%** ✅ · project **79.7%** ❌ **below the 80% floor** |
| G5 `dart run tool/check_imports.dart` | no violations ✅ |
| G6 secrets | no match ✅ |

**G4 is the only red gate, and it is red for a knowable reason** — see §4.

---

## 2. Setting the other machine up

Both CLIs are installed and working on the machine this was written on, and
both were verified with a real command rather than assumed.

```bash
npm install -g @github/copilot
```

Claude Code CLI was already present (`claude.exe` 2.1.220). `gh` 2.96.0 is
installed and authenticated as `Aennson`.

**The account does have Copilot access** despite having no Pro plan — GitHub
Copilot Free covers it. One probe answered, exit 0, billing
`premiumRequests: 0.33`, models `claude-haiku-4.5` and `gpt-5-mini`.
`gh api /user/copilot_billing` returning 404 is *not* evidence of no
entitlement; that endpoint is simply unavailable to the token.

So **the DoD's manual pass is runnable on either machine.** It does not need
the one with the AI-model access.

Flutter lives at `C:\flutter\bin` and is not on the shell `PATH` in a
non-interactive session — prepend it.

---

## 3. What is built and green

**Domain.** `AiTimeoutFailure`, `AiProcessFailure` (carries the exit code),
`AiUnavailableFailure` (carries the engines tried). `AiEngineSettings` +
`AiEngineUsage`, `AiEngineSettingsStore`.

**Infrastructure.** `ProcessRunner`/`RunningProcess` (the seam the watchdog is
tested through), `CliAiEngine` (30s deadline, kill, JSONL and single-object
parsing, stderr redaction), `CopilotCliEngine` and `ClaudeCodeCliEngine` as
profiles, `DriftAiEngineSettingsStore` (two keys in the existing `settings`
key-value table — **no migration**).

**Application.** `FallbackAiEngine` (BR-10) and `AiEngineSelection.resolve`.

**Presentation.** `AiEngineSettingsSection` — engine choice, per-engine model
picker, fallback switch, per-engine answer counter — plus
`ai_engine_providers.dart`. Strings in all three ARBs.

**Tests.** S07-UT-01 through S07-UT-05, 32 scenarios, in
`test/application/ai_engine_selection_test.dart` and
`test/infrastructure/cli_ai_engine_test.dart`. `FakeProcessRunner` and
`FakeAiEngineSettingsStore` are in place for the suites still to come.

---

## 4. What is left, in the order to do it

### 4.1 S07-CT-01 — the contract over both CLI engines

`test/contracts/ai_engine_contract_test.dart` already says, in its own dartdoc,
that `CopilotCliEngine` joins it "as a third subject in Sprint 07". Add both CLI
engines to the `subjects` list with a `FakeProcessRunner` whose stdout the
`answerWith`/`parseAs` closures rewrite.

**The trap.** `_Subject` requires a `clearKey` callback and the suite has cases
asserting `MissingApiKeyFailure`. **The CLI engines cannot raise it** — Norte
holds no credential for them; the CLI owns its own login. Do not fake one to
make the case pass. Either give `_Subject` a flag saying the key cases do not
apply to this subject, or map "no key" onto the failure the CLI actually
produces when it is not signed in (a non-zero exit → `AiProcessFailure`). Record
whichever it is in the report as a contract divergence, because it is one.

### 4.2 S07-IT-01 — **rewrite it, do not implement it as written**

The sprint specifies three scenarios, and one of them describes a state the app
can no longer reach: *"off + local → CPF passes intact"*. DEC-037 sets
`isLocal = false` on every CLI engine, so the redactor relaxation never applies
and the setting that would disable it is not offered.

What to assert instead: with the CLI engine as with the remote one, a transcript
containing a CPF reaches the engine **redacted**, and no setting changes that.
Call it S07-IT-01 still, and say plainly in the report that its exit criteria
were re-read under DEC-037 rather than met as printed.

### 4.3 S07-GT-01 — goldens for the section

Windows and mobile, dark and light. `isWindowsProvider` is what switches them;
`aiEngineSettingsStoreProvider` needs `FakeAiEngineSettingsStore`. The mobile
golden must show **no Copilot and no Claude Code row** — that is the assertion,
not a side effect.

### 4.4 S07-E2E-01 and S07-E2E-02

E2E-01: app "as Windows", fake Copilot hangs, fake Claude answers, fallback on →
the summary appears with no error shown, the log records the switch, and the
counter increments on the engine that *answered*. E2E-02: both fail → an
actionable message, the transcript still in the field, retry available.

`AiUnavailableFailure.message` already names the engines and points at Settings;
check whether the meetings screen renders `failure.message` or maps to an ARB
string, and wire `aiErrorEngineUnavailable` if it is the latter. That key, plus
`aiErrorEngineNotInstalled` and `aiErrorEngineTooSlow`, are **already in all
three ARBs and currently unused**.

### 4.5 G4, and why it is red

Project coverage is 79.7% against an 80% floor. domain+application is 91.4%, so
the shortfall is entirely in what has no test yet: the Settings section, the
providers file, `DriftAiEngineSettingsStore`, and `SystemProcessRunner` (whose
every line is `dart:io`, and which is the CLI analogue of
`LocalNotificationScheduler` in Sprint 06 — deliberately not contract-tested).

**§4.3 and §4.4 are what fix this.** Do not add filler tests to lift the number;
the sprint's own remaining suites cover exactly the files that are dragging it.

### 4.6 The manual pass, the report, the PR

The DoD asks for one summary, one intent parse, and one forced fallback with
the real Copilot CLI on Windows. **Force the fallback by renaming the
executable** — that path is `AiProcessFailure` from a `start` that throws, and
it is already unit-tested, so the manual run is confirming the real
`Process.start` behaves as the fake does.

Then `docs/reports/sprint-07-report.md`, then the PR. **Do not open the PR
before G4 is green** — the sprint is not closeable with a red gate, and Sprint
05b's report is a standing example in this repo of what happens when a PR merges
with a box still open.

---

## 5. Decisions made mid-sprint that will surprise you

| DEC | What it changes |
|---|---|
| **037** | The Copilot CLI is **not** local inference. `isLocal = false`, redactor always enforced, `architecture.md` §7.2 corrected. Verified by running the CLI: server-chosen model, `serviceRequestId`, billed request |
| **038** | Claude Code CLI added to this sprint, amending the "Out" line at the Developer's request rather than stepping over it |

Two more things decided in code, both with the reasoning in the dartdoc:

- **The BR-10 retry is unconditional.** An earlier draft skipped it for failures
  that cannot change (missing key, CLI not installed). Removed: BR-10 says
  *exact sequence*, and `project-rules.md` is law over a local optimisation.
- **`aiEngineProvider` stopped being a port and became a computation.** It used
  to be overridden with one finished engine in `main.dart`, which cannot work
  for a preference the user can change at runtime. The root now overrides the
  pieces — `remoteAiEngineProvider`, the two CLI builders, `isWindowsProvider`.
  Any test that renders `SettingsScreen` now needs `isWindowsProvider` and
  `aiEngineSettingsStoreProvider` overridden, which is why
  `jira_settings_section_test.dart` gained two overrides.

---

## 6. The bug the tests found, and the lesson

A process that exits quickly completes `exitCode` **while stdout still has
lines in flight**. The first version of `CliAiEngine._collect` awaited the exit
code and then cancelled the subscriptions, discarding whatever had not arrived.

Every single-line fixture passed. The adapter read a one-line answer perfectly
and lost the same answer the moment a banner was printed above it — which both
CLIs do, on the day they decide an update is available. It was caught by the
first fixture with noise in it, because that fixture was written from what the
CLI *actually prints* rather than from what the parser expected.

That is Sprint 05 §5's lesson arriving again: a fake written from the caller's
expectations agrees with the caller about everything, including what both got
wrong. The `copilotNoise` constant in the test file is real output from the
manual probe, and it should stay that way.

---

## 7. Open, and deliberately not closed

- **G4 project coverage at 79.7%** — §4.5.
- **The CLI engines are absent from the contract suite** — §4.1. Until they are
  in it, "both engines pass the same suite" is unproven, and that is half of
  what the sprint is for.
- **Copilot's argv ceiling is real.** Claude Code takes its prompt on stdin and
  has no limit; Copilot 1.0.78 requires `-p <text>`, so a transcript over
  `CliAiEngine.maxPromptChars` (24 000) is refused with `ValidationFailure`
  rather than silently truncated by Windows. If Copilot ever grows a stdin path,
  flip `promptOnStdin` on its profile and the ceiling stops applying.
- **Claude Code's cold cache is expensive.** The verification probe cost
  $0.149 for a two-word answer, almost all of it 24 782 cache-creation tokens.
  Not a defect, but worth measuring before anyone makes it the default engine.
- **Sprint 05b's manual pass is still open**, three sprints later. Not this
  sprint's to close, and still not closed.
