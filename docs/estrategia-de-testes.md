# Norte — Estratégia de Testes

> Define **como** todo teste do projeto é especificado, implementado e executado.
> As sprints referenciam este documento; em conflito, as regras de `docs/regras-do-projeto.md` prevalecem.

---

## 1. Pirâmide de testes

```
        ▲  E2E (integration_test) — fluxos completos, adapters fake
       ▲▲  Golden — telas nos 4 estados, dark + light
      ▲▲▲  Integration — Drift em memória, HTTP fake, outbox
     ▲▲▲▲  Contract — todos os adapters de um port na mesma suíte
    ▲▲▲▲▲  Unit — domain + application, ports mockados (maioria absoluta)
```

| Tipo | ID | Ferramentas | Onde vive |
|---|---|---|---|
| Unit | `UT` | `flutter_test`, `mocktail` | `test/domain/`, `test/application/` |
| Contract | `CT` | suíte compartilhada parametrizada por adapter | `test/contracts/` |
| Integration | `IT` | Drift `NativeDatabase.memory()`, `http_mock_adapter`/servidor fake local | `test/infrastructure/` |
| Golden | `GT` | golden files, dark+light, mobile+desktop sizes | `test/presentation/goldens/` |
| E2E | `E2E` | `integration_test/` + Riverpod overrides com fakes | `integration_test/` |
| Eval | `EV` | dataset PT-BR versionado em `test/fixtures/intents/` | `test/evals/` |

## 2. Formato obrigatório de especificação de caso de teste

Todo teste é **documentado na sprint antes de ser implementado**, neste formato:

```markdown
#### S0X-UT-NN — <título curto>
- **O que valida:** <regra de negócio (RN-xx) ou comportamento coberto>
- **Critérios de entrada:** <estado inicial, fixtures, mocks configurados>
- **Ação:** <o que é executado>
- **Critérios de saída:** <asserts objetivos que definem aprovação>
```

Regras:
1. O nome do teste no código começa com o ID: `test('S03-UT-02: ...')`.
2. Critérios de saída são **verificáveis por assert** — nunca "funciona corretamente".
3. Um teste = um comportamento. Vários comportamentos = vários testes.
4. A IA executora pode **adicionar** testes além dos especificados, nunca remover ou enfraquecer os documentados.

## 3. Fakes e fixtures (fundação dos testes)

Criados na Sprint 00 e evoluídos conforme necessário. **Determinísticos** — mesma entrada, mesma saída, sem aleatoriedade nem rede:

| Fake | Comportamento |
|---|---|
| `FakeAiEngine` | Responde a partir de um mapa fixture `input → output`; registra chamadas recebidas; permite simular latência, erro e timeout programados |
| `FakeJiraGateway` | Servidor de estado em memória com issues pré-carregadas (`test/fixtures/jira_issues.json`); permite simular 401, 404, 429 e queda de rede |
| `FakeBatchTranscription` | Retorna transcript fixo para arquivo dado; simulável: progresso, erro |
| `FakeRealtimeTranscription` | Emite sequência roteirizada de eventos `partial`/`committed` a partir de fixture; simulável: desconexão |
| `FakeNotificationScheduler` | Registra agendamentos em lista inspecionável; permite "disparar" notificação manualmente |
| `FakeClock` | Relógio injetável para testes de lembrete/sync |

Fixtures ficam em `test/fixtures/` (JSON/텍스트), **sem dados pessoais reais** — CPFs/telefones/e-mails de exemplo devem ser sintéticos (ex.: CPF gerado válido apenas em formato).

## 4. Testes E2E — regras específicas

1. Rodam com `flutter test integration_test/` (host: Linux/desktop no CI; Android emulator opcional).
2. O app sobe com o **composition root real**, trocando apenas os adapters externos por fakes via `ProviderScope(overrides: [...])`. Drift usa banco em memória.
3. Cada cenário E2E é **independente**: cria seu próprio estado no setup e não depende de outro cenário.
4. Asserts de E2E verificam **efeito observável pelo usuário** (widget presente, texto na tela) **e** efeito de sistema (registro no banco, operação na outbox, chamada registrada no fake).
5. Todo fluxo crítico tem ao menos um cenário de **caminho feliz** e um de **falha** (rede fora, IA indisponível, permissão negada).

## 5. Evals de intent (Sprint 05 e 08)

- Dataset `test/fixtures/intents/ptbr_dataset.json`: **mínimo 50 frases** em PT-BR com intent+slots esperados, incluindo ≥10 ambíguas/ruidosas marcadas como `unknown` esperado.
- O eval roda o `IntentParser` com `FakeAiEngine` (fixtures) nos testes normais, e com engine real **apenas** em job de CI manual/opcional.
- Métrica de aprovação: acurácia de intent ≥ 90% no dataset; slots exatos ≥ 85%; nenhuma frase marcada `unknown` pode virar ação mutável.

## 6. Cobertura e CI

- `flutter test --coverage` + `lcov` — gates: domain+application ≥ 90%, projeto ≥ 80% (linhas).
- Pipeline de CI (definido na Sprint 00, GitHub Actions): analyze → format → check_imports → test+coverage → goldens → E2E desktop.
- Golden failures anexam diff de imagem como artifact.
- CI é obrigatório verde para fechar sprint (evidência no relatório da sprint).

## 7. Testes manuais (quando inevitáveis)

Recursos de plataforma sem automação viável (notificação WinRT real, permissão de microfone iOS) têm **roteiro manual** documentado na sprint no mesmo formato (entrada/ação/saída), executado e registrado no relatório da sprint com screenshot/descrição do resultado.
