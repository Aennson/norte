# Sprint 05 — Voz Realtime: Scribe, IntentParser, 5 Intenções e Confirmação

**Objetivo:** comandos por voz de ponta a ponta — streaming PCM ao `ScribeRealtimeEngine`, parsing de intenção via `AiEngine` (JSON estrito), roteamento para os use cases existentes e confirmação obrigatória para ações mutáveis.

**Referências obrigatórias:** `docs/arquitetura.md` §6, §9.2–9.3 · RN-04, RN-05, RN-06

---

## Critérios de entrada

- [ ] Sprint 04 com DoD completo.
- [ ] `FakeRealtimeTranscription` e dataset de intents (`test/fixtures/intents/ptbr_dataset.json`, ≥50 frases) criados.

## Escopo

**Dentro:** port `RealtimeTranscription` (§9.1); `ScribeRealtimeEngine` (WebSocket, PCM 16kHz mono, eventos `partial`/`committed`, VAD, reconexão com backoff + buffer ≤5s); captura de microfone em stream PCM; `IntentParser` sobre `AiEngine.parseIntent` (prompt cacheável, resposta somente JSON validada por schema); `IntentRouter` mapeando as 5 intenções (`updateJira`, `addComment`, `createTask`, `createReminder`, `queryStatus`) para os use cases das sprints anteriores (reminder: use case stub que só valida e delega à Sprint 06 — ver nota de escopo); `VoiceOverlay` (design system §4) com transcript parcial/committed; `ConfirmSheet` para RN-04; pergunta de slot faltante ("Qual ticket?"); configuração "sempre confirmar escritas Jira" (default on).

**Nota de escopo:** `createReminder` nesta sprint apenas cria a entidade `Reminder` persistida — o agendamento de notificação real é da Sprint 06.

**Fora:** TTS de respostas, agendamento de notificações, parsing de data/hora avançado além do que o `AiEngine` retorna nos slots.

## Regras de validação da sprint

- **RN-04:** `confidence < 0.75` → `ConfirmSheet` antes de qualquer ação mutável, sem exceção.
- Escritas no Jira confirmam **sempre** por default (configurável); `queryStatus` e `createTask` local com confidence ≥ 0.75 executam direto.
- **RN-06:** o stream PCM nunca é gravado em disco; buffer de reconexão vive só em memória e é limitado a 5s.
- Resposta do parser que não valide contra o schema JSON → `IntentType.unknown` → UI pede reformulação (nunca ação executada, nunca crash).
- Slots incompletos → app pergunta **apenas** o que falta e refaz o parse com o contexto.
- **RN-05:** intenções que escrevem no Jira passam pela outbox (reuso dos use cases da Sprint 02 — o router não cria caminho novo).
- Latência: pipeline instrumentado medindo t(fala committed → intent pronto); p95 registrado em log local de diagnóstico.

## Testes

#### S05-UT-01 — Parser: JSON válido
- **O que valida:** §6.2 (schema estrito).
- **Critérios de entrada:** `FakeAiEngine` retornando `{"intent":"updateJira","slots":{"issueKey":"PROJ-123","transition":"Done"},"confidence":0.92}`.
- **Ação:** `IntentParser.parse("muda o PROJ-123 pra concluído")`.
- **Critérios de saída:** `VoiceIntent` com type `updateJira`, slots exatos, confidence 0.92.

#### S05-UT-02 — Parser: JSON inválido → unknown
- **O que valida:** falha de parse segura.
- **Critérios de entrada:** fake retornando texto não-JSON, JSON sem campo `intent`, e intent fora do enum (3 cenários).
- **Ação:** parse de cada um.
- **Critérios de saída:** os 3 retornam `IntentType.unknown` com confidence 0; nenhuma exceção escapa.

#### S05-UT-03 — Router: confirmação por confiança
- **O que valida:** RN-04.
- **Critérios de entrada:** router com use cases espiões; intents `createTask` com confidence 0.74 e 0.76.
- **Ação:** rotear ambos.
- **Critérios de saída:** 0.74 → resultado "requer confirmação", use case **não** chamado; 0.76 → use case chamado direto.

#### S05-UT-04 — Router: Jira sempre confirma
- **O que valida:** regra de escrita Jira (§6.2).
- **Critérios de entrada:** intent `updateJira` com confidence 0.99; setting "sempre confirmar" on (default) e off (2 cenários).
- **Ação:** rotear.
- **Critérios de saída:** on → requer confirmação mesmo com 0.99; off → executa direto (via outbox).

#### S05-UT-05 — Slot faltante
- **O que valida:** pergunta dirigida (§6.2).
- **Critérios de entrada:** intent `updateJira` com slot `issueKey` ausente e `transition` presente.
- **Ação:** rotear.
- **Critérios de saída:** resultado "slot faltante: issueKey" com pergunta "Qual ticket?"; nenhum use case chamado; fornecendo o slot, o intent completo executa.

