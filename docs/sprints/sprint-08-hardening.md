# Sprint 08 — Hardening: LGPD, Wipe, Evals in CI, and v1.0 Closure

**Objective:** harden security and privacy (BR-03/06/07/08 audit, "Delete everything"), consolidate the intent evals as a regression gate in CI, and close v1.0 with the complete E2E regression suite.

**Mandatory references:** `docs/architecture.md` §10, §13, §15 · BR-03, BR-06, BR-07, BR-08 · `docs/e2e/e2e-regression-plan.md`

---

## Entry criteria

- [ ] Sprints 00–07 with DoD complete.
- [ ] All S00–S07 tests green in CI.

## Scope

**In:** review/audit of the `PiiRedactor` (grow the PII dataset to ≥40 cases, including variants with punctuation and line breaks); "Delete everything" in Settings (wipe Drift + secure storage + temp files, with double confirmation); log audit (automated verification that no log contains a token/key/transcript/AI payload); the intent eval as a mandatory CI job; API usage counter in settings (risk §15 — cost); simple privacy policy/consent screens; execution and stabilization of the global E2E regression suite (`docs/e2e/e2e-regression-plan.md`); final accessibility review (semantic labels on the main buttons, keyboard navigation on Windows); **localization review (BR-11)**: manual pass through every screen in en, pt-BR, and it (no missing/overflowing/untranslated string), with the ARB parity test (S00-UT-06) green.

**Out:** certificate pinning (v1.1), Jira OAuth, multi-user.

## Sprint validation rules

- "Delete everything" is irreversible and complete: Drift zeroed, secure storage zeroed, temp directory cleaned, in-memory state reset (the app returns to its first-run state, including re-seeded templates).
- Double confirmation requiring the word "DELETE" to be typed (the pattern for a maximally destructive action).
- No existing test may be removed/weakened in this sprint; regressions found generate a test before the fix (rules §5).
- The eval job fails CI if accuracy drops below the thresholds (intent ≥ 90%, slots ≥ 85%).

## Tests

#### S08-UT-01 — Expanded PiiRedactor
- **What it validates:** BR-07 with an adversarial dataset.
- **Entry criteria:** dataset `test/fixtures/pii/cases.json` with ≥40 cases: CPFs valid/invalid-in-format, landline/mobile/with-country-code phones, e-mails with subdomains/+tag, PII glued to punctuation and broken across lines; ≥10 false positives (issue keys, dates, versions, CEP, CNPJ*).
- **Action:** redact all cases.
- **Exit criteria:** 100% of the ground-truth PII redacted; 0 false positives redacted. (*CNPJ is documented as out of scope for v1.0 — it must remain intact.)

#### S08-UT-02 — Complete wipe
- **What it validates:** the right to erasure (§10).
- **Entry criteria:** app with data everywhere: tasks (with JiraLink), meetings, scheduled reminders, edited templates, pending outbox, Jira token and Claude key in fake secure storage, a temp audio file.
- **Action:** execute the wipe use case.
- **Exit criteria:** all Drift tables empty; secure storage empty; temp empty; scheduler with no schedules; default templates re-seeded; usage counters zeroed.

#### S08-IT-01 — Automated log audit
- **What it validates:** BR-08 and §10 (redacted logs).
- **Entry criteria:** global logger captured; one flow from each pillar executed with fakes (summary, Jira sync, voice command, reminder) using sentinel values (`TOKEN_SENTINEL`, `KEY_SENTINEL`, transcript containing `SECRET_SENTINEL`).
- **Action:** run the flows and sweep the entire captured log.
- **Exit criteria:** no occurrence of any sentinel in the logs; `[REDACTED]` occurrences present where payloads were logged.

#### S08-IT-02 — Eval as a CI gate
- **What it validates:** architecture §13/§14.8 (regression evals).
- **Entry criteria:** CI workflow with the eval job; a dataset with 1 deliberately broken ground truth on a test branch.
- **Action:** run the job with the correct dataset and with the broken one.
- **Exit criteria:** correct dataset → green job with metrics published as an artifact; broken one below the threshold → the job fails the pipeline.

#### S08-GT-01 — Privacy and wipe screens
- **What it validates:** the consent UI and the maximally destructive action.
- **Entry criteria:** screens implemented.
- **Action:** golden dark/light of the privacy screen and the double-confirmation dialog.
- **Exit criteria:** stable goldens; the final wipe button uses the `error` color; the "DELETE" typing field is present.

#### S08-E2E-01 — Wipe end to end
- **What it validates:** erasure as seen by the user.
- **Entry criteria:** populated app (1 linked task, 1 saved meeting, 1 future reminder, fake credentials).
- **Action:** Settings → Delete everything → type "DELETE" → confirm → navigate through every tab.
- **Exit criteria:** every tab in `EmptyState`; Settings with no credentials; typing the wrong word (scenario B) keeps everything intact.

#### S08-E2E-02 — Global regression suite
- **What it validates:** the 6 pillars intact together.
- **Entry criteria:** all the scenarios in `docs/e2e/e2e-regression-plan.md` implemented.
- **Action:** run the full suite in CI (desktop) 3 consecutive times.
- **Exit criteria:** 3 runs 100% green (no flakes); total duration recorded in the report.

## Definition of Done — v1.0 closure

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%, project ≥ 80%.
- [ ] All S08-* tests passing; the eval mandatory in CI.
- [ ] Global E2E regression suite green 3× in a row.
- [ ] Compliance checklist completed in the report: BR-01 through BR-11, each with the ID of the test covering it.
- [ ] Manual localization pass (en, pt-BR, it) across every screen recorded in the report with evidence.
- [ ] Release builds produced for Android (APK), Windows (exe/msix), and iOS (if the environment is available) — artifacts attached/recorded.
- [ ] Final report `docs/reports/sprint-08-report.md` + `docs/reports/v1.0-release-notes.md`.
