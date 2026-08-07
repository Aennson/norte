# Norte — Global E2E Regression Plan

> Suite executed in full in Sprint 08 (and on every release afterwards). Each scenario crosses **more than one pillar** —
> the per-feature E2E tests already live in the sprints. General E2E rules: `docs/testing-strategy.md §4`.
> Every scenario uses deterministic fake adapters and an in-memory database; none touches a real network.

**ID convention:** `REG-E2E-NN`. Each scenario is independent and prepares its own state in setup.

---

## REG-E2E-01 — The workday journey
- **What it validates:** Tasks + Jira + Voice integration (Pillars 1 and 3).
- **Entry criteria:** clean app; fake Jira with `PROJ-10` ("To Do") and `PROJ-11` ("In Progress"); scripted voice fakes.
- **Steps:** manually create task "Prepare demo" → link to `PROJ-10` → by voice: "move PROJ-10 to in progress" (spoken in PT-BR) → confirm in the sheet → by voice: "comment on PROJ-10: starting the demo" → confirm → status refresh.
- **Exit criteria:** the outbox dispatched the transition and the comment **in that order** (FIFO); `lastKnownStatus == "In Progress"`; the local task keeps its title and tags intact; no extra Jira field persisted (BR-09).

## REG-E2E-02 — A meeting becomes work
- **What it validates:** Meetings + Tasks + Jira (Pillars 2 and 1).
- **Entry criteria:** planning transcript fixture with 3 action items; fake AiEngine with the matching summary; fake Jira with no created issues.
- **Steps:** paste transcript → summarize (planning template) → convert the 3 action items into tasks → on the 1st task, "Create Jira issue from task" → save the summary and leave the screen.
- **Exit criteria:** 3 tasks with the `meeting` tag; issue creation in the outbox and dispatched (the fake records `POST /issue` 1×); transcript **not** persisted (default retention — BR-03); the saved summary present in the meetings list.

## REG-E2E-03 — Voice end to end with low confidence
- **What it validates:** BR-04 crossing Voice + Reminders (Pillars 3 and 5).
- **Entry criteria:** fakes: committed "remind me early tomorrow about that thing" (spoken in PT-BR), `createReminder` intent at confidence 0.62 with incomplete slots.
- **Steps:** voice command → confirmation sheet due to low confidence → confirm → the app asks for the missing time → answer "9 in the morning" → confirm.
- **Exit criteria:** nothing persisted before the confirmations; reminder created for tomorrow 09:00 and scheduled in the fake scheduler; audio absent from disk (BR-06).

## REG-E2E-04 — Fully offline → reconnection
- **What it validates:** offline-first (Pillar 1 + outbox) under accumulation.
- **Entry criteria:** app with 2 linked tasks; fake Jira in no-network mode from the start.
- **Steps:** transition task A via the UI, comment on task B by voice (confirming), create local task C — all offline → restore the network → wait for the dispatcher.
- **Exit criteria:** offline: 2 pending operations visible, task C created normally (local does not depend on the network — BR-01); online: both applied exactly once each (idempotency), the pending indicators disappear.

## REG-E2E-05 — Switching engines mid-flow
- **What it validates:** the AI abstraction (Pillar 4) transparent to the domain.
- **Entry criteria:** app "as Windows"; fake Copilot OK; fake Claude OK; preferred engine Copilot.
- **Steps:** summarize meeting A (Copilot answers) → in Settings switch to Claude → summarize meeting B → break the fake Claude and enable fallback → summarize meeting C.
- **Exit criteria:** A served by Copilot, B by Claude, C by Copilot via fallback (asserts on the fakes' counters); the 3 summaries with identical shape; switches logged (BR-10).

## REG-E2E-06 — Privacy from the first screen to the last
- **What it validates:** cross-cutting LGPD (BR-03, BR-06, BR-07, BR-08) + wipe.
- **Entry criteria:** clean app; transcript fixture containing a synthetic CPF, phone, and e-mail; sentinels configured in the fakes.
- **Steps:** configure fake credentials → summarize the meeting with the PII transcript → create a voice reminder → check the captured logs → run "Delete everything" (typing DELETE).
- **Exit criteria:** the remote engine received the transcript **without** plaintext PII; logs free of sentinels and credentials; after the wipe, database/secure storage/temp are empty and the app is in its first-run state.

## REG-E2E-07 — Voice resilience
- **What it validates:** Scribe realtime under connection failure (§9.3).
- **Entry criteria:** fake realtime scripted to disconnect for 2s mid-speech and reconnect.
- **Steps:** voice command "create task: validate the server backup" (spoken in PT-BR) with the drop in the middle → wait for reconnection and the committed event.
- **Exit criteria:** final transcript intact (no gap — reconnection buffer); task created with the full title; no audio on disk.

## REG-E2E-08 — Empty states and first use
- **What it validates:** the first-run experience across every tab.
- **Entry criteria:** freshly installed app (empty database, no credentials).
- **Steps:** navigate the 4 tabs → attempt a Jira action without credentials → attempt a summary without an API key.
- **Exit criteria:** each tab shows an `EmptyState` with a primary action; actions requiring credentials show an actionable error pointing to Settings (never a crash); the default templates exist in Settings.

---

## Suite approval criteria

1. 100% of the scenarios green in 3 consecutive CI runs (no flakes — a flaky scenario is a bug and blocks the release).
2. Total execution time ≤ 20 min on the CI runner.
3. Any scenario failing blocks the Sprint 08 closure / the release.
