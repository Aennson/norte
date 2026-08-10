# Norte — Decision Log

Deviations from the documented stack or from a documented specification are recorded
here (`docs/project-rules.md` §8). One entry per decision, newest last.

---

## DEC-001 — `onAccent` token and a darkened light accent (Sprint 00)

**Status:** accepted · approved by the Developer during sprint-00 execution.

**Context.** Three documented rules could not hold at the same time:

| Source | Rule |
|---|---|
| `design-system.md` §2.1/§2.2 | `accent` is `#D97757` (dark) / `#C2603F` (light) |
| `design-system.md` §4 | `NorteButton` primary draws `#FFFFFF` text on `accent` |
| `sprint-00` S00-UT-04 | the pair white/`accent` must reach WCAG AA ≥ 4.5:1 |

Measured contrast of the documented palette:

| Pair | Ratio | Verdict |
|---|---|---|
| `#FFFFFF` on dark `accent` `#D97757` | 3.12:1 | fails |
| `#FFFFFF` on light `accent` `#C2603F` | 4.17:1 | fails |

`#C2603F` reaches at most 4.17:1 against *any* foreground — white is the lightest
ink available — so the light accent could not be rescued by changing the text colour.

**Decision.**

1. Add an `onAccent` colour token: the foreground drawn on accent surfaces.
   - dark: `#1F1E1D` (the `bg` ink on coral) → **5.33:1**
   - light: `#FFFFFF` → **4.52:1**
2. Darken the light `accent` from `#C2603F` to `#BA5B3B` — the smallest darkening
   along the same hue/saturation that lets white reach AA.
3. `S00-UT-04` asserts the `onAccent`/`accent` pair per theme instead of a
   hard-coded white. The threshold stays **≥ 4.5:1** — the exit criterion is not
   weakened, it is measured against the pair the UI actually renders.

**Rejected alternatives.**

- *Darken both accents so white works* (dark `#D97757` → `#C5522D`): sacrifices the
  signature Claude Code coral in the dark theme, which is the product default.
- *Keep every hex and assert 3:1* (the WCAG threshold for UI components): weakens a
  documented exit criterion, forbidden by `docs/project-rules.md` §5.4.

**Impact.** `design-system.md` §2.1, §2.2 and §4 updated. The dark palette — the
product default — keeps every documented hex, including the brand accent `#D97757`.

---

## DEC-002 — `lucide_icons_flutter` instead of `lucide_icons` (Sprint 00)

**Status:** accepted.

**Context.** `docs/design-system.md` §5 specifies the Lucide icon set. The
`lucide_icons` package has not been updated since 2022 and does not resolve against
the Dart 3.12 / Flutter 3.44 SDK constraints used by this project.

**Decision.** Use `lucide_icons_flutter`, the maintained port of the same icon set.
The icon set, stroke and naming are unchanged; only the package that ships them differs.

---

## DEC-003 — Development branch for Sprint 00 (Sprint 00)

**Status:** accepted.

**Context.** `docs/project-rules.md` §7.1 names sprint branches `sprint-XX/<slug>`
and §7.2 requires one worktree per feature. The execution environment for this sprint
pins the branch name to `claude/projeto-fase-um-mwxiqe` and forbids pushing anywhere
else.

**Decision.** Sprint 00 is developed and pushed on `claude/projeto-fase-um-mwxiqe`.
Every other §7 rule is honoured: `master` is untouched, commits are authored by the
Developer with the AI as `Co-Authored-By`, and the sprint closes with a single PR to
`master` that merges only on 100% green Actions. From Sprint 01 on, the `sprint-XX/<slug>`
convention applies unless the environment pins a branch again.

---

## DEC-004 — Linux desktop enabled as the E2E host (Sprint 00)

**Status:** accepted.

**Context.** `docs/testing-strategy.md` §4.1 runs E2E with
`flutter test integration_test/` on a **Linux/desktop host in CI**, and
`docs/project-rules.md` §7.3 makes a green desktop-E2E job a merge condition.
The Flutter tool refuses to run `integration_test/` without a real device: the
headless `flutter-tester` cannot build an integration bundle, and the project's
declared platforms (Android/iOS/Windows) are all unavailable on a Linux runner.

**Decision.** Enable the Linux desktop target (`linux/`) purely as the **E2E
execution host**. It is not a shipped platform: Norte still targets Android, iOS
and Windows (`docs/architecture.md` §1). Nothing in `lib/` is Linux-specific.

**Impact.** `.github/workflows/ci.yml` installs the GTK toolchain and runs the
E2E job under `xvfb`.

---

## DEC-005 — Plugin versions raised above the first resolution (Sprint 00)

**Status:** accepted.

**Context.** The stack in `docs/architecture.md` §2.1 names the packages but not
their versions. The first resolution picked `record 5.2.1` and
`workmanager 0.5.2`, both predating the Android Gradle Plugin 9 / Gradle 9
toolchain that `flutter create` now generates — a likely native-build failure on
Android.

**Decision.** Pin `record: ^7.1.1` and `workmanager: ^0.10.7`. Neither package
has any Dart API surface in Sprint 00 (audio and background sync arrive in
Sprints 04–06), so the bump costs nothing today and removes a known build risk.

`sqlite3_flutter_libs` stays on `^0.5.42`: its `0.6.0` release is published as
`0.6.0+eol`, and choosing a replacement belongs with the persistence work in
Sprint 01, where it can actually be exercised.

---

## DEC-006 — Golden files are stored per operating system (Sprint 00)

**Status:** accepted · chosen by the Developer.

**Context.** Running `flutter test` on Windows failed all 13 golden assertions
with differences of 0.65%–1.25% of the pixels, while every other test passed.
The layout was identical; only the glyph rasterisation differed. Flutter renders
text through the host operating system's font stack, so a single committed `.png`
can only ever match on one platform. The same suite is green on Linux.

Three alternatives were rejected:

| Rejected | Why |
|---|---|
| Tag the goldens and exclude them off Linux | Keeps the CI gate intact, but leaves a developer on Windows with no visual verification at all — the assurance becomes CI-only. |
| Compare with a pixel tolerance | Contradicts S00-GT-01's exit criterion, which requires runs to "pass with **no diff**", and would mask a genuine 1px regression. |
| Regenerate the files on Windows | Would immediately break the Linux CI job that guards the merge (`docs/project-rules.md` §7.3). |

**Decision.** Every platform keeps its own golden set, compared with **no
tolerance**:

```
test/presentation/goldens/images/
  linux/     <- what CI compares against
  windows/
  macos/
```

`test/support/platform_goldens.dart` installs a `LocalFileComparator` that
rewrites `images/foo.png` into `images/<platform>/foo.png`; the golden suites
call `usePlatformGoldens()` in `setUpAll`. Nothing is tagged, excluded or
skipped — **every golden test runs on every platform**, against files produced
there.

A platform whose set does not exist yet fails with an explicit message naming
`flutter test --update-goldens` and the directory to commit. `--update-goldens`
only ever writes the running platform's directory, so one machine can never
invalidate another's files.

**Cost, stated plainly.** The artifacts multiply by the number of platforms in
use, and a deliberate UI change has to be regenerated on each of them before CI
goes green. That is the price of real visual verification everywhere, and it was
accepted knowingly.

**Impact.** `test/support/platform_goldens.dart` added; the 13 existing files
moved to `images/linux/`; both golden suites wired to the comparator;
`docs/testing-strategy.md` §1 records the rule.

