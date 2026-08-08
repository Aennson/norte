---
name: sprint-executor
description: Use when starting, executing, or closing a Norte sprint (sprint-00 through sprint-09) — planning sprint work, checking entry criteria, delivering scope items, running quality gates, writing the sprint report, or preparing the end-of-sprint PR. Also use when asked "what's next" in this project.
---

# Executing a Norte sprint

## Before starting

1. Identify the current sprint: the lowest `docs/sprints/sprint-XX-*.md` whose Definition of Done is not yet fully met (check `docs/reports/`).
2. Read the sprint file top to bottom, plus `docs/project-rules.md`.
3. Verify **every Entry Criterion**. If one fails, fix the previous sprint first — never start on top of an incomplete DoD.
4. Open the sprint worktree per the `git-flow` skill (`sprint-XX/<slug>` from `master`).

## While executing

- Implement **only** what is in the sprint's "In" scope. Anything in "Out" or from a future sprint is forbidden, even if convenient.
- Follow the sprint's "Sprint validation rules" section as acceptance requirements, not suggestions.
- Implement every documented test (`test-spec` skill) — tests are part of the scope, not an afterthought.
- Commit small and often: `sprint-XX: <imperative description>` with the authorship rules from `docs/project-rules.md §7.1`.

## Before closing

Run all gates and record outputs for the report:

```bash
flutter analyze                      # 0 errors, 0 warnings
dart format --set-exit-if-changed .  # exit 0
dart run tool/check_imports.dart     # no layer violations
flutter test --coverage              # 100% green; domain+application ≥ 90%, project ≥ 80%
flutter test integration_test/       # sprint E2E green
```

Then:

1. Write `docs/reports/sprint-XX-report.md`: DoD checklist with evidence (command + result), coverage per layer, deviations (any deviation = sprint not complete).
2. Check every Definition of Done box. All boxes or no closure.
3. Open the end-of-sprint PR to `master` (`git-flow` skill). The sprint is complete only when GitHub Actions is 100% green and the PR is mergeable.
