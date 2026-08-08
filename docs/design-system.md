# Norte — Design System (inspired by Claude Code)

> Mandatory visual guide for the entire `presentation/` layer. The aesthetic is that of **Claude Code**:
> a modern terminal, warm dark background, coral/orange accent, monospaced typography for technical data,
> a dense yet calm interface. This document defines tokens that the executing AI must implement as
> `ThemeData`/`ThemeExtension` in Sprint 00 and use across all screens.

---

## 1. Visual principles

1. **Terminal-first:** the UI resembles a refined terminal — flat surfaces, slightly rounded corners (8px), no heavy shadows, 1px separators.
2. **A single accent:** coral `#D97757` is the only brand accent. States (success/error/warning) have their own discreet colors.
3. **Dark is the default theme.** Light exists and uses the warm ivory of the Anthropic palette.
4. **Mono for data, sans for prose:** issue keys (`PROJ-123`), statuses, timestamps, transcripts, and commands use a mono font; titles and running text use sans.
5. **Calm density:** spacing on a 4px scale; no gradients, glassmorphism, or decorative animations. Animations are functional only (≤200ms, standard Material curves).

## 2. Color palette (tokens)

### 2.1 Dark theme (default)

| Token | Hex | Usage |
|---|---|---|
| `bg` | `#1F1E1D` | Main app background |
| `surface` | `#262624` | Cards, fields, panels |
| `surfaceRaised` | `#30302E` | Hover, selected items, modals |
| `border` | `#3E3E3A` | Separators and 1px borders |
| `textPrimary` | `#F5F4EF` | Primary text |
| `textSecondary` | `#A8A79E` | Supporting text, metadata |
| `textMuted` | `#6E6D66` | Placeholders, disabled |
| `accent` | `#D97757` | Primary buttons, links, focus, active icon |
| `onAccent` | `#1F1E1D` | Text/icon drawn on top of `accent` (5.33:1 — DEC-001) |
| `accentHover` | `#E08B6D` | Accent hover/pressed |
| `accentSubtle` | `#3A2A22` | Background of accent chips/highlights |
| `success` | `#7BAE7F` | Completed task, sync ok |
| `warning` | `#D9A45B` | Local×Jira divergence, low confidence |
| `error` | `#C4553D` | Failures, destructive actions |
| `info` | `#6A9BCC` | Informational states, Jira links |

### 2.2 Light theme

| Token | Hex | Usage |
|---|---|---|
| `bg` | `#FAF9F5` | Main background (ivory) |
| `surface` | `#FFFFFF` | Cards, fields |
| `surfaceRaised` | `#F0EEE6` | Hover, selected |
| `border` | `#E3E1D9` | Separators |
| `textPrimary` | `#191919` | Primary text |
| `textSecondary` | `#5E5D59` | Supporting text |
| `textMuted` | `#9B9A94` | Placeholders |
| `accent` | `#BA5B3B` | Accent (darkened coral for AA contrast — DEC-001) |
| `onAccent` | `#FFFFFF` | Text/icon drawn on top of `accent` (4.52:1 — DEC-001) |
| `accentHover` | `#D97757` | Hover |
| `accentSubtle` | `#F6E3DB` | Chips/highlights |
| `success` | `#4E7D52` | — |
| `warning` | `#A97B2F` | — |
| `error` | `#B03A24` | — |
| `info` | `#3E6C99` | — |

**Rule:** every text/background pair must reach **WCAG AA contrast (≥4.5:1)** for normal text. This is verified by a test (S00-UT-04).

**Text on the accent** uses the `onAccent` token, never a literal white — no single ink reaches AA on both accents. See `docs/reports/decisions.md` — **DEC-001**.

## 3. Typography

| Role | Font | Size/weight | Usage |
|---|---|---|---|
| `display` | Sans (Inter or system) | 24 / w600 | Screen title |
| `title` | Sans | 17 / w600 | Card/section title |
| `body` | Sans | 14.5 / w400 | Running text |
| `caption` | Sans | 12 / w400, `textSecondary` | Metadata, relative timestamps |
| `mono` | JetBrains Mono (bundled) | 13 / w400 | Issue keys, statuses, transcripts, recognized voice commands |
| `monoSmall` | JetBrains Mono | 11 / w500, uppercase, letter-spacing 0.6 | Status badges |

## 4. Standard components

Implemented in `presentation/shared/` in Sprint 00 and reused across the app:

| Component | Specification |
|---|---|
| `NorteButton` | Primary: `accent` background, `onAccent` text, radius 8, height 40. Secondary: 1px `border` outline, `textPrimary` text. Destructive: `error` background. States: hover (`accentHover`), disabled (50% opacity), loading (16px spinner replaces label) |
| `NorteCard` | `surface` background, 1px `border`, radius 8, padding 16 |
| `StatusBadge` | `monoSmall` + 6px dot on the left. Colors: todo=`textMuted`, inProgress=`info`, done=`success`, blocked=`error` |
| `JiraChip` | `mono` font, `accentSubtle` background, `accent` text, issueKey prefix (e.g.: `PROJ-123`); tap opens the link action |
| `DivergenceBanner` | `warning` background at 15% opacity, 3px left border in `warning`, text explaining local vs. Jira status + two decision buttons (BR-02) |
| `VoiceOverlay` | Bottom panel styled like a terminal prompt: `surface` background, `❯` prefix in `accent`, partial transcript in `mono` `textSecondary`, committed in `textPrimary` |
| `ConfirmSheet` | Bottom sheet used for intent confirmation (BR-04): shows the interpreted action in `mono`, confidence as a bar, Confirm (`accent`) / Cancel buttons |
| `EmptyState` | 32px `textMuted` icon + short sentence + optional primary action |

## 5. Layout and navigation

- **Mobile:** bottom navigation with 4 destinations — Tasks, Meetings, Reminders, Settings. A central floating voice button (`accent` circle, mic icon) present on every tab.
- **Windows/desktop (≥ 900px):** navigation rail on the left (72px collapsed), content in a centered column max. 840px. Voice button on the rail.
- Spacing grid: multiples of 4 (4/8/12/16/24/32). Default screen padding: 16 (mobile) / 24 (desktop).
- Icons: `lucide_icons` (1.5px stroke, consistent with the terminal aesthetic).

## 6. Mandatory states for every screen

Every screen implements and tests (golden) the 4 states: **loading** (skeleton, never a full-screen spinner), **empty** (`EmptyState`), **error** (message + retry), and **content**.

## 7. Implementation (Sprint 00)

- Tokens in `presentation/shared/theme/norte_colors.dart` as `ThemeExtension<NorteColors>` (dark + light).
- Typography in `norte_typography.dart`; components in `presentation/shared/widgets/`.
- **Forbidden** to use literal colors (`Color(0xFF...)`) outside the theme files — gate verified by grep in G5/S00.
