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