## DEC-007 — `flutter_secure_storage` kept at `^9.2.4` (Sprint 00)

**Status:** accepted.

**Context.** `flutter build windows` fails with
`error C1083: Cannot open include file: 'atlstr.h'` from
`flutter_secure_storage_windows`. ATL is a Visual Studio component that the
"Desktop development with C++" workload does not install by default.

Upgrading was evaluated: `flutter_secure_storage_windows` **4.2.2 still includes
`<atlstr.h>`**, so the newer release does not remove the requirement.

**Decision.** Keep `^9.2.4` — moving to 11.0.0 would change ten packages without
fixing anything. The dependency is declared but unused until Sprint 02.

The Windows build environment must include the ATL component:

```
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" modify ^
  --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools" ^
  --add Microsoft.VisualStudio.Component.VC.ATL --quiet --norestart
```

**Impact.** No dependency change. The requirement is documented here and in the
environment setup script.

**Applied.** Installed on the Developer's Windows machine during sprint-00
closure. The `--installPath` form above fails when the path contains spaces
unless the installer is already elevated; the form that worked, run elevated:

```
setup.exe modify --productId Microsoft.VisualStudio.Product.BuildTools ^
  --channelId VisualStudio.17.Release ^
  --add Microsoft.VisualStudio.Component.VC.ATL --quiet --norestart
```

`flutter build windows --debug` succeeds afterwards.

---

## DEC-008 — Generated sources are excluded from the coverage gate (Sprint 01)

**Status:** accepted.

**Context.** `docs/project-rules.md` §2 sets gate G4 at *domain+application ≥ 90%*
and *project ≥ 80%* of lines, without saying whether machine-generated files count.
Sprint 01 introduces the first large generator output in the project. Measured on
the sprint's full suite:

| Group | Lines | Covered |
|---|---|---|
| `norte_database.g.dart` (drift) | 533 | 168 |
| `lib/l10n/generated/` (flutter gen-l10n) | 175 | 69 |
| Everything written by hand | 1084 | 962 |

Counting the generated files puts the project figure at 57.2% and makes the gate a
measurement of how much code `drift_dev` emits, not of how well the sprint is
tested. Even a hypothetical 100% of the authored code would only reach ~79.5% —
below the documented threshold — so the gate would be unreachable by construction.

**Decision.** `tool/check_coverage.dart` excludes `*.g.dart`, `*.freezed.dart` and
`lib/l10n/generated/` from **both** thresholds. The numbers stay **90% / 80%** —
they are not lowered; they are applied to the code the sprint actually writes.
Generated code is build output whose correctness belongs to the generator's own
test suite, and it is re-emitted from the same inputs on every build.

The excluded group is still printed on every run (`generated (excl.)`), so the
figure is visible rather than hidden.

**Rejected alternatives.**

- *Lower the thresholds to fit* — forbidden by `docs/project-rules.md` §5.4: a
  documented criterion is not weakened to make a run pass.
- *Write tests against the generated API until the ratio clears* — tests that
  assert what a generator emits, not what the app does; they would pass forever
  and catch nothing.

**Impact.** `tool/check_coverage.dart`. First run under the new rule:
domain+application 93.4%, project 88.7%.

---

## DEC-009 — Development branch for Sprint 01 (Sprint 01)

**Status:** accepted.

**Context.** `docs/project-rules.md` §7.1 names sprint branches `sprint-XX/<slug>`.
As in Sprint 00 (DEC-003), the execution environment pins the branch to
`claude/fase-dois-aco-427fc6` and forbids pushing anywhere else.

**Decision.** Sprint 01 is developed and pushed on `claude/fase-dois-aco-427fc6`,
in a worktree, with every other §7 rule honoured: `master` untouched, commits
authored by the Developer with the AI as `Co-Authored-By`, and a single PR to
`master` that merges only on 100% green Actions.

---

## DEC-010 — E2E suites run one invocation per file (Sprint 01)

**Status:** accepted.

**Context.** Sprint 01 adds a second file under `integration_test/`. Running
`flutter test integration_test/` then launches two real desktop windows in
sequence, and the tool starts the second before the first has fully exited:

```
Error waiting for a debug connection: The log reader stopped unexpectedly
Failed to load ".../tasks_crud_test.dart": Unable to start the app on the device.
```

Each file passes on its own, on Windows and on the Linux CI host. The failure is
in the desktop launcher, not in a test — nothing here is order-dependent
(`docs/testing-strategy.md` §4.3).

**Decision.** The CI `e2e` job loops over `integration_test/*_test.dart` and runs
one `flutter test` per file. Nothing is skipped or retried: every scenario still
runs on every push, and a real failure still fails the job.

**Impact.** `.github/workflows/ci.yml`.

---

## DEC-011 — The Linux golden set is generated on the CI runner (Sprint 01)

**Status:** accepted.

**Context.** DEC-006 keeps one golden set per operating system, and the `linux/`
set is what CI compares against. Sprint 01 changes the tasks screen and adds 16
new goldens, so the Linux set must be regenerated — but the Developer's machine
runs Windows, and glyph rasterisation depends on the host font stack, so a set
produced anywhere other than the CI runner image would be rejected by the very
job it is meant to satisfy. (A local WSL Ubuntu was available during the sprint;
its 26.04 font stack does not match GitHub's `ubuntu-latest`, so it would not have
helped.)

**Decision.** Add `.github/workflows/goldens.yml`, a `workflow_dispatch` job that
runs `flutter test --update-goldens` on the same runner image and pinned Flutter
version as the `test` job and uploads `test/presentation/goldens/images/linux/`
as an artifact. The files enter the repository through an ordinary reviewed
commit — the workflow never pushes.

