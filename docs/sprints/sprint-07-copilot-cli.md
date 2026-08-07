# Sprint 07 — CopilotCliEngine (Windows), Fallback e Settings de Motor

**Objetivo:** segundo adapter de IA — Copilot CLI como subprocesso local no Windows — com watchdog, fallback para `ClaudeApiEngine` e seleção de motor nas configurações.

**Referências obrigatórias:** `docs/arquitetura.md` §7.2–7.3, §12 · RN-07, RN-10

---

## Critérios de entrada

- [ ] Sprint 06 com DoD completo.
- [ ] Suítes de contrato `AiEngine` (S03-CT-01, S05-CT-02) existentes e parametrizáveis por adapter.

## Escopo

**Dentro:** `CopilotCliEngine` (`Process.start`, modo programático, stdout parseado, stderr logado com redação); timeout de 30s + watchdog (processo travado → kill + falha controlada); `capabilities.isLocal = true`; política de seleção/fallback do provider (`arquitetura.md §7.3`): primário falha (timeout, erro de processo, rate limit) → 1 retry → fallback se habilitado → erro claro; log local de cada troca de motor; em Android/iOS o adapter reporta `unavailable` e a UI oculta a opção; seção "Motor de IA" em Ajustes (escolha do motor — só Windows mostra Copilot —, toggle de fallback, contador de uso por motor).

**Fora:** outros motores locais, streaming no Copilot CLI (se o CLI não suportar, respostas batch são aceitas).

## Regras de validação da sprint

- **RN-10:** sequência exata primário → retry → fallback → erro; toda troca logada com motivo.
- **RN-07:** com `isLocal == true`, o `PiiRedactor` pode ser desativado (setting), mas o default permanece **ativado**.
- O subprocesso nunca recebe segredos por argv (visível em process list); ambiente do processo restrito ao necessário.
- Kill do watchdog não pode vazar processos zumbis (verificar encerramento).
- Nenhum código de plataforma (`Platform.isWindows`) fora do composition root e do próprio adapter.

## Testes

#### S07-UT-01 — Seleção por plataforma e preferência
- **O que valida:** provider de seleção (§7.3).
- **Critérios de entrada:** provider com plataforma e preferência injetáveis.
- **Ação:** avaliar as 4 combinações (pref copilot/claude × Windows/não-Windows).
- **Critérios de saída:** (copilot, Windows) → `CopilotCliEngine` com fallback Claude; demais → `ClaudeApiEngine`.

#### S07-UT-02 — Cadeia de fallback (RN-10)
- **O que valida:** política primário → retry → fallback → erro.
- **Critérios de entrada:** engine primário fake programável (falha N vezes), fallback fake espião, logger espião.
- **Ação:** cenário A: primário falha 1x e funciona no retry; B: primário falha 2x, fallback funciona; C: ambos falham; D: fallback desabilitado e primário falha 2x.
- **Critérios de saída:** A → sucesso com 2 chamadas ao primário, fallback intocado; B → sucesso via fallback com log da troca (motivo incluído); C → `AiUnavailableFailure` com mensagem clara; D → falha sem tocar o fallback.

#### S07-UT-03 — Timeout e watchdog
- **O que valida:** CLI travado não trava o app.
- **Critérios de entrada:** processo fake que nunca responde; clock/timers controlados.
- **Ação:** `summarize()` e avançar 30s.
- **Critérios de saída:** `AiTimeoutFailure` em 30s; kill enviado ao processo; nenhum processo remanescente.

#### S07-UT-04 — Parse de stdout
- **O que valida:** robustez do parsing do CLI.
- **Critérios de entrada:** fixtures de stdout: resposta válida, resposta com ruído antes/depois do payload, saída vazia, exit code ≠ 0.
- **Ação:** parsear cada fixture.
- **Critérios de saída:** válida e com ruído → payload extraído corretamente; vazia/exit ≠ 0 → `AiProcessFailure` (dispara a cadeia de fallback).

#### S07-UT-05 — unavailable em mobile
- **O que valida:** §7.2 (Android/iOS ocultam a opção).
- **Critérios de entrada:** adapter com plataforma injetada como Android.
- **Ação:** consultar disponibilidade; renderizar settings (widget test).
- **Critérios de saída:** `unavailable == true`; opção Copilot ausente da UI de Ajustes.

#### S07-CT-01 — Contrato AiEngine no CopilotCliEngine
- **O que valida:** os dois engines passam pela **mesma** suíte (arquitetura §13).
- **Critérios de entrada:** suítes de contrato existentes (summarize + parseIntent) parametrizadas com `CopilotCliEngine` sobre processo fake com fixtures.
- **Ação:** rodar a suíte completa.
- **Critérios de saída:** mesmos inputs → shape de output válido idêntico ao contrato; mesmos `Failure`s para os mesmos erros.

#### S07-IT-01 — Redator relaxado com engine local
- **O que valida:** RN-07 condicionada a `isLocal`.
- **Critérios de entrada:** `SummarizeMeeting` com Copilot fake (`isLocal = true`), setting de redação em default (on) e off (2 cenários); transcript com CPF.
- **Ação:** resumir.
- **Critérios de saída:** default on → CPF redigido mesmo local; off + local → CPF passa íntegro; off + engine remoto → redação **continua ativa** (setting só vale para local).

#### S07-GT-01 — Settings de motor
- **O que valida:** UI de Ajustes por plataforma.
- **Critérios de entrada:** settings renderizados como Windows e como mobile.
- **Ação:** golden dark/light.
- **Critérios de saída:** Windows exibe escolha de motor + toggle fallback + contador de uso; mobile não exibe Copilot.

#### S07-E2E-01 — Resumo com fallback transparente
- **O que valida:** RN-10 na experiência real.
- **Critérios de entrada:** app "como Windows" com Copilot fake programado para travar e Claude fake ok; motor preferido: Copilot; fallback on.
- **Ação:** processar uma reunião colada.
- **Critérios de saída:** resumo aparece (via fallback) sem erro ao usuário; log de diagnóstico registra a troca; contador de uso incrementa no motor que respondeu.

#### S07-E2E-02 — Ambos os motores fora
- **O que valida:** erro claro (§7.3).
- **Critérios de entrada:** ambos os fakes falhando.
- **Ação:** processar reunião.
- **Critérios de saída:** mensagem de erro acionável (nomeia o problema e sugere verificar Ajustes); transcript preservado no campo; retry disponível.

## Definition of Done

- [ ] Gates G1–G6 verdes; cobertura domain+application ≥ 90%.
- [ ] Todos os testes S07-* passando; suíte de contrato cobre os 2 engines no CI.
- [ ] Teste manual no Windows com Copilot CLI real instalado: 1 resumo + 1 parse de intent + 1 fallback forçado (CLI desinstalado/renomeado) — evidências no relatório.
- [ ] Relatório `docs/relatorios/sprint-07-relatorio.md`.
