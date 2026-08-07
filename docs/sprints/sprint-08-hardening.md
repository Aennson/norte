# Sprint 08 — Hardening: LGPD, Wipe, Evals em CI e Fechamento da v1.0

**Objetivo:** endurecer segurança e privacidade (auditoria RN-03/06/07/08, "Apagar tudo"), consolidar os evals de intent como gate de regressão no CI e fechar a v1.0 com a suíte E2E de regressão completa.

**Referências obrigatórias:** `docs/arquitetura.md` §10, §13, §15 · RN-03, RN-06, RN-07, RN-08 · `docs/e2e/plano-e2e-regressao.md`

---

## Critérios de entrada

- [ ] Sprints 00–07 com DoD completo.
- [ ] Todos os testes S00–S07 verdes no CI.

## Escopo

**Dentro:** revisão/auditoria do `PiiRedactor` (ampliar dataset de PII para ≥40 casos, incluindo variantes com pontuação e quebra de linha); "Apagar tudo" em Ajustes (wipe Drift + secure storage + arquivos temp, com dupla confirmação); auditoria de logs (verificação automatizada de que nenhum log contém token/key/transcript/payload de IA); eval de intents como job obrigatório do CI; contador de uso de API nas settings (risco §15 — custo); telas de política de privacidade/consentimento simples; execução e estabilização da suíte E2E de regressão global (`docs/e2e/plano-e2e-regressao.md`); revisão final de acessibilidade (labels semânticos nos botões principais, navegação por teclado no Windows).

**Fora:** certificate pinning (v1.1), OAuth Jira, multiusuário.

## Regras de validação da sprint

- "Apagar tudo" é irreversível e completo: Drift zerado, secure storage zerado, diretório temp limpo, estado em memória reiniciado (app volta ao estado de primeira execução, incluindo templates re-seedados).
- Dupla confirmação com digitação da palavra "APAGAR" (padrão de ação destrutiva máxima).
- Nenhum teste existente pode ser removido/enfraquecido nesta sprint; regressões encontradas geram teste antes do fix (regras §5).
- O job de eval falha o CI se acurácia cair abaixo dos limiares (intent ≥ 90%, slots ≥ 85%).

## Testes

#### S08-UT-01 — PiiRedactor ampliado
- **O que valida:** RN-07 com dataset adversarial.
- **Critérios de entrada:** dataset `test/fixtures/pii/casos.json` com ≥40 casos: CPFs válidos/inválidos-em-formato, telefones fixos/celulares/com DDI, e-mails com subdomínios/+tag, PII colado a pontuação e quebrado em linhas; ≥10 falsos-positivos (issue keys, datas, versões, CEP, CNPJ*).
- **Ação:** redigir todos os casos.
- **Critérios de saída:** 100% dos PII do gabarito redigidos; 0 falsos-positivos redigidos. (*CNPJ documentadamente fora do escopo v1.0 — deve permanecer intacto.)

#### S08-UT-02 — Wipe completo
- **O que valida:** direito de exclusão (§10).
- **Critérios de entrada:** app com dados em tudo: tasks (com JiraLink), meetings, reminders agendados, templates editados, outbox pendente, token Jira e key Claude em secure storage fake, arquivo temp de áudio.
- **Ação:** executar o use case de wipe.
- **Critérios de saída:** todas as tabelas Drift vazias; secure storage vazio; temp vazio; scheduler sem agendamentos; templates padrão re-seedados; contadores de uso zerados.

#### S08-IT-01 — Auditoria automatizada de logs
- **O que valida:** RN-08 e §10 (logs redigidos).
- **Critérios de entrada:** logger global capturado; execução de um fluxo de cada pilar com fakes (resumo, sync Jira, comando de voz, lembrete) usando valores sentinela (`TOKEN_SENTINEL`, `KEY_SENTINEL`, transcript com `SEGREDO_SENTINEL`).
- **Ação:** rodar os fluxos e varrer todo o log capturado.
- **Critérios de saída:** nenhuma ocorrência de qualquer sentinela nos logs; ocorrências de `[REDACTED]` presentes onde payloads foram logados.

#### S08-IT-02 — Eval como gate de CI
- **O que valida:** arquitetura §13/§14.8 (evals de regressão).
- **Critérios de entrada:** workflow de CI com job de eval; dataset com 1 gabarito propositalmente quebrado em branch de teste.
- **Ação:** rodar o job com dataset correto e com o quebrado.
- **Critérios de saída:** dataset correto → job verde com métricas publicadas como artifact; quebrado abaixo do limiar → job falha o pipeline.

#### S08-GT-01 — Telas de privacidade e wipe
- **O que valida:** UI de consentimento e ação destrutiva máxima.
- **Critérios de entrada:** telas implementadas.
- **Ação:** golden dark/light da tela de privacidade e do diálogo de dupla confirmação.
- **Critérios de saída:** goldens estáveis; botão final de wipe usa cor `error`; campo de digitação "APAGAR" presente.

#### S08-E2E-01 — Wipe de ponta a ponta
- **O que valida:** exclusão vista pelo usuário.
- **Critérios de entrada:** app populado (1 task vinculada, 1 meeting salvo, 1 reminder futuro, credenciais fake).
- **Ação:** Ajustes → Apagar tudo → digitar "APAGAR" → confirmar → navegar por todas as abas.
- **Critérios de saída:** todas as abas em `EmptyState`; Ajustes sem credenciais; digitar palavra errada (cenário B) mantém tudo intacto.

#### S08-E2E-02 — Suíte de regressão global
- **O que valida:** os 6 pilares íntegros em conjunto.
- **Critérios de entrada:** todos os cenários de `docs/e2e/plano-e2e-regressao.md` implementados.
- **Ação:** executar a suíte completa no CI (desktop) 3 vezes consecutivas.
- **Critérios de saída:** 3 execuções 100% verdes (sem flakes); duração total registrada no relatório.

## Definition of Done — fechamento da v1.0

- [ ] Gates G1–G6 verdes; cobertura domain+application ≥ 90%, projeto ≥ 80%.
- [ ] Todos os testes S08-* passando; eval obrigatório no CI.
- [ ] Suíte E2E de regressão global verde 3× seguidas.
- [ ] Checklist de conformidade preenchido no relatório: RN-01 a RN-10, cada uma com o ID do teste que a cobre.
- [ ] Build de release gerado para Android (APK), Windows (exe/msix) e iOS (se ambiente disponível) — artefatos anexados/registrados.
- [ ] Relatório final `docs/relatorios/sprint-08-relatorio.md` + `docs/relatorios/v1.0-release-notes.md`.
