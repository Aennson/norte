# Norte — Instructions for AI Assistants

Norte is a personal productivity assistant for developers (Flutter — Android, iOS, Windows): tasks with Jira linking, AI meeting summaries, intent-based voice commands, and voice reminders.

**This repository is executed sprint by sprint from its documentation. Nothing here is improvised.**

## Mandatory reading order (before writing any code)

1. `docs/architecture.md` — layers, domain, pillars, stack (technical source of truth).
2. `docs/project-rules.md` — quality gates G1–G6, layer dependency rule, business rules BR-01..BR-11, Git workflow. **This document is law.**
3. `docs/design-system.md` — visual tokens, components, layout (Claude Code-inspired).
4. `docs/testing-strategy.md` — test types, fakes, specification format, evals.
5. The current sprint file in `docs/sprints/` — execute sprints strictly in order (00 → 09; 00–08 deliver v1.0, 09 opens v1.1).

## Hard rules digest

- **Sprints in order**, each with Entry Criteria and a Definition of Done — both are objective checklists.
- **Every documented test** has an ID (`S0X-UT-NN`) with entry/exit criteria; implement exactly as specified, name tests with their ID, never remove or weaken one.
- **Layer rule:** `presentation → application → domain ← infrastructure`; wiring only in the composition root. Verified by `tool/check_imports.dart`.
- **Languages (BR-11):** en, pt-BR, it — every UI string from ARB resources, English is template/fallback, the 3 files stay in key parity.
- **Git:** never commit to `master`; one worktree per feature; end-of-sprint PR merged only with GitHub Actions 100% green. Commits authored by the Developer (`Aennson <aennson@gmail.com>`), AI as `Co-Authored-By` contributor.
- **Never:** real APIs in tests, secrets outside secure storage, persisting ephemeral transcripts/voice audio, auto-resolving local×Jira conflicts.

## Project skills (auto-loaded)

Skills in `.claude/skills/` load automatically when their activity comes up. Trust their triggers:

| Skill | Fires when you are... |
|---|---|
| `sprint-executor` | starting, executing, or closing a sprint |
| `test-spec` | writing or changing any test |
| `norte-design` | building or changing any UI |
| `git-flow` | branching, committing, merging, or opening a PR |

When in doubt between documents: `docs/project-rules.md` > the sprint file > everything else.
