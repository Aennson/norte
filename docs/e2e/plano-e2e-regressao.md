# Norte — Plano E2E de Regressão Global

> Suíte executada por completo na Sprint 08 (e depois a cada release). Cada cenário cruza **mais de um pilar** —
> os E2E por funcionalidade isolada já vivem nas sprints. Regras gerais de E2E: `docs/estrategia-de-testes.md §4`.
> Todos os cenários usam adapters fake determinísticos e banco em memória; nenhum acessa rede real.

**Convenção de IDs:** `REG-E2E-NN`. Cada cenário é independente e prepara seu próprio estado no setup.

---

## REG-E2E-01 — Jornada do dia de trabalho
- **O que valida:** integração Tarefas + Jira + Voz (Pilares 1 e 3).
- **Critérios de entrada:** app limpo; fake Jira com `PROJ-10` ("To Do") e `PROJ-11` ("In Progress"); fakes de voz roteirizados.
- **Passos:** criar task manual "Preparar demo" → vincular a `PROJ-10` → por voz: "muda o PROJ-10 pra em progresso" → confirmar no sheet → por voz: "comenta no PROJ-10: iniciando a demo" → confirmar → refresh de status.
- **Critérios de saída:** outbox despachou transition e comment **nessa ordem** (FIFO); `lastKnownStatus == "In Progress"`; task local segue com título e tags intactos; nenhum campo extra do Jira persistido (RN-09).

## REG-E2E-02 — Reunião vira trabalho
- **O que valida:** Reuniões + Tasks + Jira (Pilares 2 e 1).
- **Critérios de entrada:** fixture de transcript de planning com 3 action items; fake AiEngine com resumo correspondente; fake Jira vazio de issues criadas.
- **Passos:** colar transcript → resumir (template planning) → converter os 3 action items em tasks → na 1ª task, "Criar issue no Jira a partir da task" → salvar summary e sair da tela.
- **Critérios de saída:** 3 tasks com tag `reunião`; criação de issue na outbox e despachada (fake registra `POST /issue` 1×); transcript **não** persistido (retention default — RN-03); summary salvo presente na lista de reuniões.

## REG-E2E-03 — Voz de ponta a ponta com baixa confiança
- **O que valida:** RN-04 cruzando Voz + Lembretes (Pilares 3 e 5).
- **Critérios de entrada:** fakes: committed "me lembra amanhã cedo daquele negócio", intent `createReminder` confidence 0.62 com slots incompletos.
- **Passos:** comando de voz → sheet de confirmação por baixa confiança → confirmar → app pergunta horário faltante → responder "9 da manhã" → confirmar.
- **Critérios de saída:** nada persistido antes das confirmações; reminder criado para amanhã 09:00 e agendado no fake scheduler; áudio ausente do disco (RN-06).

## REG-E2E-04 — Offline total → reconexão
- **O que valida:** offline-first (Pilar 1 + outbox) sob acúmulo.
- **Critérios de entrada:** app com 2 tasks vinculadas; fake Jira em modo sem rede desde o início.
- **Passos:** transicionar task A por UI, comentar em task B por voz (confirmando), criar task local C — tudo offline → religar rede → aguardar dispatcher.
- **Critérios de saída:** offline: 2 operações pendentes visíveis, task C criada normalmente (local não depende de rede — RN-01); online: ambas aplicadas exatamente 1× cada (idempotência), indicadores de pendência somem.

## REG-E2E-05 — Troca de motor no meio do fluxo
- **O que valida:** abstração de IA (Pilar 4) transparente ao domínio.
- **Critérios de entrada:** app "como Windows"; Copilot fake ok; Claude fake ok; motor preferido Copilot.
- **Passos:** resumir reunião A (Copilot responde) → em Ajustes trocar para Claude → resumir reunião B → quebrar Claude fake e habilitar fallback → resumir reunião C.
- **Critérios de saída:** A servida pelo Copilot, B pela Claude, C pela Copilot via fallback (asserts nos contadores dos fakes); os 3 summaries com shape idêntico; trocas logadas (RN-10).

## REG-E2E-06 — Privacidade da primeira à última tela
- **O que valida:** LGPD transversal (RN-03, RN-06, RN-07, RN-08) + wipe.
- **Critérios de entrada:** app limpo; transcript fixture contendo CPF, telefone e e-mail sintéticos; sentinelas configuradas nos fakes.
- **Passos:** configurar credenciais fake → resumir reunião com o transcript com PII → criar lembrete por voz → verificar logs capturados → executar "Apagar tudo" (digitando APAGAR).
- **Critérios de saída:** engine remoto recebeu transcript **sem** PII em claro; logs sem sentinelas e sem credenciais; após wipe, banco/secure storage/temp vazios e app em estado de primeira execução.

## REG-E2E-07 — Resiliência de voz
- **O que valida:** Scribe realtime sob falha de conexão (§9.3).
- **Critérios de entrada:** fake realtime roteirizado para desconectar 2s no meio da fala e reconectar.
- **Passos:** comando de voz "cria tarefa validar backup do servidor" com a queda no meio → aguardar reconexão e committed.
- **Critérios de saída:** transcript final íntegro (sem buraco — buffer de reconexão); task criada com o título completo; nenhum áudio em disco.

## REG-E2E-08 — Estados vazios e primeiro uso
- **O que valida:** experiência de primeira execução em todas as abas.
- **Critérios de entrada:** app recém-instalado (banco vazio, sem credenciais).
- **Passos:** navegar pelas 4 abas → tentar ação Jira sem credenciais → tentar resumo sem API key.
- **Critérios de saída:** cada aba mostra `EmptyState` com ação primária; ações que exigem credenciais mostram erro acionável apontando para Ajustes (nunca crash); templates padrão existem em Ajustes.

---

## Critérios de aprovação da suíte

1. 100% dos cenários verdes em 3 execuções consecutivas no CI (sem flakes — cenário flaky é bug e bloqueia release).
2. Execução total ≤ 20 min no runner de CI.
3. Falha de qualquer cenário bloqueia o fechamento da Sprint 08 / release.
