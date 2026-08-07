# Norte — Testing Strategy

> Defines **how** every test in the project is specified, implemented, and executed.
> The sprints reference this document; in case of conflict, the rules in `docs/project-rules.md` prevail.

---

## 1. Test pyramid

```
        ▲  E2E (integration_test) — complete flows, fake adapters
       ▲▲  Golden — screens in the 4 states, dark + light
      ▲▲▲  Integration — in-memory Drift, fake HTTP, outbox
     ▲▲▲▲  Contract — all adapters of a port in the same suite
    ▲▲▲▲▲  Unit — domain + application, mocked ports (the vast majority)
```

| Type | ID | Tools | Location |
|---|---|---|---|
| Unit | `UT` | `flutter_test`, `mocktail` | `test/domain/`, `test/application/` |
| Contract | `CT` | shared suite parameterized per adapter | `test/contracts/` |
| Integration | `IT` | Drift `NativeDatabase.memory()`, `http_mock_adapter`/local fake server | `test/infrastructure/` |
| Golden | `GT` | golden files, dark+light, mobile+desktop sizes | `test/presentation/goldens/` |
| E2E | `E2E` | `integration_test/` + Riverpod overrides with fakes | `integration_test/` |
| Eval | `EV` | versioned PT-BR dataset in `test/fixtures/intents/` | `test/evals/` |

## 2. Mandatory test case specification format

Every test is **documented in the sprint before being implemented**, in this format:

```markdown
#### S0X-UT-NN — <short title>
- **What it validates:** <business rule (BR-xx) or behavior covered>
- **Entry criteria:** <initial state, fixtures, configured mocks>
- **Action:** <what is executed>
- **Exit criteria:** <objective asserts that define approval>
```

Rules:
1. The test name in code starts with the ID: `test('S03-UT-02: ...')`.
2. Exit criteria are **verifiable by asserts** — never "works correctly".
3. One test = one behavior. Multiple behaviors = multiple tests.
4. The executing AI may **add** tests beyond those specified, never remove or weaken the documented ones.

## 3. Fakes and fixtures (test foundation)

Created in Sprint 00 and evolved as needed. **Deterministic** — same input, same output, no randomness, no network:

| Fake | Behavior |
|---|---|
| `FakeAiEngine` | Responds from a fixture map `input → output`; records received calls; can simulate programmed latency, errors, and timeouts |
| `FakeJiraGateway` | In-memory state server with preloaded issues (`test/fixtures/jira_issues.json`); can simulate 401, 404, 429, and network loss |
| `FakeBatchTranscription` | Returns a fixed transcript for a given file; can simulate progress and errors |
| `FakeRealtimeTranscription` | Emits a scripted sequence of `partial`/`committed` events from a fixture; can simulate disconnection |
| `FakeNotificationScheduler` | Records schedules in an inspectable list; allows "firing" a notification manually |
| `FakeClock` | Injectable clock for reminder/sync tests |

Fixtures live in `test/fixtures/` (JSON/text), **with no real personal data** — sample CPFs/phones/e-mails must be synthetic (e.g.: a CPF valid in format only).

## 4. E2E tests — specific rules

1. Run with `flutter test integration_test/` (host: Linux/desktop in CI; Android emulator optional).
2. The app boots with the **real composition root**, replacing only the external adapters with fakes via `ProviderScope(overrides: [...])`. Drift uses an in-memory database.
3. Each E2E scenario is **independent**: it creates its own state in setup and does not depend on another scenario.
4. E2E asserts verify both the **user-observable effect** (widget present, text on screen) **and** the system effect (record in the database, operation in the outbox, call recorded in the fake).
5. Every critical flow has at least one **happy-path** scenario and one **failure** scenario (network down, AI unavailable, permission denied).

## 5. Intent evals (Sprints 05 and 08)

- Dataset `test/fixtures/intents/ptbr_dataset.json`: **minimum 50 utterances** in PT-BR (the product's voice-command language) with expected intent+slots, including ≥10 ambiguous/noisy ones with `unknown` as the expected result.
- The eval runs the `IntentParser` with `FakeAiEngine` (fixtures) in regular tests, and with the real engine **only** in a manual/optional CI job.
- Approval metrics: intent accuracy ≥ 90% on the dataset; exact slots ≥ 85%; no utterance labeled `unknown` may ever become a mutating action.

## 6. Coverage and CI

- `flutter test --coverage` + `lcov` — gates: domain+application ≥ 90%, project ≥ 80% (lines).
- CI pipeline (defined in Sprint 00, GitHub Actions): analyze → format → check_imports → test+coverage → goldens → desktop E2E.
- Golden failures attach the image diff as an artifact.
- A green CI is mandatory to close a sprint (evidence in the sprint report).

## 7. Manual tests (when unavoidable)

Platform features with no viable automation (real WinRT notification, iOS microphone permission) have a **manual script** documented in the sprint in the same format (entry/action/exit), executed and recorded in the sprint report with a screenshot/description of the result.
