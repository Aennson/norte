# Norte — Recommended AI Tooling (Plugins & Skills)

How the executing AI (Claude Code or compatible) should be equipped to run this project with excellence.

---

## 1. Project skills — auto-loaded from this repository

These live in `.claude/skills/` and are **discovered automatically** by Claude Code when the repository is opened. Each skill triggers on its own activity — no manual invocation needed (they can also be forced with `/skill-name`):

| Skill | Auto-triggers when | Enforces |
|---|---|---|
| `sprint-executor` | starting/executing/closing a sprint | entry criteria → scope → gates G1–G6 → report → PR |
| `test-spec` | writing or changing any test | test IDs, entry/exit criteria as asserts, fakes, determinism, coverage |
| `norte-design` | building or changing any UI | design tokens, shared components, 4 states, goldens, WCAG AA, BR-11 strings |
| `git-flow` | branching/committing/merging/PRs | worktree-per-feature, authorship, 100%-green-CI merges |

`CLAUDE.md` at the repository root is loaded on every session and indexes both the documentation and these skills.

**Rule:** keep the skills in sync with `docs/`. If a rule changes in `docs/project-rules.md`, update the corresponding skill in the same commit.

## 2. Built-in Claude Code skills worth using

Available out of the box in Claude Code (no installation):

| Skill / command | Use in this project |
|---|---|
| `/code-review` | Before each end-of-sprint PR: review the sprint diff for correctness bugs at high effort |
| `/security-review` | Sprints 02 (Jira credentials), 03 (BYOK key), and 08 (hardening): review pending changes for security issues |
| `/simplify` | After a sprint's scope is green: reuse/simplification pass without behavior changes |
| `/init`-style repo docs | Already covered by `CLAUDE.md` — do not regenerate over it |

## 3. Marketplace plugins (claude.ai catalog)

From the organization's plugin catalog, these add value; install/enable via the plugin manager (`/plugin`) or the claude.ai plugin settings:

| Plugin | Status | Why it helps here |
|---|---|---|
| **Engineering** (`engineering`) | recommended — enable | `/engineering:review` for PR reviews, `/engineering:architecture` for decision records in `docs/reports/decisions.md`, tech-debt audit before v1.1 planning |
| **Design** (`design`) | recommended — enable | `/design:accessibility` for the WCAG AA audit (S00-UT-04 complements, Sprint 08 review), `/design:critique` on the main screens, `/design:ux-copy` for the three-language UI strings |

No Flutter-specific plugin exists in the catalog today; the project skills in §1 fill that role and are the authoritative source when they conflict with a generic plugin's advice.

## 4. Order of authority

When guidance conflicts:

```
docs/project-rules.md  >  sprint file  >  project skills (.claude/skills/)  >  built-in/marketplace plugins
```

Plugins and skills are accelerators — they never override a documented rule.