This is exactly the procedure DEC-006 prescribes ("generate it once with
`flutter test --update-goldens`, then commit the files"), performed on the only
Linux machine the project has.

**Impact.** `.github/workflows/goldens.yml` added; `docs/testing-strategy.md` §1
records the procedure.

---

## DEC-012 — Jira Server/Data Center alongside Cloud (Sprint 02)

**Status:** accepted.

**Context.** `docs/architecture.md` §4 and the Sprint 02 scope both name **Jira
Cloud REST v3** with Basic auth. During the sprint the Developer identified the
target site as a self-hosted **Jira Server/Data Center** instance. (The
hostname is deliberately not recorded here: it is internal infrastructure, and
a decision record is a public document.) The two products are not
interchangeable in the three places an HTTP client cannot paper over:

| | Cloud | Data Center |
|---|---|---|
| path | `/rest/api/3/…` | `/rest/api/2/…` |
| auth | `Basic base64(email:token)` | `Bearer <personal access token>` |
| rich text | Atlassian Document Format | plain string |

The adapter as specified would have failed against the Developer's own site, so
the manual Definition-of-Done test could not have been performed at all.

**Decision.** `JiraRestAdapter` supports both, selected by a `JiraDeployment`
field on `JiraCredentials` that the user picks in Settings. Detection is
deliberately *not* inferred from the URL: a Data Center instance can live at any
hostname, and guessing wrong produces a 404 the user cannot diagnose.

Everything else is shared — request shape, response reading, status
classification, failure mapping — and the S02-CT-01 contract suite runs its nine
cases against **three** subjects (`FakeJiraGateway`, REST-as-Cloud,
REST-as-Data-Center), plus three cases that assert each product gets the wire
format it expects. Neither configuration can drift from the other.

This is a scope extension, authorised by the Developer during the sprint. No
documented criterion is weakened: every S02 test still runs, and Cloud remains
the default so the specified behaviour is what an unconfigured install gets.

**Impact.** `docs/architecture.md` §4.2 records the second deployment;
`JiraCredentials`, `JiraRestAdapter`, `SecureJiraCredentialStore`,
`JiraSettingsSection`, the three ARB files, `FakeJiraServer` and the contract
suite. OAuth 2.0 (3LO) remains the Cloud evolution path; Data Center's is
unchanged, since a PAT is already its long-lived credential.

---

## DEC-013 — Development branch for Sprint 02 (Sprint 02)

**Status:** accepted.

**Context.** `docs/project-rules.md` §7.1 names sprint branches
`sprint-XX/<slug>`. As in Sprint 00 (DEC-003) and Sprint 01 (DEC-009), the
execution environment pins the branch to `claude/proxima-fase-e56000` and
forbids pushing anywhere else.

**Decision.** Sprint 02 is developed and pushed on `claude/proxima-fase-e56000`,
in a worktree, with every other §7 rule honoured: `master` untouched, commits
authored by the Developer with the AI as `Co-Authored-By`, and a single PR to
`master` that merges only on 100% green Actions.

---

## DEC-014 — The Sprint 02 manual Jira pass is carried to Sprint 09 (Sprint 02 → 03)

**Status:** ~~accepted~~ **superseded by DEC-016** — the pass was executed. The
entry stays as written, because it is the record of why the box was open for as
long as it was. Decided by the Developer on 2026-08-08, when Sprint 03 was
opened.

**Context.** Sprint 02's Definition of Done requires a manual pass against a
real Jira site (`docs/reports/sprint-02-report.md` §6). It was never executed,
and the reason is not scheduling: **the Developer's site cannot be reached from
the Developer's machine.** A Zscaler Browser Access gateway answers before Jira
does, returning `200 text/html` or a `303` to `p.zpa-auth.net`, and it does not
read the `Authorization` header at all. No credential the app can send changes
the outcome — that transcript is what motivated Sprint 09 in the first place
(`docs/sprints/sprint-09-gateway-access.md`, *Why this sprint exists*).

So the box is not a task waiting for an afternoon. It is a test that the current
network makes impossible, and the sprint that makes it possible is already
planned and specified.

**Decision.** The Sprint 02 manual pass is **discharged into S09-MT-01**, which
supersedes it: S09-MT-01's steps 4 and 5 are the Sprint 02 §6 script (link,
comment, transition, refresh, verify in a browser, verify no token in logs)
performed against that same real site, once a route to it exists. The Sprint 02
DoD box is closed on that basis, with §6 rewritten to state plainly that the
pass did not happen and where it now lives. Sprint 09's Definition of Done gains
an explicit line for the inherited obligation, so closing it cannot quietly drop
the debt.

**What this does not claim.** No pass was performed and none is recorded as
performed. Sprint 02's automated evidence is unchanged and stands on its own:
293 tests, the contract suite against a real loopback server in both Cloud and
Data Center configurations, and two genuine defects found and fixed by the
Developer's attempt to run this very script (report §5). The attempt produced
the interception transcript — the sprint's most valuable manual finding — even
though it could not produce a green pass.

**Rejected alternatives.**

- *Hold Sprint 03 until the pass happens* — `docs/project-rules.md` §1 exists to
  stop work being built on unverified foundations, not to block on a test the
  network forbids. Nothing in Sprint 03 touches Jira; the meetings pipeline
  shares no code path with the gateway.
- *Tick the box as passed* — a false record, and the one thing a report may
  never contain.
- *Move Sprint 09 ahead of Sprint 03* — Sprint 09 is v1.1 by design
  (`docs/project-rules.md` §1), and its own entry criteria require an
  organisational answer on app-held sessions that is not yet on record.

**Impact.** `docs/reports/sprint-02-report.md` §6 and §7;
`docs/sprints/sprint-09-gateway-access.md` Definition of Done.

---

## DEC-015 — Development branch for Sprint 03 (Sprint 03)

**Status:** accepted.

**Context.** `docs/project-rules.md` §7.1 names sprint branches
`sprint-XX/<slug>`. As in Sprint 00 (DEC-003), Sprint 01 (DEC-009) and
Sprint 02 (DEC-013), the execution environment pins the branch to
`claude/next-phase-273c71` and forbids pushing anywhere else.

**Decision.** Sprint 03 is developed and pushed on `claude/next-phase-273c71`,
in a worktree, with every other §7 rule honoured: `master` untouched, commits
authored by the Developer with the AI as `Co-Authored-By`, and a single PR to
`master` that merges only on 100% green Actions.

---

## DEC-016 — The Sprint 02 manual Jira pass was executed (Sprint 02 → 04)

**Status:** accepted · attested by the Developer on 2026-08-08. **Supersedes
DEC-014.**

**Context.** DEC-014 discharged Sprint 02's manual box into S09-MT-01 because a
Zscaler Browser Access gateway made the Developer's Jira site unreachable from
the Developer's machine. That put a v1.0 obligation inside a v1.1 sprint —
Sprint 09 opens only once v1.0 has closed — so the debt could not be settled
until after the release it belonged to.

**Decision.** The script was run and reported as passing. The Sprint 02 box is
closed on that pass, in the report that owns it, and Sprint 09 no longer
inherits another sprint's obligation. S09-MT-01 keeps its own purpose: it
validates the *route through the gateway*, not the Jira operations, which are
now proven independently.

**What this rests on.** The Developer's attestation, which is what a manual box
is. No token was shared with the executing AI, none reached this repository, and
none appears in any commit. The failed first attempt and its `curl` transcript
stay in the Sprint 02 report: they found two defects and motivated Sprint 09,
and deleting them would make the record worse, not cleaner.

**Left open deliberately.** Which route made the site reachable is not recorded.
It does not affect this box, but Sprint 09's entry criteria require it to be
established before that sprint opens, since the whole sprint is premised on the
interception being real and current.

**Impact.** `docs/reports/sprint-02-report.md` §6–7;
`docs/sprints/sprint-09-gateway-access.md` Definition of Done.

---

## DEC-017 — The `AiEngine` port ships only the surface that has a caller (Sprint 03 → 04)

**Status:** accepted.

**Context.** `docs/architecture.md` §7.1 declares four members on `AiEngine`.
Sprint 03 implemented the port and shipped two of them plus `capabilities`.
`complete(AiRequest)` — documented as "generic use" — has no caller anywhere in
Sprints 00–08, and `parseIntent` is specified as returning `VoiceIntent`, a type
whose only consumer arrives in Sprint 05. The gap was explained in the Sprint 03
report but never written back into the architecture document, which left the
technical source of truth stating something the code does not do.

**Decision.** `complete(AiRequest)` is **not implemented** until a sprint has a
use for it: every adapter would otherwise have to satisfy a method no test
exercises, and it would sit in the coverage figure pretending to be work.
`parseIntent` keeps its provisional `String` return until **Sprint 05**, which
is the plan the provisional port itself recorded. `docs/architecture.md` §7.1 is
amended to say both things, so the next sprint reads a document that is true.

**Rejected alternative.** *Implement `complete` to match the document* — an
untested method on two adapters, written to satisfy a doc rather than a caller,
is the definition of dead code. Correcting the document is cheaper and honest.

