# Norte — Project Execution Documentation

**Norte** is a personal productivity assistant for developers (Flutter — Android, iOS, Windows): tasks with Jira linking, AI meeting summaries, intent-based voice commands, and voice reminders.

This folder contains **everything an executing AI needs to implement and test the project from scratch**, sprint by sprint, with no open decisions.

---

## 🤖 Instructions for the executing AI — read this first

1. **Mandatory reading order before writing any code:**
   1. [`architecture.md`](architecture.md) — the complete architecture (layers, domain, pillars, stack).
   2. [`project-rules.md`](project-rules.md) — **inviolable rules**: quality gates, dependency rule, business rules BR-01..BR-10, testing rules, Git workflow.
   3. [`design-system.md`](design-system.md) — mandatory visual tokens (inspired by Claude Code), components, and layout.
   4. [`testing-strategy.md`](testing-strategy.md) — pyramid, fakes, test case format, E2E, and evals.
2. **Project premise — languages (BR-11):** the system supports **English (en), Brazilian Portuguese (pt-BR), and Italian (it)**. Every user-facing string is a localized ARB resource from Sprint 00 on (English is the template/fallback); the three locales stay in key parity, enforced by test S00-UT-06 in every sprint.
3. **Execute the sprints in order** (00 → 08). Each sprint has *Entry Criteria* (verify before starting) and a *Definition of Done* (verify before closing). Do not mix sprint scopes.
   - **Mandatory Git workflow** ([`project-rules.md §7`](project-rules.md)): `master` is protected; every new feature is born on a **separate branch created as a worktree**; at the end of each sprint, a **PR to `master`** that is only merged with **GitHub Actions 100% green**. Commits authored by the Developer, the AI as a contributor (`Co-Authored-By`). **Premise: everything 100%** — no merge with a failing test, a warning, or a pending job.
4. **Every test is already specified** with an ID, "what it validates", entry criteria, and exit criteria. Implement exactly what is specified (you may add tests, never remove any) and name each test with its ID: `test('S01-UT-01: ...')`.
5. When a sprint is finished, write the report in `docs/reports/sprint-XX-report.md` with the evidence required by the DoD.
6. When in doubt between documents: `project-rules.md` > the sprint > the other documents.

## 📁 Documentation map

| Document | Contents |
|---|---|
| [`architecture.md`](architecture.md) | v1.0 architecture document (technical source of truth) |
| [`project-rules.md`](project-rules.md) | Gates G1–G6, dependency rule, BR-01..BR-11, Git workflow, prohibitions |
| [`design-system.md`](design-system.md) | Dark/light palette, typography, components, responsive layout |
| [`testing-strategy.md`](testing-strategy.md) | Test types, fakes/fixtures, specification format, evals |
| [`e2e/e2e-regression-plan.md`](e2e/e2e-regression-plan.md) | Global E2E suite crossing the pillars (REG-E2E-01..08) |
| `reports/` | Created during execution (sprint reports and decisions) |

## 🚀 Sprints (executable roadmap)

| Sprint | Delivery | Specified tests |
|---|---|---|
| [00 — Setup](sprints/sprint-00-setup.md) | Flutter project, theme/design system, l10n (en/pt-BR/it), fakes, CI, import check | S00: 6 UT · 2 GT · 1 IT · 1 E2E |
| [01 — Foundation](sprints/sprint-01-foundation.md) | Complete domain, Drift, reactive local Tasks CRUD | S01: 4 UT · 3 IT · 1 GT · 2 E2E |
| [02 — Jira](sprints/sprint-02-jira.md) | JiraLink, REST adapter, idempotent outbox, status divergence | S02: 4 UT · 4 IT · 1 CT · 1 GT · 2 E2E |
| [03 — Meetings](sprints/sprint-03-meetings.md) | Pasted transcript, templates, Claude summary, PII, ActionItems→Tasks | S03: 6 UT · 2 IT · 1 CT · 1 GT · 2 E2E |
| [04 — Whisper batch](sprints/sprint-04-whisper-batch.md) | Audio recording + batch transcription into the same pipeline | S04: 3 UT · 1 IT · 1 CT · 1 GT · 2 E2E |
| [05 — Realtime voice](sprints/sprint-05-realtime-voice.md) | Scribe realtime, IntentParser, 5 intents, confirmation | S05: 6 UT · 2 CT · 1 EV · 1 GT · 3 E2E |
| [06 — Reminders](sprints/sprint-06-reminders.md) | Voice reminders + notifications on all 3 platforms | S06: 4 UT · 2 IT · 1 GT · 2 E2E |
| [07 — Copilot CLI](sprints/sprint-07-copilot-cli.md) | Local Windows engine, watchdog, fallback, engine settings | S07: 5 UT · 1 CT · 1 IT · 1 GT · 2 E2E |
| [08 — Hardening](sprints/sprint-08-hardening.md) | LGPD, wipe, evals in CI, global regression, v1.0 release | S08: 2 UT · 2 IT · 1 GT · 2 E2E + REG suite |

## ✅ Gate summary (valid in every sprint)

```
flutter analyze                      # 0 warnings
dart format --set-exit-if-changed .  # formatted
dart run tool/check_imports.dart     # layers respected
flutter test --coverage              # 100% green; domain+application ≥ 90%
flutter test integration_test/       # sprint E2E green
```

Details and exact criteria: [`project-rules.md §2`](project-rules.md).
