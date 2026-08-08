# Sprint 00 — Setup, Design System, and Test Infrastructure · Report

**Branch:** `claude/projeto-fase-um-mwxiqe` (see DEC-003) · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Repository empty or containing only `docs/` | `git ls-files` before the sprint listed `docs/`, `CLAUDE.md`, `README.md`, `.claude/` only | ✅ |
| Stable Flutter SDK 3.x, `flutter doctor` clean for the platforms available in the environment | `flutter doctor` → `[✓] Flutter (Channel stable, 3.44.9)`, `[✓] Connected device`, `[✓] Network resources`. None of the three target platforms (Android/iOS/Windows) is buildable on this Linux container — see §5 | ✅ (with the gap in §5) |

## 2. Quality gates

Every command below was run at `HEAD` of the sprint branch.

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 7.8s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --output=none --set-exit-if-changed .` | `Formatted 46 files (0 changed)` — exit 0 ✅ |
| G3 — tests | `flutter test` | `00:09 +67: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **100.0%** (13/13) · project **84.3%** (397/471) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match ✅ |
| E2E | `xvfb-run flutter test integration_test/` | green on the CI Linux desktop host — `✓ Built build/linux/x64/debug/bundle/norte`, 2/2 scenarios passing ✅ |

**CI evidence.** Workflow run
[#2](https://github.com/Aennson/norte/actions/runs/31226818154) on
`6e37da8` — all three jobs (`quality`, `test`, `e2e`) **success**. Run #1 failed
on a single E2E scenario that had not pinned the viewport; fixed on the branch
in `6e37da8` (no re-run was used to mask it).

**Coverage per layer**

| Layer | Lines | Coverage | Gate |
|---|---|---|---|
| `domain/` + `application/` | 13/13 | 100.0% | ≥ 90% ✅ |
| Project (all instrumented `lib/`) | 397/471 | 84.3% | ≥ 80% ✅ |

The sprint's Definition of Done waives the domain gate ("there is no domain"); it
is reported as met rather than skipped because `domain/failures/` and
`domain/ports/` shipped with the fakes and are fully covered.

## 3. Deliverables

| # | Deliverable | Status | Where |
|---|---|---|---|
| 1 | App compiles; `main.dart` is the composition root with `ProviderScope` | ⚠️ partial | `lib/main.dart` — compiles and boots under the test harness; no target platform buildable here (§5) |
| 2 | `NorteColors` (ThemeExtension, dark+light) + `NorteTypography` | ✅ | `lib/presentation/shared/theme/` |
| 3 | Shared components, each with a golden | ✅ | `norte_button.dart`, `norte_card.dart`, `status_badge.dart`, `empty_state.dart` |
| 4 | `go_router` with 4 destinations + voice button | ✅ | `lib/presentation/app/norte_router.dart`, `norte_shell.dart`, `lib/presentation/voice/voice_button.dart` |
| 5 | `test/fakes/` with the 6 fakes of testing-strategy §3 | ✅ | `test/fakes/` (+ `test/fakes/fakes_test.dart`) |
| 6 | `tool/check_imports.dart` — layer rule + literal colours | ✅ | `tool/check_imports.dart` |
| 7 | CI workflow analyze → format → check_imports → test → coverage | ✅ | `.github/workflows/ci.yml` |
| 8 | l10n scaffolding, 3 ARB files in key parity, English fallback | ✅ | `l10n.yaml`, `lib/l10n/` |

**Fakes.** `FakeClock` and `FakeNotificationScheduler` implement real ports in
`lib/domain/ports/`. The other four (`FakeAiEngine`, `FakeJiraGateway`,
`FakeBatchTranscription`, `FakeRealtimeTranscription`) use the provisional
interfaces the sprint permits (`test/fakes/ports/provisional_ports.dart`) because
their real signatures need `Meeting`, `Task` and `VoiceIntent` — entities the
sprint's "Out" scope forbids and that `architecture.md` §11 shows as still empty.
Each provisional port names the sprint that promotes it.

## 4. Sprint validation rules

| Rule | Result |
|---|---|
| Colour tokens are exactly the hexes of design-system §2 | ✅ — asserted token-by-token by S00-UT-01/02. The light `accent` and the new `onAccent` follow **DEC-001**, approved by the Developer and written back into `design-system.md` §2.1/§2.2/§4 |
| No screen uses a literal colour outside the theme | ✅ — enforced by `check_imports` (G5) and covered by S00-IT-01 |
| Folder structure identical to architecture §11 | ✅ — empty layers hold a `.gitkeep` |
| No hardcoded user-facing string | ✅ — every visible string resolves through `AppLocalizations`; parity enforced by S00-UT-06 |

## 5. Deviations and gaps

**Blocking: none.** The two items below are environment limits, recorded so the
Developer can close them locally.

1. **Target-platform builds were not verified.** Android, iOS and Windows are all
   unbuildable in this Linux container: the Android SDK download
   (`dl.google.com`) is refused by the environment's egress policy with HTTP 403,
   and iOS/Windows need their own hosts. Deliverable 1 is therefore evidenced by
   compilation + the app booting under the Flutter test harness (S00-E2E-01 boots
   the real `ProviderScope`/`NorteApp` tree), not by a platform artifact.
   **Action for the Developer:** run `flutter build apk --debug` and
   `flutter build windows --debug` locally once before merging.
2. **S00-E2E-01 could not be executed in this container** (resolved in CI). The
   Linux desktop host (DEC-004) builds until `sqlite3_flutter_libs` fetches the
   SQLite amalgamation from `sqlite.org`, which the same egress policy refuses.
   The `e2e` CI job runs the real thing on GitHub's runner, where that host is
   reachable: it built the Linux bundle and passed both scenarios on run #2.

3. **Windows needs the Visual Studio ATL component.** `flutter build windows`
   fails with `error C1083: Cannot open include file: 'atlstr.h'` from
   `flutter_secure_storage_windows` — ATL is not part of the default
   "Desktop development with C++" workload, and the current 4.2.2 release still
   requires it (DEC-007). One-time fix on the developer's machine:
   `vs_installer.exe modify --add Microsoft.VisualStudio.Component.VC.ATL`.
   Does not affect CI, which builds the Linux host for E2E.

**Decisions taken:** DEC-001 (`onAccent` token + darkened light accent),
DEC-002 (`lucide_icons_flutter`), DEC-003 (branch name), DEC-004 (Linux desktop
as E2E host), DEC-005 (plugin versions), DEC-006 (per-platform golden sets),
DEC-007 (ATL requirement) — all in `docs/reports/decisions.md`.

## 6. Tests

| ID | Title | Cases | Result |
|---|---|---|---|
| S00-UT-01 | Dark theme tokens | 1 | ✅ |
| S00-UT-02 | Light theme tokens | 1 | ✅ |
| S00-UT-03 | ThemeExtension lerp | 4 | ✅ |
| S00-UT-04 | AA contrast | 3 | ✅ |
| S00-UT-05 | Locale resolution and fallback | 6 | ✅ |
| S00-UT-06 | ARB key parity | 4 | ✅ |
| S00-GT-01 | Shared component goldens | 10 (5 × dark/light) | ✅ |
| S00-GT-02 | Navigation shell | 4 | ✅ |
| S00-IT-01 | check_imports detects a violation | 9 | ✅ |
| S00-E2E-01 | Navigation smoke test | 2 | ✅ (CI, Linux desktop host) |
| — | Fakes sanity suite (added under §5.4) | 24 | ✅ |

67 tests green under `flutter test`; 2 under `flutter test integration_test/`.
The 13 golden files are committed under
`test/presentation/goldens/images/linux/` — golden sets are per operating
system (DEC-006), and every golden test runs on every platform against its own
files, with no tolerance and nothing skipped.

## 7. Definition of Done

- [x] Gates G1–G6 green.
- [x] All S00-* tests implemented and passing — 67 under `flutter test`, 2 under
      `flutter test integration_test/`.
- [x] CI runs and passes on push — run #2, all three jobs green.
- [x] Report `docs/reports/sprint-00-report.md` created with evidence.

**Remaining to close the sprint** (`docs/project-rules.md` §7.3): open the
sprint PR to `master` and merge it only with Actions 100% green on the PR head.
The Developer should also run the platform builds listed in §5.1 first — that is
the one piece of deliverable 1 this environment could not produce.
