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
