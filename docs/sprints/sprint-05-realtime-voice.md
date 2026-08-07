# Sprint 05 — Realtime Voice: Scribe, IntentParser, 5 Intents, and Confirmation

**Objective:** end-to-end voice commands — PCM streaming to the `ScribeRealtimeEngine`, intent parsing via the `AiEngine` (strict JSON), routing to the existing use cases, and mandatory confirmation for mutating actions.

**Mandatory references:** `docs/architecture.md` §6, §9.2–9.3 · BR-04, BR-05, BR-06

---

## Entry criteria

- [ ] Sprint 04 DoD complete.
- [ ] `FakeRealtimeTranscription` and the intents dataset (`test/fixtures/intents/ptbr_dataset.json`, ≥50 utterances) created, plus the en/it smoke datasets (`en_dataset.json`, `it_dataset.json`, ≥10 utterances each — BR-11).

## Scope

**In:** `RealtimeTranscription` port (§9.1); `ScribeRealtimeEngine` (WebSocket, PCM 16kHz mono, `partial`/`committed` events, VAD, reconnection with backoff + ≤5s buffer); microphone capture as a PCM stream; `IntentParser` on top of `AiEngine.parseIntent` (cacheable prompt, JSON-only response validated against a schema); `IntentRouter` mapping the 5 intents (`updateJira`, `addComment`, `createTask`, `createReminder`, `queryStatus`) to the use cases from previous sprints (reminder: a stub use case that only validates and delegates to Sprint 06 — see the scope note); `VoiceOverlay` (design system §4) with partial/committed transcript; `ConfirmSheet` for BR-04; missing-slot question ("Which ticket?"); "always confirm Jira writes" setting (default on).

**Scope note:** in this sprint, `createReminder` only creates the persisted `Reminder` entity — actual notification scheduling belongs to Sprint 06.

**Out:** TTS responses, notification scheduling, date/time parsing beyond what the `AiEngine` returns in the slots.

## Sprint validation rules

- **BR-04:** `confidence < 0.75` → `ConfirmSheet` before any mutating action, no exceptions.
- Jira writes **always** confirm by default (configurable); `queryStatus` and local `createTask` with confidence ≥ 0.75 execute directly.
- **BR-06:** the PCM stream is never written to disk; the reconnection buffer lives only in memory and is capped at 5s.
- A parser response that does not validate against the JSON schema → `IntentType.unknown` → the UI asks the user to rephrase (never an executed action, never a crash).
- Incomplete slots → the app asks **only** for what is missing and re-parses with the context.
- **BR-05:** intents that write to Jira go through the outbox (reuse of the Sprint 02 use cases — the router creates no new path).
- Latency: pipeline instrumented measuring t(committed speech → intent ready); p95 recorded in the local diagnostics log.

## Tests

#### S05-UT-01 — Parser: valid JSON
- **What it validates:** §6.2 (strict schema).
- **Entry criteria:** `FakeAiEngine` returning `{"intent":"updateJira","slots":{"issueKey":"PROJ-123","transition":"Done"},"confidence":0.92}`.
- **Action:** `IntentParser.parse("muda o PROJ-123 pra concluído")`.
- **Exit criteria:** `VoiceIntent` with type `updateJira`, exact slots, confidence 0.92.

#### S05-UT-02 — Parser: invalid JSON → unknown
- **What it validates:** safe parse failure.
- **Entry criteria:** fake returning non-JSON text, JSON without the `intent` field, and an intent outside the enum (3 scenarios).
- **Action:** parse each one.
- **Exit criteria:** all 3 return `IntentType.unknown` with confidence 0; no exception escapes.

#### S05-UT-03 — Router: confidence-based confirmation
- **What it validates:** BR-04.
- **Entry criteria:** router with spy use cases; `createTask` intents with confidence 0.74 and 0.76.
- **Action:** route both.
- **Exit criteria:** 0.74 → "requires confirmation" result, use case **not** called; 0.76 → use case called directly.

#### S05-UT-04 — Router: Jira always confirms
- **What it validates:** the Jira write rule (§6.2).
- **Entry criteria:** `updateJira` intent with confidence 0.99; "always confirm" setting on (default) and off (2 scenarios).
- **Action:** route.
- **Exit criteria:** on → requires confirmation even at 0.99; off → executes directly (via the outbox).

