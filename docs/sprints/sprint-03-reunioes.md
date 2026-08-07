# Sprint 03 — Reuniões: Transcrição Colada, Templates, Resumo IA e ActionItems→Tasks

**Objetivo:** pipeline completo de resumo de reuniões a partir de transcrição **colada** pelo usuário: templates configuráveis, redação de PII, `ClaudeApiEngine.summarize`, revisão do resumo e conversão de action items em tasks com 1 toque.

**Referências obrigatórias:** `docs/arquitetura.md` §5, §7.1–7.2 (ClaudeApiEngine) · RN-03, RN-07, RN-08

---

## Critérios de entrada

- [ ] Sprint 02 com DoD completo.
- [ ] `FakeAiEngine` com fixtures de resumo (`test/fixtures/summaries/`).

## Escopo

**Dentro:** port `AiEngine` completo (interface de `arquitetura.md §7.1`); `ClaudeApiEngine` (dio, `POST /v1/messages`, system prompt com prompt caching, streaming para resumos, BYOK — key em secure storage + campo em Ajustes); `PiiRedactor` (regex BR: CPF, telefone, e-mail); entidades `MeetingSummary`, `ActionItem`, `TemplateSection`; templates em Drift com os 4 padrões embarcados (daily, retro, planning, 1:1) + CRUD de templates em Ajustes; use case `SummarizeMeeting`; use case `ConvertActionItemToTask`; telas: nova reunião (colar texto, escolher tipo, toggle "salvar transcrição"), resultado do resumo por seções, lista de reuniões salvas.

**Fora:** gravação de áudio/Whisper (Sprint 04), `CopilotCliEngine` (Sprint 07).

## Regras de validação da sprint

- **RN-03:** default `retention = ephemeral` — transcript nunca toca o Drift a menos que o usuário ative "salvar transcrição" antes de processar; ao sair da tela de resultado, o transcript efêmero é descartado (só o summary salvo permanece, se o usuário salvou).
- **RN-07:** `SummarizeMeeting` aplica `PiiRedactor` **antes** de chamar `AiEngine` sempre que `capabilities.isLocal == false`.
- Template é dado, não código: o `systemPrompt` enviado como system message; transcript como user message; seções do template devem estruturar o output.
- `ClaudeApiEngine` sem API key configurada → `MissingApiKeyFailure` com mensagem que direciona a Ajustes (nunca crash).
- Resposta da IA malformada (JSON de resumo inválido) → 1 retry; persistindo, `AiResponseFailure` com opção de tentar de novo — nunca resumo parcial silencioso.
- Cada `ActionItem` convertido gera task com título do item, tag `reunião` e referência ao meeting id (se salvo); conversão é individual e marcada visualmente como "já convertido".

## Testes

#### S03-UT-01 — Redação de PII (padrões BR)
- **O que valida:** RN-07 (regex).
- **Critérios de entrada:** `PiiRedactor`; texto fixture com 2 CPFs (com e sem máscara), 3 telefones (`+55`, `(11) 9...`, `11987654321`), 2 e-mails, e falsos-positivos próximos (datas, issue keys `PROJ-123`, versões `1.2.3`).
- **Ação:** redigir.
- **Critérios de saída:** todos os PII substituídos por `[CPF]`/`[TELEFONE]`/`[EMAIL]`; falsos-positivos intactos; texto restante inalterado.

#### S03-UT-02 — Redação aplicada antes da IA
- **O que valida:** RN-07 (integração no use case).
- **Critérios de entrada:** `SummarizeMeeting` com `FakeAiEngine` espião (`isLocal == false`); transcript com CPF.
- **Ação:** executar.
- **Critérios de saída:** o texto recebido pelo engine não contém o CPF (contém `[CPF]`); com engine `isLocal == true`, o texto chega íntegro.

#### S03-UT-03 — Template estrutura o prompt
- **O que valida:** §5.3 (template como dado).
- **Critérios de entrada:** template retro com 3 seções; `FakeAiEngine` espião.
- **Ação:** `SummarizeMeeting` com esse template.
- **Critérios de saída:** system prompt enviado == `systemPrompt` do template; user message == transcript redigido; flag de extração de action items respeitada.

