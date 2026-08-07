---
name: test-spec
description: Use when writing, implementing, changing, or debugging any test in the Norte project — unit, contract, integration, golden, E2E, or eval — or when creating fakes and fixtures. Ensures tests match their documented specification, IDs, and entry/exit criteria.
---

# Implementing Norte tests

Full reference: `docs/testing-strategy.md`. Non-negotiables below.

## Every documented test is a contract

- Each sprint file specifies tests with an ID (`S0X-UT-NN`, `CT`, `IT`, `GT`, `E2E`, `EV`), **what it validates**, **entry criteria**, **action**, and **exit criteria**.
- The test name in code starts with its ID: `test('S02-UT-03: outbox does not duplicate an operation with the same operationId', ...)`.
- Implement the entry criteria as setup/fixtures, the action as the body, and the exit criteria as asserts — every exit criterion becomes at least one assert.
- You may **add** tests; you may never remove, weaken, or `skip` a documented one.
- One test = one behavior.

## Determinism rules

- No network, no real clock (`FakeClock`/injected `DateTime.now`), no execution-order dependency, no randomness.
- Use the shared fakes in `test/fakes/` (`FakeAiEngine`, `FakeJiraGateway`, `FakeBatchTranscription`, `FakeRealtimeTranscription`, `FakeNotificationScheduler`, `FakeClock`) — extend them; do not create parallel ad-hoc fakes.
- Fixtures live in `test/fixtures/` with synthetic personal data only (never real CPFs/e-mails/phones).

## Per-type rules

- **UT:** domain/application only, ports mocked with `mocktail`.
- **CT:** one shared parameterized suite per port; every adapter of that port runs it (real adapter against a fake server + the fake adapter).
- **IT:** Drift `NativeDatabase.memory()`; HTTP against local fake servers.
- **GT:** dark + light, mobile + desktop sizes; the 4 screen states (loading/empty/error/content); bundled mono font loaded.
- **E2E:** real composition root + `ProviderScope(overrides: [...])` swapping only external adapters for fakes; assert both the UI effect and the system effect (DB row, outbox entry, fake call log); each scenario independent.
- **EV:** intent datasets in `test/fixtures/intents/` (pt-BR primary ≥50, en/it smoke ≥10 each); thresholds: intent ≥ 90%, exact slots ≥ 85%, `unknown` ground truth never becomes an action.

## Coverage and regressions

- Gates: domain+application ≥ 90%, project ≥ 80% (lines). A failing gate blocks the sprint.
- Found a bug? Write the regression test (with a new ID continuing the sprint's sequence) **before** the fix.