#### S05-UT-05 — Missing slot
- **What it validates:** the targeted question (§6.2).
- **Entry criteria:** `updateJira` intent with the `issueKey` slot missing and `transition` present.
- **Action:** route.
- **Exit criteria:** "missing slot: issueKey" result with the question "Which ticket?"; no use case called; providing the slot, the complete intent executes.

#### S05-UT-06 — Reconnection with buffer
- **What it validates:** §9.3 (≤5s in-memory buffer).
- **Entry criteria:** `ScribeRealtimeEngine` with a controllable fake WebSocket; continuous synthetic PCM stream.
- **Action:** drop the connection for 3s mid-speech; reconnect.
- **Exit criteria:** the 3s of audio is re-sent after reconnection (no loss); dropping for 7s → only the last 5s retained; no byte written to disk (BR-06, verified by an FS spy).

#### S05-CT-01 — RealtimeTranscription contract
- **What it validates:** `ScribeRealtimeEngine` (fake WS) and `FakeRealtimeTranscription` under the same contract.
- **Entry criteria:** parameterized suite; identical event script.
- **Action:** `start(pcm)` → events → `stop()`.
- **Exit criteria:** both emit `partial`s followed by `committed` in the same semantic order; `stop()` closes the stream with no later events.

#### S05-CT-02 — AiEngine contract (parseIntent)
- **What it validates:** the `parseIntent` shape on the existing adapters (`ClaudeApiEngine` via fake server, `FakeAiEngine`).
- **Entry criteria:** the same 3 test utterances.
- **Action:** `parseIntent` on each adapter.
- **Exit criteria:** both return a `VoiceIntent` valid against the schema; a network failure maps to the same `Failure`.

#### S05-EV-01 — Multilingual intent dataset eval
- **What it validates:** parsing accuracy (architecture §13; strategy §5) across the supported languages (BR-11).
- **Entry criteria:** PT-BR dataset ≥50 utterances with ground truth (intent + slots), ≥10 ambiguous ones with `unknown` ground truth; en and it smoke datasets ≥10 utterances each with ground truth; `FakeAiEngine` with fixtures OR the real engine in a manual job.
- **Action:** run the parser over all utterances of the three datasets.
- **Exit criteria:** per dataset: intent accuracy ≥ 90%; exact slots ≥ 85%; 100% of the `unknown`-labeled utterances result in `unknown` (none becomes an action); a per-utterance error report generated as an artifact.

#### S05-GT-01 — VoiceOverlay and ConfirmSheet
- **What it validates:** the voice components (design system §4).
- **Entry criteria:** overlay with a partial in progress; sheet with an `updateJira` intent at confidence 0.68.
- **Action:** render dark/light.
- **Exit criteria:** stable goldens; partial in `mono` `textSecondary`; the sheet shows the interpreted action + a confidence bar + buttons.

#### S05-E2E-01 — "Move PROJ-123 to done" (spoken in PT-BR)
- **What it validates:** Pillar 3 complete with Jira confirmation.
- **Entry criteria:** app with fakes: realtime (script emits committed "muda o PROJ-123 para concluído"), AiEngine (updateJira intent, 0.92), Jira gateway with PROJ-123; linked local task.
- **Action:** tap the voice button → the fake emits events → `ConfirmSheet` appears → confirm.
- **Exit criteria:** the overlay showed partial and committed; the sheet showed "PROJ-123 → Done"; after confirming, the transition is in the outbox and dispatched to the fake; cancelling (scenario B) → nothing in the outbox.

#### S05-E2E-02 — "Create task: review the connector PR" (spoken in PT-BR)
- **What it validates:** a local intent without confirmation.
- **Entry criteria:** fakes with committed "cria tarefa revisar PR do conector", `createTask` intent 0.95.
- **Action:** complete voice command.
- **Exit criteria:** task "revisar PR do conector" created with no confirmation sheet; success toast/feedback; task visible in the Tasks tab.

#### S05-E2E-03 — Ambiguous utterance
- **What it validates:** the `unknown` path.
- **Entry criteria:** fake AiEngine returns unknown for committed "faz aquilo lá que combinamos" ("do that thing we agreed on").
- **Action:** voice command.
- **Exit criteria:** the UI asks the user to rephrase; no task/outbox/reminder created; a subsequent command works.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [ ] All S05-* tests passing; eval S05-EV-01 in CI with fixtures.
- [ ] p95 latency (committed → intent) measured with the real engine in a manual test and recorded in the report (target < 3s — risk §15).
- [ ] Report `docs/reports/sprint-05-report.md`.
