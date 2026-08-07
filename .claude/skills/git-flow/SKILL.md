---
name: git-flow
description: Use before any git operation in the Norte project — creating branches or worktrees, committing, merging, pushing, or opening/closing the end-of-sprint pull request. Enforces worktree-per-feature, commit authorship, and the 100%-green-CI merge rule.
---

# Norte Git workflow

Full reference: `docs/project-rules.md §7`. Non-negotiables below.

## Setup (once per session)

```bash
git config user.name "Aennson"
git config user.email "aennson@gmail.com"
```

Commits are authored by the Developer; the AI signs as contributor with a trailer:

```
Co-Authored-By: <AI name> <AI noreply email>
```

## Branching — worktree per feature

- `master` is protected: **never** commit to it directly; the main checkout stays on `master`.
- Sprint branch as a worktree: `git worktree add ../norte-sprint-XX -b sprint-XX/<slug> master`
- Feature branches inside the sprint: `git worktree add ../norte-feat-<slug> -b feature/sprint-XX-<slug> sprint-XX/<slug>`
- A feature merges into the sprint branch only with gates G1–G6 green **in its worktree**; remove the worktree after merging (`git worktree remove`, `git worktree prune` at sprint end).

## Commits

- Format: `sprint-XX: <imperative description>`; small and frequent.
- Never commit: secrets/keys/tokens, real personal data in fixtures, generated coverage artifacts.

## End-of-sprint PR

1. One PR per sprint: `sprint-XX/<slug>` → `master`.
2. Description: delivered scope, completed DoD checklist, link to `docs/reports/sprint-XX-report.md` (committed on the branch).
3. **Merge only with GitHub Actions 100% green** — every job (analyze, format, check_imports, tests + coverage, goldens, E2E), no skips, no re-running to mask flakes (a flaky test is a bug: fix before merging).
4. Red CI → fix on the sprint branch, wait for a green run. The sprint is not complete until the PR is mergeable at 100%.
5. After merging, start the next sprint from updated `master`.
