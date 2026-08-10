# Sprint 07 — CopilotCliEngine, Fallback, and Engine Settings · Report

**Branch:** `sprint-07/copilot-cli` · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Enterprise 26100 (Developer's machine) · **CI:** `ubuntu-latest`

The sprint was executed across two machines. `docs/reports/HANDOFF-sprint-07.md`
is the record of where it stopped and what it was carrying; this report is what
happened after §4.1 of it.

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 06 DoD complete | `docs/reports/sprint-06-report.md`; merged at `7bb2888`/PR #12 | ✅ |
| The `AiEngine` contract suites (S03-CT-01, S05-CT-02) exist and are parameterizable per adapter | `test/contracts/ai_engine_contract_test.dart`, two subjects before this sprint and four after | ✅ |

**Sprint 05b's manual pass is still open**, four sprints later. Its own report
says the PR should not have merged without it, and PR #11 merged anyway.
Nothing in Sprint 07 depends on it — 05b is `taskRef` resolution and no engine
resolves a `taskRef` — but it is not closed by this sprint passing over it
either, and it is the Developer's to close.

## 2. Quality gates

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 14.1s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --output=none --set-exit-if-changed .` | `Formatted 296 files (0 changed)`, exit 0 ✅ |
| G3 — tests | `flutter test` | `01:23 +920: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **91.5%** (852/931) · project **80.4%** (5003/6219) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match ✅ |
| E2E | `flutter test integration_test/<suite>`, one per file (DEC-010) | **13 suites, all green** on the CI `e2e` job — run `31396322298` ✅ |

**The whole pipeline is green at `f6104e9`**: `quality`, `test` and `e2e` all
`success` in run `31396322298`.

**G4 was the red gate this sprint restarted on, at 79.7% against an 80% floor.**
It is green at 80.4%. The handoff predicted where the missing coverage was — the
Settings section, the providers file, `DriftAiEngineSettingsStore` — and said
the sprint's own remaining suites would cover it rather than filler tests. That
turned out to be true, and no test in this sprint was written to move the
number.

The suite grew 860 → 920.

**One environment note that matters for reading these numbers.** The machine
this half of the sprint ran on had Flutter 3.29.3 / Dart 3.7.2, which cannot
resolve the project's `sdk: ^3.12.0` constraint at all — no test could run until
it was upgraded to the 3.44.9 that `ci.yml` pins. The upgraded analyzer then
reported seven issues in code that had been clean on the older SDK: new lints
(`unnecessary_underscores`, `prefer_initializing_formals`) plus one genuine
unused parameter. All seven are fixed. **CI pins 3.44.9, so CI would have
reported them too** — the handoff's "G1: No issues found" was measured against
an analyzer that no longer exists in this project.

## 3. Scope delivered

Everything in the sprint's "In" list, plus DEC-038's second CLI engine.

**Domain.** `AiTimeoutFailure`, `AiProcessFailure` (carries the exit code),
`AiUnavailableFailure` (carries the engines tried); `AiEngineSettings`,
`AiEngineUsage`, `AiEngineSettingsStore`.

**Infrastructure.** `ProcessRunner`/`RunningProcess` (the seam the watchdog is
tested through), `CliAiEngine` (30s deadline, kill, JSONL and single-object
parsing, stderr redaction), `CopilotCliEngine` and `ClaudeCodeCliEngine` as
profiles, `DriftAiEngineSettingsStore` (two keys in the existing `settings`
table — no migration).

**Application.** `FallbackAiEngine` (BR-10) and `AiEngineSelection.resolve`.

**Presentation.** `AiEngineSettingsSection` — engine choice, per-engine model
picker, fallback switch, per-engine answer counter — and `ai_engine_providers`.
Strings in all three ARBs.

### Sprint validation rules

| Rule | How it is met |
|---|---|
| BR-10: exact sequence primary → retry → fallback → error, every switch logged | `FallbackAiEngine`, S07-UT-02 (4 scenarios), S07-E2E-01/02. The retry is **unconditional** — an earlier draft skipped it for failures that cannot change, and that was removed because `project-rules.md` says *exact* and is law over a local optimisation |
| BR-07: with `isLocal == true` the redactor may be relaxed; default enabled | Vacuously safe and deliberately so — **DEC-037 makes `isLocal` false on every engine that ships in v1.0**, so the relaxation is unreachable. S07-IT-01 asserts the branch is live and that nothing reaches it |
| No secret reaches argv; the child environment is restricted | Norte holds no credential for either CLI, so there is none to leak. `cli_ai_engine_test.dart` asserts the environment is empty and no argument is credential-shaped |
| The watchdog kill leaks no zombie | S07-UT-03 asserts `kill` was delivered, not merely that the call returned |
| No `Platform.isWindows` outside the composition root and the adapter | `isWindowsProvider`, overridden in `main.dart`; G5 green |

## 4. Tests

| ID | Where | Result |
|---|---|---|
| S07-UT-01 | `test/application/ai_engine_selection_test.dart` | ✅ |
| S07-UT-02 | `test/application/ai_engine_selection_test.dart` | ✅ |
| S07-UT-03 | `test/infrastructure/cli_ai_engine_test.dart` | ✅ |
| S07-UT-04 | `test/infrastructure/cli_ai_engine_test.dart` | ✅ |
| S07-UT-05 | `test/infrastructure/cli_ai_engine_test.dart` | ✅ |
| S07-CT-01 | `test/contracts/ai_engine_contract_test.dart` | ✅ **with two recorded divergences** — §5 |
| S07-IT-01 | `test/application/summarize_through_cli_engine_test.dart` | ✅ **exit criteria re-read under DEC-037** — §5 |
| S07-GT-01 | `test/presentation/goldens/ai_engine_settings_golden_test.dart` | ✅ |
| S07-E2E-01 | `integration_test/ai_engine_fallback_test.dart` | ✅ |
| S07-E2E-02 | `integration_test/ai_engine_fallback_test.dart` | ✅ |

## 5. Deviations, and why each one is one

Three. None is a box ticked loosely; each is a place the sprint document
described something the code can no longer be.

### 5.1 S07-CT-01 — the CLI engines cannot raise `MissingApiKeyFailure`

The contract suite asserts that an engine with no key raises
`MissingApiKeyFailure`, and it asserts `maxTokens > 0`. Neither is true of a
CLI engine, and neither can be made true honestly:

- **Norte holds no credential for either CLI.** Both authenticate themselves
  and keep their token under their own name. There is nothing for Settings to
  clear, so the failure is not merely unraised — it is unraisable. What a user
  actually meets is a CLI nobody has signed in, and what that does is print a
  complaint and exit non-zero.
- **A CLI reports no token ceiling.** `ClaudeApiEngine` sends `max_tokens` and
  therefore knows one; a CLI chooses server-side and says nothing. It advertises
  `0`, which nothing in the app reads.

**What was done.** The suite now names situations in words —
`credentialRejected`, `throttled`, `noCredential` — instead of HTTP statuses,
and each subject declares the `Failure` it really raises. The two CLI engines
are handed *the same* map, so changing either adapter's translation alone breaks
the suite; and a dedicated case asserts neither can raise
`MissingApiKeyFailure`, so the divergence is a tested claim rather than a gap.
All three CLI situations collapse onto `AiProcessFailure`, which drives BR-10's
chain exactly as `MissingApiKeyFailure` does.

**What was not done:** faking a key. That would have made the suite agree with
itself about a credential the app does not hold.

### 5.2 S07-IT-01 — one scenario describes a state the app cannot reach

As printed, the test asks for three scenarios, the middle being *"off + local →
CPF passes intact"*. DEC-037 sets `isLocal = false` on every CLI engine, so
BR-07's relaxation never applies and the setting that would disable the redactor
is not offered anywhere in the app. Implementing it as written would have
required inventing the setting **and** lying about `isLocal`, and the pair would
have shipped a CPF to a remote model.

**What is asserted instead**, keeping the ID: a CPF reaches the CLI engine
redacted through argv *and* through stdin — the two CLIs differ there, and a
rule holding for only one would be worse than none — the user's own transcript
is kept unredacted on the meeting, and the relaxation branch is shown to be
**live but unreachable**, by handing a genuinely local fake the same transcript
and watching the raw text go through.

### 5.3 The manual pass found two defects, and both are fixed

Recorded here rather than in §7 because they changed shipped code.

**The summary could never have worked.** `ClaudeApiEngine` sends
`MeetingSummaryCodec.schemaFor` as `output_config.format`, so the model has no
choice about the shape. A CLI has one prompt and no such affordance, and
`systemPromptFor` — written for a transport that carried the schema alongside it
— never says the word JSON. Asked to summarize a retro, the real Copilot CLI
answered in **Markdown headings**: a good answer to the prompt it was actually
given, and unreadable to the codec. `outputContractFor` now states the contract
in words, beside the schema it mirrors.

**Every fixture in the suite is JSON, which is precisely why no test caught it.**
The fakes agreed with the parser about a shape the model was never asked for.
That is `sprint-05` §5's lesson arriving a third time, and the regression test
written for it asserts *the prompt says JSON*, not that the fixture is.

**The executable name assumed one install.** `copilot.cmd` is what the npm
package lays down; this machine had the WinGet package, which ships a native
`copilot.exe`. The engine reported "is it installed?" about a tool that plainly
was. `CliEngineProfile.executables` is now an ordered list of candidates, and
only a failure to *start* advances to the next — a CLI that starts and exits
non-zero has answered, and running a second copy would turn one honest failure
into two and bill for it.

## 6. The bug the E2E suites found

**The engine preference was never being read before the first request.**

`aiEngineProvider` composes the chain from `aiEngineSettingsProvider`, and a
Riverpod provider is lazy: nothing read the settings until something read the
engine, and that read returned the defaults synchronously. So the first summary
of every session went to the remote engine no matter what the user had chosen,
the usage counter credited an engine they had not picked, and — because a
summary still appeared — nothing anywhere reported a problem. It is the exact
failure the counter exists to make visible, hiding from the counter.

It survived every unit and widget test in the sprint because those inject a
finished engine. S07-E2E-01 is the first thing to assemble the chain the way the
app assembles it, and it failed on the first run.

`_AiEngineWarmUp` in `NorteApp` activates the settings on the first frame, with
`ref.listen` rather than `ref.watch`: both start the provider, and watching
would rebuild the whole application subtree every time a switch moved in
Settings. Later reads were already safe — `invalidate` keeps the previous value
— so this closes the one window that existed.

**A second thing the E2E found:** `AiUnavailableFailure`, `AiProcessFailure` and
`AiTimeoutFailure` were falling through to "Summarizing failed. Try again.",
which at the end of a BR-10 chain is advice that cannot work. The three ARB keys
had been written earlier in the sprint and never wired. Both `meeting_labels`
and `voice_labels` map them now, because a voice command goes through the same
chain.

Both fixes carry regressions in `test/presentation/ai_engine_wiring_test.dart`
that run in the ordinary `flutter test` pass — the E2E suites only run on the
desktop host, and a fix nothing local guards is a fix waiting to be reverted.

### Two things the CI run then found, and neither was a product bug

**S07-E2E-02 counted starts, not attempts.** After §5.3 gave the profile two
executable spellings, one BR-10 attempt against a tool that is installed under
neither name is one `start` per candidate — so the count was 4 where the test
said 2. The chain was right the whole time; its own log shows exactly two
attempts and one switch. The assertion is now the product, and the *attempts*
are read from the log, because two attempts is what BR-10 specifies and starts
are an implementation detail of finding the tool.

**S00-E2E-01 booted a root that had grown requirements.** Sprint 00's smoke
suite builds a bare `ProviderScope` on the stated grounds that there was no
external adapter to override yet. That stopped being true here: Settings carries
the engine section, and `_AiEngineWarmUp` reads the preference on the first
frame, so `isWindowsProvider` and `aiEngineSettingsStoreProvider` are needed at
boot rather than when Settings is opened. Both still throw when unoverridden and
that is kept — a silent default is how a phone comes to be offered a subprocess
— so the suite supplies them exactly as `main.dart` does.

Worth noting for whoever runs these locally on Windows: with those overrides in
place the suite then reported a 153px `RenderFlex` overflow on the **Reminders**
screen at a 390px viewport, on this host and not on CI, where the same suite is
green. Golden sets are per-OS for this reason (DEC-006) — the host font stack
measures text differently. It is recorded rather than chased because CI is the
authority the DoD names, and CI does not see it.

## 7. The manual pass — **Windows ✅**

The DoD asks for one summary, one intent parse and one forced fallback against
the real Copilot CLI. `tool/copilot_manual_pass.dart` runs all three and is
committed, because the pass is worth repeating and a script says what it checked
more precisely than a paragraph.

```
PASS  summary
      28s · sections What went well, What to improve, Action items · 2 action items · engine copilot-cli
        - Update the runbook
        - Set up a review reminder in Slack
PASS  intent
      createTask · slots {title: revisar o PR do conector} · confidence 0.95 · missing none
PASS  forced fallback
      primary attempts 2 · fallback calls 1 · switch logged: true
        [copilot-cli] copilot-that-is-not-installed.cmd could not start — ProcessException
        [ai] parseIntent: copilot-cli failed (attempt 1/2) — AiProcessFailure: …
        [ai] parseIntent: copilot-cli failed (attempt 2/2) — AiProcessFailure: …
        [ai] parseIntent: switching copilot-cli → claude-api — AiProcessFailure
```

Three notes on how it was run:

- **The transcript is the synthetic fixture** (`testing-strategy.md` §3):
  invented people, invented complaints, no personal data left this machine.
- **The forced fallback points at an executable that does not exist** rather
  than renaming the installed one. `Process.start` cannot tell the difference —
  both raise `ProcessException` before a child exists — and renaming a tool the
  Developer installed is a side effect a verification script has no business
  having.
- **The summary step is given three minutes rather than thirty seconds.** The
  shipped deadline is unchanged and S07-UT-03 still pins it; a real model
  reading a real prompt is simply slower than the ceiling an intent needs, and
  the measured 28s is the number to weigh if the default is ever revisited.

### Intent slot fidelity varies, and the app already handles it

Across three consecutive runs on identical input, the title slot came back
filled **once**, with an identical confidence of 0.95 every time. The intent
type was correct in all three. Copilot routes per request and does not report
which model answered an intent.

This is not a transport failure and the pass is not conditioned on it: an
unfilled slot is a case the app is built for — `IntentParser` asks the user for
what is missing (S05-UT-05), which is the whole reason `missingSlots` exists.
It is recorded because *two in three* is worth knowing before anyone makes a CLI
the default engine for voice.

## 8. Open, and deliberately not closed

- **Copilot loads the user's own MCP servers and project skills.**
  `--no-custom-instructions` covers `AGENTS.md` and related files;
  `--disable-builtin-mcps` covers the built-in GitHub server. Neither covers a
  server the user configured in `~/.copilot/mcp-config.json`, and the manual
  pass watched one connect during a summary request. A meeting summary therefore
  starts whatever MCP servers that user has, and the answer can depend on their
  Copilot configuration rather than only on Norte's prompt. `--available-tools`
  may narrow it. Adding a flag on the evidence of a single probe, this late in a
  sprint, is worse than writing down what was seen — this is the first thing to
  pick up.
- **Copilot's argv ceiling is real.** Claude Code takes its prompt on stdin and
  has no limit; Copilot requires `-p <text>`, so a transcript over
  `CliAiEngine.maxPromptChars` (24 000) is refused with `ValidationFailure`
  rather than silently truncated by Windows. If Copilot grows a stdin path, flip
  `promptOnStdin` on its profile and the ceiling stops applying.
- **Claude Code's cold cache is expensive** — $0.149 for a two-word answer on
  the verification probe, almost all of it 24 782 cache-creation tokens. Not a
  defect; worth measuring before anyone makes it the default.
- **E2E cannot be run locally on this machine.** `flutter test integration_test/`
  builds a Windows desktop app, which needs symlink support and therefore
  Developer Mode. The suites are verified by the CI `e2e` job on the Linux
  desktop host, which is where DEC-010 says they run anyway. Enabling Developer
  Mode is the Developer's call and would make the local run possible.
- **Sprint 05b's manual pass is still open** — §1.

## 9. Decisions

| DEC | What it changes |
|---|---|
| **037** | The Copilot CLI is **not** local inference. `isLocal = false`, redactor always enforced, `architecture.md` §7.2 corrected |
| **038** | Claude Code CLI added to this sprint, amending the "Out" line at the Developer's request rather than stepping over it |

## 10. Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90% (**91.5%**), project ≥ 80% (**80.4%**)
- [x] All S07-* tests passing; the contract suite covers both CLI engines in CI — four subjects, with the divergences of §5.1 recorded rather than smoothed
- [x] Manual test on Windows with the real Copilot CLI: 1 summary + 1 intent parse + 1 forced fallback — §7
- [x] Report `docs/reports/sprint-07-report.md`