#### S03-UT-04 — Retenção efêmera
- **O que valida:** RN-03.
- **Critérios de entrada:** meeting com `retention = ephemeral`; repositório de meetings espião.
- **Ação:** resumir e salvar o summary.
- **Critérios de saída:** objeto persistido tem `rawTranscript` vazio/nulo; com `retention = persisted`, transcript é persistido.

#### S03-UT-05 — ActionItem → Task
- **O que valida:** conversão com 1 toque.
- **Critérios de entrada:** summary com action item "Atualizar runbook".
- **Ação:** `ConvertActionItemToTask`.
- **Critérios de saída:** task criada com título "Atualizar runbook", status `todo`, tag `reunião`; item marcado como convertido; segunda conversão do mesmo item é rejeitada (`AlreadyConvertedFailure`).

#### S03-UT-06 — Resposta malformada da IA
- **O que valida:** política de retry/erro.
- **Critérios de entrada:** `FakeAiEngine` programado: 1ª resposta inválida, 2ª válida (cenário A); ambas inválidas (cenário B).
- **Ação:** `SummarizeMeeting`.
- **Critérios de saída:** A → summary válido com exatamente 2 chamadas; B → `AiResponseFailure` após 2 chamadas, nenhum summary persistido.

#### S03-IT-01 — ClaudeApiEngine: request e caching
- **O que valida:** conformidade com a API de Messages + prompt caching (§7.2).
- **Critérios de entrada:** servidor HTTP fake capturando o request; key fake em secure storage fake.
- **Ação:** `summarize()`.
- **Critérios de saída:** POST `/v1/messages` com headers de auth e versão; system prompt marcado com `cache_control`; transcript na user message; resposta do fake parseada em `MeetingSummary` correto.

#### S03-IT-02 — Templates padrão embarcados
- **O que valida:** seed dos 4 templates.
- **Critérios de entrada:** banco em memória recém-criado.
- **Ação:** inicializar o repositório de templates.
- **Critérios de saída:** daily, retro, planning e 1:1 presentes com seções conforme §5.3; re-inicializar não duplica; template editado pelo usuário não é sobrescrito pelo seed.

#### S03-CT-01 — Contrato AiEngine (summarize)
- **O que valida:** `ClaudeApiEngine` (servidor fake) e `FakeAiEngine` retornam o mesmo shape.
- **Critérios de entrada:** suíte de contrato com transcript e template fixos.
- **Ação:** `summarize()` em cada adapter.
- **Critérios de saída:** ambos retornam `MeetingSummary` com as seções do template e lista (possivelmente vazia) de action items; erros mapeados nos mesmos `Failure`s.

#### S03-GT-01 — Telas de reunião
- **O que valida:** telas nova reunião e resultado nos 4 estados (design system §6).
- **Critérios de entrada:** providers overridados por estado.
- **Ação:** renderizar dark/light.
- **Critérios de saída:** goldens estáveis; seções do resumo em `NorteCard`; action items com botão de conversão; transcript exibido em fonte `mono`.

#### S03-E2E-01 — Colar → resumir → converter
- **O que valida:** pipeline completo do Pilar 2.
- **Critérios de entrada:** app com `FakeAiEngine` (fixture de retro com 2 action items); transcript de retro em fixture.
- **Ação:** nova reunião → colar transcript → tipo retro → processar → revisar seções → converter 1 action item → salvar summary → voltar e abrir a aba Tarefas.
- **Critérios de saída:** as 3 seções da retro aparecem; task do action item existe na lista de tarefas com tag `reunião`; meeting salvo aparece na lista de reuniões **sem** transcript persistido (verificado no banco — RN-03).

#### S03-E2E-02 — Falha de IA com recuperação
- **O que valida:** UX de erro do pipeline.
- **Critérios de entrada:** `FakeAiEngine` programado para falhar 2x e então funcionar.
- **Ação:** processar → ver erro → tocar "Tentar novamente".
- **Critérios de saída:** tela de erro com retry (sem crash, transcript colado preservado no campo); retry produz o resumo.

## Definition of Done

- [ ] Gates G1–G6 verdes; cobertura domain+application ≥ 90%.
- [ ] Todos os testes S03-* passando.
- [ ] Teste manual com API Claude real (1 resumo com key própria) registrado no relatório; key não commitada.
- [ ] Relatório `docs/relatorios/sprint-03-relatorio.md`.
