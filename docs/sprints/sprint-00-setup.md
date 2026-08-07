# Sprint 00 — Setup, Design System, and Test Infrastructure

**Objective:** create the cross-platform Flutter project skeleton with the layer structure, the visual theme (design system), the test fakes, and CI — the base upon which every following sprint runs.

**Mandatory references:** `docs/architecture.md` §2, §11 · `docs/design-system.md` · `docs/testing-strategy.md` · `docs/project-rules.md`

---

## Entry criteria

- [ ] Repository empty or containing only `docs/`.
- [ ] Stable Flutter SDK 3.x installed (`flutter doctor` with no errors for the target platforms available in the environment).

## Scope

**In:** Flutter project (Android/iOS/Windows enabled), folder structure from `docs/architecture.md §11`, stack dependencies (§2.1), dark+light theme with the design system tokens, shared components (`NorteButton`, `NorteCard`, `StatusBadge`, `EmptyState`), navigation shell (mobile bottom nav / desktop rail) with placeholder screens, **localization scaffolding (BR-11)**: `flutter_localizations` + `intl`, `l10n.yaml`, ARB files `app_en.arb` (template), `app_pt.arb`, `app_it.arb` with the shell's initial keys, app follows the device locale with fallback to English, test fakes, `tool/check_imports.dart` script, GitHub Actions CI.

**Out:** any business rule, real entities, persistence, network calls.

## Deliverables

1. App compiles and runs on the available platforms; `main.dart` is the composition root with `ProviderScope`.
2. `presentation/shared/theme/` with `NorteColors` (ThemeExtension, dark+light) and `NorteTypography` per `docs/design-system.md`.
3. Shared components listed in the scope, each with a golden test.
4. `go_router` navigation with 4 placeholder destinations (Tasks, Meetings, Reminders, Settings) + voice button (no function yet).
5. `test/fakes/` with the 6 fakes from `docs/testing-strategy.md §3` (provisional interfaces where the port does not exist yet are allowed **only** for fakes that depend on future sprints — in that case create the real port in `domain/ports/` right away).
6. `tool/check_imports.dart` — fails (exit ≠ 0) if any file violates the dependency rule from `docs/project-rules.md §3`, or if `Color(0x...)` appears outside `presentation/shared/theme/`.
7. CI workflow `.github/workflows/ci.yml`: analyze → format → check_imports → test → coverage gate.
8. l10n scaffolding (BR-11): the 3 ARB files in `lib/l10n/` with identical key sets covering every shell string; `AppLocalizations` wired in `MaterialApp`; unsupported locales fall back to English.

## Sprint validation rules

- Color tokens are **exactly** the hex values from `docs/design-system.md §2` — no invented colors.
- No screen uses a literal color outside the theme (verified by check_imports).
- Folder structure identical to `docs/architecture.md §11` (empty folders may hold a `.gitkeep`).
- No hardcoded user-facing string: every visible text goes through `AppLocalizations` (BR-11) — including the placeholder screens.

## Tests

#### S00-UT-01 — Dark theme tokens
- **What it validates:** dark palette fidelity to the design system.
- **Entry criteria:** `NorteColors.dark` instantiated.
- **Action:** read each token.
- **Exit criteria:** each token matches the hex in the `design-system.md §2.1` table (assert by value).

#### S00-UT-02 — Light theme tokens
- **What it validates:** light palette fidelity (§2.2).
- **Entry criteria:** `NorteColors.light` instantiated.
- **Action:** read each token.
- **Exit criteria:** all hex values match the §2.2 table.

#### S00-UT-03 — ThemeExtension lerp
- **What it validates:** theme transition does not break (ThemeExtension requirement).
- **Entry criteria:** dark and light instances.
- **Action:** `lerp(dark, light, 0.5)` and `copyWith()`.
- **Exit criteria:** no token is null; `lerp(a, b, 0) == a` and `lerp(a, b, 1) == b`.

#### S00-UT-04 — AA contrast
- **What it validates:** WCAG AA accessibility (design-system §2, final rule).
- **Entry criteria:** contrast-ratio function implemented in the test.
- **Action:** compute contrast for the pairs (`textPrimary`/`bg`, `textPrimary`/`surface`, `textSecondary`/`surface`, white/`accent`) in both themes.
- **Exit criteria:** all ≥ 4.5:1.

#### S00-UT-05 — Locale resolution and fallback
- **What it validates:** BR-11 (supported languages and fallback).
- **Entry criteria:** app configured with the 3 supported locales; a sample key present in the 3 ARB files with distinct values.
- **Action:** resolve `AppLocalizations` for `en`, `pt-BR`, `it`, and an unsupported locale (`fr`).
- **Exit criteria:** each supported locale returns its own translation for the sample key; `fr` resolves to the English value (fallback).

#### S00-UT-06 — ARB key parity
- **What it validates:** BR-11 (the three locales stay in parity). This test runs in every sprint from now on and fails whenever a key is added to fewer than 3 files.
- **Entry criteria:** the files `app_en.arb`, `app_pt.arb`, `app_it.arb` read from disk by the test.
- **Action:** compare the three key sets, each key's placeholder list, and value contents.
- **Exit criteria:** identical key sets across the 3 files; identical placeholders per key; no empty or whitespace-only value.

#### S00-GT-01 — Shared component goldens
- **What it validates:** appearance of `NorteButton` (4 states), `NorteCard`, `StatusBadge` (4 statuses), `EmptyState`.
- **Entry criteria:** bundled mono font loaded in the test; fixed surface size.
- **Action:** render each component in dark and light.
- **Exit criteria:** goldens generated and committed; subsequent runs pass with no diff.

#### S00-GT-02 — Navigation shell
- **What it validates:** responsive layout (design-system §5).
- **Entry criteria:** app shell with placeholder screens.
- **Action:** render at 390×844 (mobile) and 1280×800 (desktop).
- **Exit criteria:** mobile shows bottom nav with 4 items + voice button; desktop shows the navigation rail; stable goldens.

#### S00-IT-01 — check_imports detects a violation
- **What it validates:** gate G5 actually fails when it should.
- **Entry criteria:** temporary file in `domain/` importing `package:flutter/material.dart`, created by the test in a synthetic directory.
- **Action:** run the script's analysis over the synthetic directory.
- **Exit criteria:** the script reports the violation (and exit ≠ 0); after removing the file, it passes.

#### S00-E2E-01 — Navigation smoke test
- **What it validates:** app boots and navigates across the 4 destinations.
- **Entry criteria:** app started via `integration_test` with the default `ProviderScope`.
- **Action:** tap each navigation item.
- **Exit criteria:** each placeholder screen appears (expected title found); no exceptions in the log.

## Definition of Done

- [ ] Gates G1–G6 green (`docs/project-rules.md §2`); no domain coverage gate yet (there is no domain) — the ≥ 80% project gate applies to what exists.
- [ ] All S00-* tests implemented and passing.
- [ ] CI runs and passes on push.
- [ ] Report `docs/reports/sprint-00-report.md` created with evidence.