**Impact.** `docs/architecture.md` §7.1; `lib/domain/ports/ai_engine.dart`.

---

## DEC-018 — `ActionItem` belongs to `MeetingSummary`, not to `Meeting` (Sprint 03 → 04)

**Status:** accepted.

**Context.** `docs/architecture.md` §3.1 placed `List<ActionItem> actionItems`
on `Meeting`. But `AiEngine.summarize` returns a `MeetingSummary`, and the
action items *are* output of summarization — extracted by the model, carrying
their own conversion state once the user turns one into a task.

**Decision.** The items live on `MeetingSummary`. `Meeting.actionItems` remains
as a **read-through getter**, so every caller and the accessor named in §3.1
still read true. Holding the list in two places would let the extracted items
and their conversion state disagree, and there is no correct answer to which
copy wins.

**Impact.** `docs/architecture.md` §3.1; `lib/domain/entities/meeting.dart`.

---

## DEC-019 — Template prompts and section headings are user data, not ARB resources (Sprint 03 → 04)

**Status:** accepted.

**Context.** BR-11 requires every UI string to come from ARB resources in three
languages. A `MeetingTemplate`'s `systemPrompt` and its section headings are
rendered in the UI, so the rule appears to reach them.

**Decision.** It does not, and they are stored as data. BR-11 governs the
**app's interface**; a template is the **user's content**. The prompt is sent to
a model and the headings become the keys of a stored summary, so translating
either at render time would rewrite the user's own edits, or make a summary
saved under one locale unreadable under another. The four seeded defaults ship
in English and the user edits them into whatever language their team runs
meetings in — the only answer that stays true for a bilingual team. Every string
of the app's own interface around them is localized in all three languages, and
S00-UT-06 still enforces key parity.

**Impact.** `lib/infrastructure/persistence` (seeded templates); BR-11's scope
as applied in Sprints 03+.

---

## DEC-020 — "Available platform" means Windows and Android (Sprint 00 → 04)

**Status:** accepted · decided by the Developer on 2026-08-08.

**Context.** Norte targets Android, iOS and Windows. Sprint 00 §5.1 closed the
Android and Windows builds with real artifacts and left **iOS unverified**: it
requires a macOS host, which the project does not have. Several sprints have a
manual script phrased "on each available platform" — Sprint 04's is the first
where that phrase decides whether a box can be ticked, since it asks for a real
recording per platform.

**Decision.** For every manual script in v1.0, **"available platform" means
Windows and Android** — the two the Developer's machine can build and run. iOS
is a declared target that remains **unverified**, and it is recorded as an open
platform obligation rather than silently dropped: the first build, the first
manual pass, and the `test/presentation/goldens/images/macos/` golden set are
all deferred until a macOS host exists. No sprint may tick an iOS-specific box
before then.

**Rejected alternatives.**

- *Block Sprint 04 until a Mac exists* — blocks the project indefinitely on
  hardware, for a platform whose code path is the same `record` plugin.
- *Quietly read "available" as "whatever was tested"* — the phrase would then
  mean nothing and every future sprint would reinterpret it.

**Impact.** Every v1.0 manual script; `docs/reports/sprint-00-report.md` §5.1;
the missing `macos/` golden set.

---

## DEC-021 — `BatchTranscription` takes a path, not a `dart:io` `File` (Sprint 04)

**Status:** accepted.

**Context.** `docs/architecture.md` §9.1 declares
`Future<Transcript> transcribeFile(File audio, {String? language})`. Sprint 00
wrote the provisional port with `String path` instead, at a point when it had
no caller and no entity types; Sprint 04 promoted it and had to choose which
of the two the real port would be.

**Decision.** The port keeps **`String path`**. `File` is a `dart:io` type, and
putting it on a domain port drags a platform dependency into the one layer the
project keeps free of them: the layer rule permits `dart:` imports, so nothing
would have failed the gate — it would simply have been wrong quietly. The
practical cost is immediate and testable: `FakeAudioStore` can model a
directory as a `Set<String>`, and `S04-UT-03` can assert "no audio file remains
in the directory" without touching a real filesystem it would then have to
clean up. `WhisperBatchEngine` constructs its own `File` from the path, which
is where a platform type belongs.

`docs/architecture.md` §9.1 is amended to match, and the promoted port is
otherwise byte-for-byte the provisional one — including `progress`, which the
architecture document never named but the recording screen needs.

**Impact.** `docs/architecture.md` §9.1;
`lib/domain/ports/transcription_engine.dart`.

---

## DEC-022 — `permission_handler` added to the stack (Sprint 04)

**Status:** accepted.

**Context.** Sprint 04 requires that a denied microphone produce "an
explanatory screen with a link to system settings; never a crash". The `record`
package — the stack's audio dependency (`docs/architecture.md` §2.1) — exposes
only `hasPermission()`, a boolean. It cannot distinguish *denied* from
*permanently denied*, and it cannot open the system settings at all.

Those two gaps are the whole screen. Without the distinction, the app shows an
"Allow microphone" button that produces no prompt on a platform that has
stopped asking — a control that silently does nothing, which is worse than no
control. Without the settings deep link, there is no route out at all, and the
sprint's rule cannot be delivered.

**Decision.** Add `permission_handler: ^13.0.0`, used **only** by
`RecordAudioRecorder` and only for the microphone permission. Capture itself
stays with `record`. `MicrophonePermission` — the domain's three-state enum —
is what the rest of the app sees, so the package appears nowhere above
`infrastructure/platform/`.

**Rejected alternatives.**

- *Ship the boolean and always show the settings link* — a user whose refusal
  was a mis-tap is sent on a trip through system settings for a permission the
  prompt would have granted in one tap.
- *Write the platform channels by hand* — three platforms of native code, for a
  problem a maintained package solves, in a sprint whose subject is audio.

**Impact.** `pubspec.yaml`; `lib/infrastructure/platform/record_audio_recorder.dart`;
`docs/architecture.md` §2.1's dependency list gains one entry.

---

## DEC-023 — Development branch for Sprint 04 (Sprint 04)

**Status:** accepted.

**Context.** `docs/project-rules.md` §7.1 names sprint branches
`sprint-XX/<slug>`. As in Sprint 00 (DEC-003), Sprint 01 (DEC-009), Sprint 02
(DEC-013) and Sprint 03 (DEC-015), the execution environment pins the branch
and forbids pushing anywhere else.

**Decision.** Sprint 04 is developed and pushed on
`claude/sprint-verification-04e4a6`, in a worktree, with every other §7 rule
honoured: `master` untouched, commits authored by the Developer with the AI as
`Co-Authored-By`, and a single PR to `master` that merges only on 100% green
Actions.

---

## DEC-024 — The provisional ports file is retired (Sprint 05)

**Status:** accepted.

**Context.** Sprint 00 could not create domain entities, so the fakes whose
real ports needed them were declared in primitives in
`test/fakes/ports/provisional_ports.dart`, each marked with the sprint that
would promote it. `JiraGateway` went in Sprint 02, `AiEngine` in Sprint 03,
`BatchTranscription` in Sprint 04. Sprint 05 promotes the last one,
`RealtimeTranscription`, into `lib/domain/ports/transcription_engine.dart`,
typed against `Uint8List` as `docs/architecture.md` §9.1 specifies.

**Decision.** Delete the file rather than leave it as a stub. Its whole purpose
was to hold contracts awaiting promotion, and none remain; a file of comments
explaining that it is empty is a file the next reader opens to learn nothing.

