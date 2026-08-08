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