#### S05-UT-06 — Reconexão com buffer
- **O que valida:** §9.3 (buffer ≤5s em memória).
- **Critérios de entrada:** `ScribeRealtimeEngine` com WebSocket fake controlável; stream PCM sintético contínuo.
- **Ação:** derrubar a conexão por 3s durante fala; reconectar.
- **Critérios de saída:** áudio dos 3s é reenviado após reconexão (nenhuma perda); derrubar por 7s → apenas os últimos 5s retidos; nenhum byte escrito em disco (RN-06, verificado por FS espião).

#### S05-CT-01 — Contrato RealtimeTranscription
- **O que valida:** `ScribeRealtimeEngine` (WS fake) e `FakeRealtimeTranscription` no mesmo contrato.
- **Critérios de entrada:** suíte parametrizada; roteiro de eventos idêntico.
- **Ação:** `start(pcm)` → eventos → `stop()`.
- **Critérios de saída:** ambos emitem `partial`s seguidos de `committed` na mesma ordem semântica; `stop()` encerra o stream sem eventos posteriores.

#### S05-CT-02 — Contrato AiEngine (parseIntent)
- **O que valida:** shape de `parseIntent` nos adapters existentes (`ClaudeApiEngine` via servidor fake, `FakeAiEngine`).
- **Critérios de entrada:** mesmas 3 frases de teste.
- **Ação:** `parseIntent` em cada adapter.
- **Critérios de saída:** ambos retornam `VoiceIntent` válido contra o schema; falha de rede mapeia para o mesmo `Failure`.

#### S05-EV-01 — Eval do dataset PT-BR
- **O que valida:** acurácia do parsing (arquitetura §13; estratégia §5).
- **Critérios de entrada:** dataset ≥50 frases com gabarito (intent + slots), ≥10 ambíguas com gabarito `unknown`; `FakeAiEngine` com fixtures OU engine real em job manual.
- **Ação:** rodar o parser sobre todas as frases.
- **Critérios de saída:** intent ≥ 90% de acerto; slots exatos ≥ 85%; 100% das frases de gabarito `unknown` resultam em `unknown` (nenhuma vira ação); relatório de erros por frase gerado como artifact.

#### S05-GT-01 — VoiceOverlay e ConfirmSheet
- **O que valida:** componentes de voz (design system §4).
- **Critérios de entrada:** overlay com parcial em andamento; sheet com intent `updateJira` confidence 0.68.
- **Ação:** renderizar dark/light.
- **Critérios de saída:** goldens estáveis; parcial em `mono` `textSecondary`; sheet mostra ação interpretada + barra de confiança + botões.

#### S05-E2E-01 — "Muda o PROJ-123 pra concluído"
- **O que valida:** Pilar 3 completo com confirmação Jira.
- **Critérios de entrada:** app com fakes: realtime (roteiro emite committed "muda o PROJ-123 para concluído"), AiEngine (intent updateJira 0.92), Jira gateway com PROJ-123; task local vinculada.
- **Ação:** tocar botão de voz → fake emite eventos → `ConfirmSheet` aparece → confirmar.
- **Critérios de saída:** overlay mostrou parcial e committed; sheet mostrou "PROJ-123 → Done"; após confirmar, transition na outbox e despachada ao fake; cancelar (cenário B) → nada na outbox.

#### S05-E2E-02 — "Cria tarefa revisar PR do conector"
- **O que valida:** intent local sem confirmação.
- **Critérios de entrada:** fakes com committed "cria tarefa revisar PR do conector", intent `createTask` 0.95.
- **Ação:** comando de voz completo.
- **Critérios de saída:** task "revisar PR do conector" criada sem sheet de confirmação; toast/feedback de sucesso; task visível na aba Tarefas.

#### S05-E2E-03 — Frase ambígua
- **O que valida:** caminho `unknown`.
- **Critérios de entrada:** fake AiEngine retorna unknown para committed "faz aquilo lá que combinamos".
- **Ação:** comando de voz.
- **Critérios de saída:** UI pede reformulação; nenhuma task/outbox/reminder criado; novo comando na sequência funciona.

## Definition of Done

- [ ] Gates G1–G6 verdes; cobertura domain+application ≥ 90%.
- [ ] Todos os testes S05-* passando; eval S05-EV-01 no CI com fixtures.
- [ ] Latência p95 (committed → intent) medida com engine real em teste manual e registrada no relatório (meta < 3s — risco §15).
- [ ] Relatório `docs/relatorios/sprint-05-relatorio.md`.