Worth recording for its own sake: **every provisional port was promoted
unchanged in shape.** `Transcript` and `BatchTranscription` arrived in Sprint 04
exactly as Sprint 00 sketched them (DEC-021), and `TranscriptEvent`'s
`text`/`isCommitted` pair survived untouched into the real port. The one thing
that changed was `AiEngine.parseIntent`, which Sprint 00 could only type as
`String` and this sprint promotes to `VoiceIntent` (DEC-017).

**Impact.** `test/fakes/ports/provisional_ports.dart` deleted;
`test/fakes/fakes.dart` loses the export and gains a note;
`lib/domain/ports/transcription_engine.dart` gains `TranscriptEvent` and
`RealtimeTranscription`.

---

## DEC-025 — What Sprint 05's reminder stub resolves, and what it refuses (Sprint 05)

**Status:** accepted.

**Context.** The sprint's scope note says `createReminder` "only creates the
persisted `Reminder` entity", and Sprint 06's entry criteria expect the entity
"persisted via the stub". But `Reminder.triggerAt` is a `DateTime`, and the
parser returns a slot like `+20m`, `today 15:00` or `friday 15:00`. Something
has to turn one into the other, and the sprint's "Out" section excludes
"date/time parsing beyond what the `AiEngine` returns in the slots".

**Decision.** `CreateReminder` resolves exactly the forms that need nothing but
the injected clock — an ISO 8601 instant, and a relative offset (`+90s`,
`+20m`, `+1h`, `+2d`) — and returns `ValidationFailure` for a wall-clock
phrase, naming the `triggerAt` field.

Resolving `tomorrow 09:00` correctly needs the device timezone and a weekday
calendar, which is precisely S06-IT-02. Implementing it here would be doing a
future sprint's work without its tests; refusing it leaves Sprint 06 a case it
has to make pass, which is the honest way to hand work forward. The boundary is
pinned by a test of its own so it cannot drift silently.

`NotificationScheduler` is deliberately **not** a constructor parameter, so
"Sprint 05 does not schedule" is a fact about the type rather than a promise in
a comment.

**Impact.** `lib/application/usecases/create_reminder.dart`;
`test/application/create_reminder_test.dart`; Sprint 06 inherits the wall-clock
forms.

---

## DEC-026 — The Scribe realtime wire format (Sprint 05)

**Status:** **settled** against `Aennson/zefa-ia`, the Developer's own working
ElevenLabs integration, 2026-08-09. A live probe came first and got part of it
right and one important part **wrong**; both rounds are recorded, because the
way the probe misled is more useful than the answer it produced.

### The protocol, as a working implementation speaks it

Client to server — **one** message type, as JSON **text**, never a binary
frame:

```json
{"message_type":"input_audio_chunk","audio_base_64":"…",
 "commit":false,"sample_rate":16000}
```

Session configuration is entirely in the query string: `model_id`,
`audio_format=pcm_16000`, `commit_strategy=vad`, and an optional
`language_code` in ISO-639-3.

Server to client, discriminated by `message_type`: `session_started`,
`partial_transcript`, `final_transcript`, `committed_transcript`,
`committed_transcript_with_timestamps`, `rate_limited`, `input_error`. Errors
carry a **flat sentence** in `error`, not a typed code.

A commit is not a message of its own — it **rides on an audio chunk**, so an
empty chunk with `commit: true` is how a client says the sentence is over.

### What the probe got right, and the one thing it got wrong

Right, and worth having: `message_type` rather than `type`; the flat error
string; `xi-api-key` on the handshake (DEC-029); ISO-639-3 language codes, and
that a bad one closes the socket with 1008.

**Wrong: it concluded audio is raw binary and that no JSON audio message
exists.** The probe enumerated thirteen candidate `message_type` values and saw
every one refused. It never tried `input_audio_chunk` — and had it tried,
without `audio_base_64` and `sample_rate` the answer would have been the same
refusal, because **"refused by name" and "refused for a missing field" are
indistinguishable from outside**. A method that looked systematic produced a
confident, wrong conclusion, and shipping it would have meant every chunk
silently rejected: nothing transcribed, nothing obviously broken.

The reference implementation carries a comment recording that its author made
the same mistake before fixing it. Two independent arrivals at the same wrong
answer is a good sign the API's failure mode, not the reader, is what is
misleading.

**The lesson worth keeping** is not "probe more". It is that **a black-box
probe can only refute, never confirm** — an accepted message proves a shape
works, a refused one proves nothing about *why*. Where a working
implementation exists, read it first; it is the only oracle that answers the
positive question.

### The original decision, and why the tolerance was still right

**Context.** `ScribeRealtimeEngine` speaks a WebSocket protocol this repository
cannot exercise in CI: every automated test drives it through
`FakeRealtimeSocket`, because a suite that called the real service would
violate `docs/project-rules.md` §5.4. The adapter's assumptions about frame
names were therefore unverified when it was written.

**Decision.** Ship a deliberately tolerant reader — `partial`/`final`/
`committed` in the name, an `is_final` boolean, either `text` or `transcript`
as the field — so that a protocol revision degrades into a harmless spelling
difference rather than the silent loss of every voice command. The same risk
`docs/architecture.md` §15 records for the Copilot CLI, wearing a different
coat.

**How it held up.** Tolerance was the right instinct and it was not enough. It
would have absorbed a renamed transcript frame; it could not absorb a different
*discriminator*, and `type` versus `message_type` is exactly that. The lesson
is narrower than "be tolerant": **be tolerant about values, and verify the
shape.** A tolerant reader of a field that does not exist reads nothing,
tolerantly.

**What made it verifiable.** A short-lived key and a throwaway probe outside
the repository — sixty lines of `dart:io`, no dependency on the app, no
credential anywhere in the tree. That is the tool the sprint should have
reached for on day one rather than at the end, and the reason it did not is
that "no real APIs in tests" was read as "no real APIs at all". §5.4 forbids
them in *tests*; it says nothing about a diagnostic run by hand.

**Impact.** `lib/infrastructure/transcription/scribe_realtime_engine.dart`;
`test/support/fake_realtime_socket.dart` and `fake_realtime_server.dart`, both
of which were speaking the invented dialect and are now speaking the observed
one; `docs/reports/sprint-05-report.md` §7.

---

## DEC-027 — The voice settings are read on demand, not watched (Sprint 05)

**Status:** accepted.

**Context.** `VoiceSettingsStore` was first written with a `watch()`, and the
router held a snapshot from a `StreamProvider`. Writing S05-E2E-01 (C) found
the flaw: between launch and the stream's first emission the router reports the
defaults rather than the user's choice. With a default of "always confirm" that
window is harmless — the user is asked when they expected not to be — but the
shape of the bug is a confirmation decision that depends on scheduling.

**Decision.** `VoiceSettingsStore` has `read` and `write` and no `watch`.
`IntentRouter` reads it at the moment it needs to know, which costs one local
query and has no window at all. The Settings screen uses a `FutureProvider`
invalidated after a write — the pattern `aiConfiguredProvider` and
`transcriptionConfiguredProvider` already use, so the codebase gains no new
idiom.

**Rejected alternative.** *Keep the stream and seed it with a synchronous
read* — two sources of truth for one boolean, and the seeding is the same
scheduling assumption written more elaborately.

