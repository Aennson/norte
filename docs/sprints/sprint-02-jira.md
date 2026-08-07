# Sprint 02 — Integração Jira: JiraLink, Adapter REST, Outbox e Refresh

**Objetivo:** vincular tasks a issues do Jira Cloud (camada externa, nunca espelho), com escrita via outbox offline-first idempotente e refresh de status sob demanda + background.

**Referências obrigatórias:** `docs/arquitetura.md` §4 · RN-01, RN-02, RN-05, RN-08, RN-09

---

## Critérios de entrada

- [ ] Sprint 01 com DoD completo.
- [ ] `FakeJiraGateway` disponível com fixtures de issues (`test/fixtures/jira_issues.json`).

## Escopo

**Dentro:** port `JiraGateway` (getIssue, transitionIssue, addComment, createIssue, getStatus); `JiraRestAdapter` (dio, Basic auth com API token, Jira Cloud REST v3); armazenamento de credenciais em `flutter_secure_storage` + tela de configuração Jira em Ajustes; tabela `outbox` no Drift + `OutboxDispatcher` (retry exponencial, idempotência por `operationId`); use cases `LinkTaskToJira`, `UnlinkTask`, `UpdateJiraStatus`, `AddJiraComment`, `CreateJiraIssueFromTask`, `RefreshJiraStatus`; refresh em background a cada 15 min (workmanager mobile / timer+isolate Windows) apenas para tasks vinculadas não concluídas; UI: `JiraChip` na task, `DivergenceBanner` para conflito de status.

**Fora:** OAuth, sync bidirecional automática, espelhamento de campos do Jira além dos 4 do `JiraLink`.

## Regras de validação da sprint

- **RN-09:** `JiraLink` persiste somente `issueKey`, `siteUrl`, `lastKnownStatus`, `lastSyncedAt`. Nenhuma outra coluna/campo de Jira no schema.
- **RN-05:** toda mutação Jira (transition, comment, create) entra na outbox; nenhuma chamada de escrita direta de use case → adapter.
- **RN-02:** divergência de status nunca resolve sozinha; banner oferece "Manter local" / "Adotar do Jira".
- **RN-08:** token só em secure storage; logs do dio redigem header `Authorization` e corpo de credenciais.
- Outbox: backoff exponencial 2s/4s/8s/16s (máx 5 tentativas); depois marca `failed` e exibe indicador na UI com ação de retry manual.
- Vincular ticket exige validação online (`GET /issue/{key}`): key inexistente → erro claro; sem rede → erro "requer conexão" (vínculo não é enfileirado).

## Testes

#### S02-UT-01 — Vincular e desvincular preserva a task
- **O que valida:** RN-01.
- **Critérios de entrada:** task local existente; `FakeJiraGateway` com issue `PROJ-123` válida.
- **Ação:** `LinkTaskToJira(task, "PROJ-123")`, depois `UnlinkTask`.
- **Critérios de saída:** após vincular, `jiraLink.issueKey == "PROJ-123"` e demais campos da task intactos; após desvincular, `jiraLink == null` e a task continua existindo com título/status locais.

#### S02-UT-02 — Vínculo com key inexistente
- **O que valida:** validação online do vínculo.
- **Critérios de entrada:** fake configurado para 404 em `NOPE-1`.
- **Ação:** `LinkTaskToJira(task, "NOPE-1")`.
- **Critérios de saída:** `JiraIssueNotFoundFailure`; task permanece sem link; nada na outbox.

#### S02-UT-03 — Mutações vão para a outbox, nunca direto
- **O que valida:** RN-05.
- **Critérios de entrada:** task vinculada; fake gateway espião.
- **Ação:** `UpdateJiraStatus(task, "Done")` **sem** rodar o dispatcher.
- **Critérios de saída:** 1 operação pendente na outbox com payload correto; **zero** chamadas registradas no gateway.

#### S02-UT-04 — Detecção de divergência
- **O que valida:** RN-02 (detecção).
- **Critérios de entrada:** task com status local `done`, `lastKnownStatus = "In Progress"`; fake retorna status remoto `"To Do"`.
- **Ação:** `RefreshJiraStatus(task)`.
- **Critérios de saída:** resultado sinaliza divergência (local ≠ remoto); status local **não** é alterado; `lastKnownStatus` atualizado para `"To Do"` e `lastSyncedAt` = clock.now.

