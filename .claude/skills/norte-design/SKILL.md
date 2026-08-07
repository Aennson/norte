---
name: norte-design
description: Use when building or changing anything visual in the Norte app — screens, widgets, themes, colors, typography, layout, navigation, or UI strings. Enforces the Claude Code-inspired design system, the 4 mandatory screen states, WCAG AA, and the three-language localization premise.
---

# Building Norte UI

Full reference: `docs/design-system.md`. Non-negotiables below.

## Tokens, never literals

- All colors come from `NorteColors` (ThemeExtension, dark + light) in `presentation/shared/theme/` — the exact hex values in `docs/design-system.md §2`. `Color(0xFF...)` outside the theme files fails the import-check gate.
- Dark is the default theme. Every text/background pair ≥ 4.5:1 contrast (tested by S00-UT-04).
- Typography roles from `NorteTypography`: sans for prose, **JetBrains Mono for technical data** (issue keys, statuses, transcripts, timestamps, voice commands).

## Reuse the shared components

`NorteButton`, `NorteCard`, `StatusBadge`, `JiraChip`, `DivergenceBanner`, `VoiceOverlay`, `ConfirmSheet`, `EmptyState` — specified in `docs/design-system.md §4`. Do not hand-roll a variant of something that exists; extend the shared component instead.

## Every screen ships with

1. The **4 states**: loading (skeleton — never a full-screen spinner), empty (`EmptyState`), error (message + retry), content.
2. **Golden tests** for those states in dark + light, mobile (390×844) + desktop (1280×800).
3. Responsive behavior: bottom nav + floating voice button on mobile; navigation rail ≥ 900px; 4px spacing grid; screen padding 16 (mobile) / 24 (desktop).
4. Functional-only animations (≤200ms); no gradients, shadows, or decoration.

## UI strings (BR-11)

- Every user-facing string goes through `AppLocalizations` — no hardcoded literals, including placeholders and error messages.
- New string = key added to **all three** ARB files (`app_en.arb` template, `app_pt.arb`, `app_it.arb`) in the same commit; the parity test S00-UT-06 fails otherwise.
- Destructive actions use the `error` token and require confirmation; the maximally destructive wipe requires typed confirmation.