**Impact.** `lib/domain/ports/voice_settings_store.dart`;
`lib/infrastructure/persistence/drift_voice_settings_store.dart`;
`lib/application/voice/intent_router.dart`;
`lib/presentation/voice/voice_providers.dart`.

---

## DEC-028 — Three BYOK credentials, three slots (Sprint 05)

**Status:** accepted.

**Context.** Sprint 05's first draft handed `whisperCredentials` to
`ScribeRealtimeEngine` in the composition root. Whisper is OpenAI and Scribe is
ElevenLabs — different services, different keys — so the app had one field and
one storage slot for two credentials. Configuring voice commands would have
silently broken meeting transcription, and the reverse.

Nothing caught it. Every unit, contract and E2E test injects a credential store
directly, so `main()`'s wiring is the one layer no suite exercises. It was found
by writing the manual script's instructions and discovering they could not be
followed: there was no field to put the Scribe key in that did not already hold
something else.

**Decision.** `SecureTranscriptionCredentialStore` gains two named
constructors, `.whisper` and `.scribe`, filing under
`transcription.whisper.apiKey` and `transcription.scribe.apiKey`. **There is no
default constructor**, so the composition root cannot pick the wrong store by
omission — the mistake is made impossible to express rather than merely
asserted against, which is the only durable fix for a layer without tests.

The voice settings section grows a masked key field beside its switch, with the
same BR-08 shape as the other three key forms: the stored key is never read
back into the field, and a configured install shows *that* a key exists, never
the key.

**Rejected alternative.** *One "transcription key" for both* — the shape that
caused the bug. A slot named for what a key is *for* rather than which service
it belongs to invites exactly one slot for two providers.

**Impact.** `lib/infrastructure/transcription/secure_transcription_credential_store.dart`;
`lib/main.dart`; `lib/presentation/settings/voice_settings_section.dart`;
`lib/presentation/voice/voice_providers.dart`; four new strings in each of the
three ARB files; `test/infrastructure/transcription_credential_slots_test.dart`.

---

## DEC-029 — The realtime key travels in a header, over a socket a test can watch (Sprint 05)

**Status:** accepted.

**Context.** The second wiring defect of the same family as DEC-028, found the
same way — by answering a question about the manual pass rather than by a test.
`WebSocketRealtimeSocket.connect` accepted an `apiKey` argument, documented it
as going into the `xi-api-key` header, and **never sent it**:
`WebSocketChannel.connect` carries no headers at all. `realtime_socket.dart`
had **0 of 14 lines covered**, because every engine test drives
`FakeRealtimeSocket`.

A fake transport is the right tool for reproducing a dropped connection
deterministically. It is the wrong tool for asking whether a credential leaves
the machine, and nothing in the suite was asking.

**Decision.** Three parts.

1. Connect through `IOWebSocketChannel`, which can send handshake headers. The
   generic constructor cannot, and its silence is what hid the bug. All three
   v1.0 targets are `dart:io` platforms (`docs/architecture.md` §12).
2. Present the key in the **`xi-api-key` header, never in the query string**. A
   URL is the part of a request that reliably reaches proxy logs, crash reports
   and shell history; a credential put there cannot be taken back (BR-08).
3. Add `FakeRealtimeServer` — a real loopback WebSocket server that records the
   handshake — and test the adapter against it. This is the same shape as
   `FakeClaudeServer` and `FakeJiraServer`, and for the same reason: an adapter
   mocked at its own boundary tests the mock.

**What this does not settle.** Whether ElevenLabs authenticates a realtime
socket by this header at all. That is DEC-026's open item, and a 401 on the
handshake is exactly the signal the manual pass is looking for — it now
surfaces as `AuthFailure` rather than as a generic network problem.

**Impact.** `lib/infrastructure/transcription/realtime_socket.dart`;
`test/support/fake_realtime_server.dart`;
`test/infrastructure/realtime_socket_test.dart`.

---

## DEC-030 — A lettered sprint for the task commands (Sprint 05a)

**Status:** accepted.

**Context.** The Developer asked for the app's own tasks to be fully operable
by voice — change status, comment, delete under confirmation, create with every
attribute — plus multi-status filtering and a description search. None of it is
in Sprint 05's documented scope, and `docs/project-rules.md` §8 forbids
implementing a future sprint's work while a sprint is open.

The numbering had no room. Sprints 00–08 deliver v1.0 and are all specified;
09 opens v1.1. Inserting a number would renumber documents that other files,
test IDs and reports already reference by name.

**Decision.** `docs/sprints/sprint-05a-task-commands.md`, executed after 05 and
before 06, with test IDs prefixed `S05a-`. Roadmap item 5a in
`docs/architecture.md` §14 records the position.

**Rejected alternatives.**

- *Extend Sprint 05* — its PR is green and complete against its own scope, and
  a sprint that grows while it is being closed is a sprint with no Definition
  of Done.
- *Fold it into Sprint 06* — Sprint 06 is reminders and notifications across
  three platforms. Two unrelated subjects in one sprint means one DoD that
  cannot fail cleanly.

**Impact.** `docs/sprints/sprint-05a-task-commands.md` (new);
`docs/architecture.md` §14.

---

## DEC-031 — Continuous listening, and what a session survives (Sprint 05)

**Status:** accepted, on the Developer's instruction after the first real run.

**Context.** Sprint 05 shipped a session that closed the microphone the moment
a segment committed, executed one command, and ended — including when the
command merely failed to be understood. In use that turned out to be wrong on
both counts: every command needed its own press of the button, and a
misunderstanding cost the user the session as well as the command.

**Decision.** The microphone stays open until the user stops it, and commands
execute as they are spoken. A failure ends the session only when it takes the
pipeline down — no key, a rejected key, no microphone. Everything else leaves
the session listening, because the fix for a misunderstanding is saying it
again.

Three guards keep "continuous" from meaning "twice":

- A segment arriving while the previous one is still being parsed is the same
  sentence. VAD segments on silence, and a real run produced 14 characters
  followed by 5 from one command; routing both executed it twice.
- Anything said while a confirmation sheet is up is the user reading, not a
  new command.
- A segment that is **only** hesitation never reaches the parser (DEC-032).

**Impact.** `lib/presentation/voice/voice_providers.dart`;
`docs/sprints/sprint-05-realtime-voice.md`'s implicit one-command-per-session
assumption, which was never written down and is now contradicted here.

---

## DEC-032 — Hesitation is filtered twice, and asymmetrically (Sprint 05)

**Status:** accepted.

**Context.** "eeeh", "hmmm" and "aaah" commit as segments like any other. Each
one costs an API call, a second of the user's time, and an answer of `unknown`
that reads on screen as the app failing to understand — when nothing was said.

The Developer expected `zefa-ia` to solve this and asked me to copy it. It does
not: there is no disfluency handling anywhere in its STT or audio layers. What
looks like filtering there is the model tidying up on its own. Recorded because
"the other project already does it" was the premise, and it was not true.

**Decision.** Two filters, and the asymmetry is the design.

1. `no_verbatim` is requested of the service — it appears among the settings
   the endpoint echoes on `session_started`, so it is the cheapest place to
   drop hesitation, before it is ever transcribed.
2. `SpeechFiller` catches what gets through, and rejects a segment **only when
   it is entirely filler**. "eh, cria tarefa" is a command with a stumble in
   front of it; dropping it to save an API call would lose a command the user
   actually gave.