#### S02-IT-01 — Idempotência da outbox
- **O que valida:** RN-05 (idempotência por `operationId`).
- **Critérios de entrada:** outbox Drift em memória com operação `op-1`; fake gateway contando chamadas.
- **Ação:** despachar; simular timeout de resposta após sucesso no servidor (resposta perdida); redespachar `op-1`.
- **Critérios de saída:** gateway aplicou a operação 1 única vez (fake deduplica por `operationId` e o teste asserta 1 aplicação efetiva); operação termina `completed`, sem duplicata na fila.

#### S02-IT-02 — Retry com backoff e falha final
- **O que valida:** política de retry da outbox.
- **Critérios de entrada:** fake gateway retornando 429 sempre; `FakeClock` controlando o tempo.
- **Ação:** despachar uma operação e avançar o relógio pelos intervalos.
- **Critérios de saída:** tentativas nos offsets 0s/2s/4s/8s/16s (5 no total); após a 5ª, estado `failed`; nenhuma tentativa além disso sem retry manual.

#### S02-IT-03 — Ordem FIFO por issue
- **O que valida:** consistência de mutações sequenciais.
- **Critérios de entrada:** outbox com transition e comment para a mesma issue, criadas nessa ordem.
- **Ação:** despachar com rede ok.
- **Critérios de saída:** gateway recebe transition antes do comment.

#### S02-IT-04 — Redação de credenciais nos logs
- **O que valida:** RN-08.
- **Critérios de entrada:** `JiraRestAdapter` com interceptor de log capturado em memória; request com Basic auth.
- **Ação:** executar `getIssue` contra servidor HTTP fake.
- **Critérios de saída:** log não contém o token nem o header `Authorization` em claro (aparece `[REDACTED]`).

#### S02-CT-01 — Contrato JiraGateway
- **O que valida:** `JiraRestAdapter` (contra servidor fake) e `FakeJiraGateway` obedecem o mesmo contrato.
- **Critérios de entrada:** suíte parametrizada recebendo factory do adapter.
- **Ação:** rodar os mesmos casos (issue existe, 404, 401, 429, comment ok) nos dois adapters.
- **Critérios de saída:** mesmos tipos de retorno/failure para os mesmos estímulos nos dois.

#### S02-GT-01 — JiraChip e DivergenceBanner
- **O que valida:** componentes Jira no design system (§4).
- **Critérios de entrada:** task vinculada com e sem divergência.
- **Ação:** renderizar card de task em dark/light.
- **Critérios de saída:** goldens estáveis; banner usa cor `warning` e dois botões de decisão.

#### S02-E2E-01 — Fluxo offline → online
- **O que valida:** offline-first (RN-05) de ponta a ponta.
- **Critérios de entrada:** app com task vinculada a `PROJ-123`; fake gateway em modo "sem rede".
- **Ação:** pela UI, mudar status para Done (ação Jira) → verificar indicador "pendente de sync" → religar a rede do fake → aguardar dispatcher.
- **Critérios de saída:** com rede off, UI mostra pendência e nada chega ao gateway; com rede on, operação é aplicada 1 vez, indicador some, `lastKnownStatus` reflete "Done".

#### S02-E2E-02 — Decisão de divergência
- **O que valida:** RN-02 na UI.
- **Critérios de entrada:** task local `done`; fake com status remoto "In Progress".
- **Ação:** refresh pela UI → banner aparece → escolher "Adotar do Jira".
- **Critérios de saída:** antes da escolha nada muda; após, status local vira `inProgress`; escolher "Manter local" (cenário B, repetido) mantém `done` e enfileira transition na outbox.

## Definition of Done

- [ ] Gates G1–G6 verdes; cobertura domain+application ≥ 90%.
- [ ] Todos os testes S02-* passando; contrato CT rodando para ambos adapters no CI.
- [ ] Teste manual contra um Jira Cloud real (site de teste): vincular, comentar, transicionar — roteiro e evidência no relatório. **Token real nunca commitado.**
- [ ] Relatório `docs/relatorios/sprint-02-relatorio.md`.