Matching collapses repeated letters, so `eeeeh` and `eh` are one word and the
list stays short.

**Impact.** `lib/infrastructure/transcription/scribe_realtime_engine.dart`;
`lib/presentation/voice/speech_filler.dart`.

---

## DEC-033 — The audit log records actions, and the wipe survives itself (Sprint 10)

**Status:** accepted.

**Context.** The Developer asked for a log of everything the app does, for
audit purposes, delivered after every other sprint so the evolutionary cycle is
not disturbed.

Two things had to be decided before it could be specified, because both change
guarantees the project already made.

**Decision 1 — an audit entry is a fact about an action, never its content
(BR-12).** "Everything that occurs" read literally would mean writing
transcripts, utterances, task titles, Jira payloads and credential activity to
disk. BR-03, BR-06, BR-07 and BR-08 each forbid part of that, and together they
forbid all of it: the app's privacy posture rests on those things *not* being
written down. An audit trail that wrote them would undo four rules at once and
would be, in substance, a second copy of the data it audits.

So an entry carries the entity type and id, the actor, the action, the outcome,
and scalars — counts, lengths, durations, enum values, confidences. It never
carries a string a person or a model authored. The codebase already practises
exactly this in its diagnostics (`committed segment: 98 chars`, never the
segment; token counts, never the prompt); BR-12 promotes the habit to a rule
and `tool/check_audit.dart` makes it a build failure rather than a review note.

**Decision 2 — "delete everything" wipes the audit log and then records that it
did.** This is a genuine conflict with no clean answer: auditability wants the
log to outlive a wipe, and the right to erasure (`architecture.md` §10) wants
nothing to survive it. Keeping the log through a wipe would mean the one
operation whose purpose is to leave nothing behind leaves behind a detailed
account of everything that came before — the erasure would be a lie. Wiping it
silently means the user cannot afterwards tell whether the wipe ran at all,
which was one of the three questions that motivated the sprint.

The resolution keeps erasure honest and answers the question: the wipe clears
every entry and writes exactly one new one — `security/dataWiped`, with the
number of entries removed. The count is a fact about the app's behaviour; it
identifies nothing. The hash chain restarts from that entry.

**Rejected alternatives.**

- *Log content and encrypt it at rest.* Moves the problem to key custody on a
  device the user already controls, and BR-08 keeps the only secure store for
  credentials. It would also make "the log contains no transcripts" — the
  sentence that makes this feature safe to ship — untrue but hard to disprove.
- *Keep the audit log across a wipe.* Rejected above: it makes the erasure
  guarantee false.
- *Wipe silently, recording nothing.* Cheapest, and it deletes the evidence
  that the feature works.
- *A separate append-only file outside Drift.* No integrity gain on a machine
  the user owns (see the sprint's "What the hash chain does and does not
  prove"), and it would escape the wipe by accident rather than by decision.
- *Run the sprint earlier, e.g. after 05a.* Instrumenting use cases that later
  sprints then rewrite means doing the work twice and reviewing it twice. The
  Developer's instruction — last, so the cycle is not broken — is also the
  cheaper order.

**Impact.** `docs/sprints/sprint-10-audit-log.md` (new); `docs/project-rules.md`
§4 (BR-12); `docs/architecture.md` §10, §14.1.

---

## DEC-034 — Accent folding is written, not depended on (Sprint 05a)

**Status:** accepted.

**Context.** Two features added this sprint need the same comparison: naming a
task out loud (`docs/architecture.md` §6.3.1) and searching the list (§4.1).
A user who says "orcamento" means the task called "orçamento", and a search box
that disagreed with the voice command about which tasks match would be two
features with two opinions about the same string.

Dart's core library has no Unicode normalisation — no NFD, no `String.fold` —
so lowercasing alone does not do it. The obvious answer is the `diacritic`
package, roughly the same thirty lines behind a version constraint.

**Decision.** `TextMatch` in `domain/services/`, with an explicit map from each
lowercase accented rune to its unaccented spelling. It covers the Latin-1
diacritics Portuguese and Italian actually use plus the two ligatures they
borrow, and it says so in its own dartdoc: it is not a collator, and it knows
nothing about Turkish dotless i or Greek final sigma.

`domain/` may import nothing outside `domain/` (§3), so a package here would
also have been the first third-party dependency in the layer that is supposed
to have none.

**Rejected alternatives.**

- *The `diacritic` package.* A dependency in the domain layer for eight vowels,
  and one that would have to be added to `docs/architecture.md` §2.1 as part of
  the stack. The scope it buys — every script in Unicode — is scope the three
  supported languages (BR-11) do not use.
- *Fold with a regex over a normalised string.* There is nothing to normalise
  against without NFD; the regex would need the same map.
- *Compare case-insensitively and ignore accents entirely.* Then "orcamento"
  finds nothing, which is the exact complaint the fold exists to answer.

**Impact.** `lib/domain/services/text_match.dart` (new);
`lib/application/usecases/list_tasks.dart`;
`lib/application/voice/intent_router.dart`.

---

## DEC-035 — `taskRef` resolves approximately, but digits do not (Sprint 05b)

**Status:** accepted.

**Context.** A task titled `HEROBRAZIL-762`. The Developer said "coloca a
atividade Hero Brazil-762 para o status de pronto" and the app answered "No
task called 'Hero Brazil-762'". Nothing was misheard and nothing was misparsed:
`fold` normalises case and accents, so the comparison was
`herobrazil-762`.contains(`hero brazil-762`), and **one space** is the whole
failure. People spell identifiers out loud with spaces a tracker does not
write.

§6.3.1 as written says `taskRef` never guesses. Taken as "never approximate",
that rule makes every task whose title is an identifier unreachable by voice —
which is most of a developer's list.

**Decision.** A four-tier ladder (§6.3.1): exact, containment, **squashed**,
**approximate**. Each tier is exhausted before the next, so an exact match is
never beaten by a better-scoring approximate one, and a tie inside any tier is
still the question it is today.

Tier 3 is the one that fixes the reported case and it is **deterministic** —
squashing drops every non-alphanumeric rune, so `Hero Brazil-762` and
`HEROBRAZIL-762` are simply equal and no threshold is consulted. Tier 4,
normalised Damerau–Levenshtein over the squashed strings, exists for the harder
class: a Brazilian speaker's "Hero Brasil" against a title written
`HEROBRAZIL`.

**And digits are excluded from both approximate tiers.** If the phrase and a
candidate both carry digit runs and the sets differ, the candidate is dropped
before scoring:

```
herobrazil762  vs  herobrasil762   → 0.923   same chamado, spelled differently
herobrazil762  vs  herobrazil763   → 0.923   a different chamado
```

The scores are identical. No edit-distance metric distinguishes them, because
`s→z` and `2→3` cost the same to a metric and nothing at all to a metric's
author. Letters can be misheard and the error is audible; a number either
matches or the app asks. This is the rule that keeps "never guesses" true in
the sense that matters — never *act on the wrong row* — while dropping the
sense that was only ever an implementation detail.

**Rejected alternatives.**

- *Pass the task titles to the model as context*, the way `IntentContext`
  already carries `knownIssueKeys`, and let it do the matching. It fits the
  architecture without effort and rides after the cache breakpoint, so it costs
  no cache invalidation. Rejected on three counts: it moves a matching decision
  into a non-deterministic component whose failure mode is *inventing* a title
  rather than missing by a little; the token cost grows with the size of the
  list, and §15's p95 is already above target; and it sends the title of every
  task the user has to an external API on every command, which is a privacy
  expansion nobody asked for and which no business rule currently permits.
- *Phonetic matching (Soundex, Metaphone).* Built for English surnames. On a
  list mixing PT-BR, English and issue keys it collapses distinctions the user
  relies on, and there is no PT-BR implementation in the stack.
- *Match against the description and tags too.* Widens what a destructive
  command can hit, to solve a problem nobody has reported.
- *Lower the bar and let tier 4 always return its best candidate.* Turns
  `TaskNotFound` into a state that never occurs, which means the user is never
  told the app did not understand — they are told it did, about the wrong row.
- *Keep §6.3.1 literal and ask the user to rename their tasks.* The app exists
  to fit the way the Developer already works.

**Impact.** `docs/sprints/sprint-05b-task-ref-matching.md` (new);
`docs/architecture.md` §6.3.1, §14; `lib/domain/services/text_match.dart`;
`lib/application/voice/intent_router.dart`;
`lib/presentation/voice/voice_labels.dart` and the three ARB files.

---

## DEC-036 — Device-dependent manual passes move to an end-of-v1.0 acceptance run (Sprint 06)

**Status:** accepted · decided by the Developer on 2026-08-09.

**Context.** DEC-020 settled that "available platform" means **Windows and
Android** for every v1.0 manual script, and Sprint 04 closed its box on that
reading. Sprint 06 is the first sprint whose manual script cannot be satisfied
by the machine alone: a notification is delivered by an operating system, and
proving delivery with the app *swiped away* (step 9) or *after a reboot*
(step 10) needs a physical Android device in the Developer's hands. They do
not have one now, and will not for some time.

The choice was therefore between three things, and only one of them is honest:
block the sprint on hardware, tick a box for evidence nobody gathered, or move
the obligation somewhere it will actually be met and say so.

**Decision.** A manual step that **requires a device the Developer does not
currently hold** is deferred to a single **end-of-v1.0 acceptance pass**,
carried in `docs/sprints/sprint-08-hardening.md`. A sprint may close with such
a step outstanding, on three conditions:

1. **Every platform actually in hand is still verified in its own sprint.**
   Sprint 06 closes with all five Windows rows passing against the real OS,
   including the check on launch — deferral applies to the missing device, not
   to the manual pass as an idea.
2. **The deferred steps are written down as steps**, in the sprint's report and
   in the Sprint 08 acceptance list, with the numbers they had. "Test Android
   later" is not a deferral, it is a hope.
3. **Nothing automated is deferred, ever.** Gates G1–G6, the golden sets, the
   E2E suites and CI run in full every sprint, on every platform that can run
   them, exactly as before. This decision moves *human* verification of
   *device* behaviour; it grants no relief anywhere else, and a sprint that
   skipped a golden set under it would be misreading it.

The Developer is asked for these passes when the hardware is available; until
then no sprint claims them. iOS remains what DEC-020 made it — unverified,
pending a macOS host — and now shares one acceptance list with Android instead
of being tracked separately.

**Rejected alternatives.**

- *Block Sprint 06 until a device exists.* Blocks the project on hardware for
  behaviour whose Windows equivalent is already proven, and leaves finished,
  tested, CI-green work unmerged for an unknown number of weeks. It also makes
  every later sprint start from a stale `master`, which is how Sprint 05's
  worst afternoon began.
- *Redefine "available platform" as Windows only.* This is the tempting one and
  it is wrong: it would silently delete an obligation rather than move it, and
  DEC-020 exists precisely because a phrase nobody pins gets reinterpreted by
  whoever needs it to mean something convenient. v1.0 still owes Android a
  verified notification path.
- *Tick the box and note the gap in prose.* Sprint 05b's report says its PR
  should not merge until a manual pass is filled in; the PR merged anyway, and
  the box is still open on `master` two sprints later. A checklist that can be
  ticked on intent stops being a checklist.

**Impact.** `docs/sprints/sprint-08-hardening.md` (the acceptance list);
`docs/reports/sprint-06-report.md` §6 and §9; every future v1.0 manual script;
DEC-020, which stands — Android is still an available platform and still owed,
it is simply owed at a named moment.

---

## DEC-037 — The Copilot CLI is a remote engine, and `isLocal` says so (Sprint 07)

**Context.** `docs/architecture.md` §7.2 gives `CopilotCliEngine`
`capabilities.isLocal = true`, with a stated reason: the inference runs as a
local subprocess, so "data does not leave the machine". BR-07 uses exactly that
condition — and only that condition — to permit relaxing the PII redactor.

**The premise is false, and it was checked rather than assumed.** GitHub
Copilot CLI 1.0.78 was installed on the Developer's machine and run
non-interactively (`copilot -p … --output-format json`). Its own JSONL says what
it is: `session.auto_mode_resolved` chose `claude-haiku-4.5` from a
server-provided list, and the answer came back with `requestId`,
`serviceRequestId`, `apiCallId: msg_011…` and `premiumRequests: 0.33` billed to
the account. The CLI is a thin client. **The process is local; the inference is
not.** A transcript handed to it goes to GitHub's servers exactly as a
transcript handed to `ClaudeApiEngine` goes to Anthropic's.

**Decision.** `CopilotCliEngine` declares **`isLocal = false`**. The redactor
relaxation of BR-07 therefore never applies to it, the setting that would
disable redaction is not offered, and PII redaction stays enforced on both
engines in v1.0.

**Why this way round.** BR-07 is a rule about *where the user's data goes*, and
§7.2's `isLocal = true` is a claim about the same thing that happens to be
wrong. Honouring the rule means contradicting the document's literal text;
honouring the text means shipping a toggle that sends unredacted CPFs to a
third party under a justification that does not survive one command's output.
When a document and the world disagree about a fact, the world wins and the
document is corrected — and BR-07's own words ("with `isLocal == true`") are
satisfied here, not overridden: the condition is simply not met.

**Rejected alternatives.**

- *Implement §7.2 literally.* This is the deferential reading and it is the
  dangerous one. It converts a documentation error into a privacy defect that
  only fires when a user opts in, which is the hardest kind to notice: the
  toggle would be labelled with the reassurance that the data stays local,
  and the reassurance would be false.
- *Keep `isLocal = true` and disable the toggle anyway.* Leaves the wrong fact
  in the codebase for the next sprint to read and act on, having removed the
  one symptom that would have exposed it. A capability that lies and is worked
  around is worse than one that is corrected.
- *Add a third capability (`runsLocally` vs `dataStaysLocal`).* Precise, and
  premature: v1.0 has no engine for which the two differ in the other
  direction, and BR-07 needs one answer, not two.

**What this does not change.** Everything else Sprint 07 asks of the adapter
stands unaltered — the subprocess, the 30s watchdog, the BR-10 fallback chain,
the Windows-only availability, the settings section. `isLocal` is read by the
application layer for one purpose, and this decision changes only that answer.

**Impact.** `docs/architecture.md` §7.2 (the premise, corrected here rather
than silently); the sprint's S07-IT-01, whose "off + local → CPF passes intact"
scenario describes a state the app can no longer reach and is re-read in
`docs/reports/sprint-07-report.md`; the Settings UI, which shows no redaction
toggle. If a genuinely local engine is ever added (v1.1's gateway work, or an
on-device model), BR-07's relaxation becomes reachable again and this decision
does not stand in its way.
