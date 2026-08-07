# Norte — Documentação de Execução do Projeto

**Norte** é um assistente pessoal de produtividade para desenvolvedores (Flutter — Android, iOS, Windows): tarefas com vínculo Jira, resumo de reuniões por IA, comandos de voz com intenção e lembretes por voz.

Esta pasta contém **tudo o que uma IA executora precisa para implementar e testar o projeto do zero**, sprint a sprint, sem decisões em aberto.

---

## 🤖 Instruções para a IA executora — leia primeiro

1. **Ordem de leitura obrigatória antes de escrever qualquer código:**
   1. [`arquitetura.md`](arquitetura.md) — a arquitetura completa (camadas, domínio, pilares, stack).
   2. [`regras-do-projeto.md`](regras-do-projeto.md) — **regras invioláveis**: gates de qualidade, regra de dependência, regras de negócio RN-01..RN-10, regras de teste.
   3. [`design-system.md`](design-system.md) — tokens visuais (inspirados no Claude Code), componentes e layout obrigatórios.
   4. [`estrategia-de-testes.md`](estrategia-de-testes.md) — pirâmide, fakes, formato de caso de teste, E2E e evals.
2. **Execute as sprints em ordem** (00 → 08). Cada sprint tem *Critérios de Entrada* (verifique antes de começar) e *Definition of Done* (verifique antes de encerrar). Não misture escopo de sprints.
   - **Fluxo Git obrigatório** ([`regras-do-projeto.md §7`](regras-do-projeto.md)): `master` é protegida; cada nova funcionalidade nasce em **branch separada criada como worktree**; ao final de cada sprint, **PR para `master`** que só é mergeado com o **GitHub Actions 100% verde**. Commits em nome do Desenvolvedor, IA como contribuidora (`Co-Authored-By`). **Premissa: tudo 100%** — nenhum merge com teste falhando, warning ou job pendente.
3. **Todo teste já está especificado** com ID, "o que valida", critérios de entrada e critérios de saída. Implemente exatamente o que está especificado (pode adicionar testes, nunca remover) e nomeie cada teste com seu ID: `test('S01-UT-01: ...')`.
4. Ao terminar uma sprint, escreva o relatório em `docs/relatorios/sprint-XX-relatorio.md` com as evidências pedidas no DoD.
5. Em dúvida entre documentos: `regras-do-projeto.md` > sprint > demais documentos.

## 📁 Mapa da documentação

| Documento | Conteúdo |
|---|---|
| [`arquitetura.md`](arquitetura.md) | Documento de arquitetura v1.0 (fonte de verdade técnica) |
| [`regras-do-projeto.md`](regras-do-projeto.md) | Gates G1–G6, regra de dependência, RN-01..RN-10, proibições |
| [`design-system.md`](design-system.md) | Paleta dark/light, tipografia, componentes, layout responsivo |
| [`estrategia-de-testes.md`](estrategia-de-testes.md) | Tipos de teste, fakes/fixtures, formato de especificação, evals |
| [`e2e/plano-e2e-regressao.md`](e2e/plano-e2e-regressao.md) | Suíte E2E global cruzando os pilares (REG-E2E-01..08) |
| `relatorios/` | Criada durante a execução (relatórios de sprint e decisões) |

## 🚀 Sprints (roadmap executável)

| Sprint | Entrega | Testes especificados |
|---|---|---|
| [00 — Setup](sprints/sprint-00-setup.md) | Projeto Flutter, tema/design system, fakes, CI, check de imports | S00: 4 UT · 2 GT · 1 IT · 1 E2E |
| [01 — Fundação](sprints/sprint-01-fundacao.md) | Domínio completo, Drift, Tasks CRUD local reativo | S01: 4 UT · 3 IT · 1 GT · 2 E2E |
| [02 — Jira](sprints/sprint-02-jira.md) | JiraLink, adapter REST, outbox idempotente, divergência de status | S02: 4 UT · 4 IT · 1 CT · 1 GT · 2 E2E |
| [03 — Reuniões](sprints/sprint-03-reunioes.md) | Transcrição colada, templates, resumo Claude, PII, ActionItems→Tasks | S03: 6 UT · 2 IT · 1 CT · 1 GT · 2 E2E |
| [04 — Whisper batch](sprints/sprint-04-whisper-batch.md) | Gravação de áudio + transcrição batch no mesmo pipeline | S04: 3 UT · 1 IT · 1 CT · 1 GT · 2 E2E |
| [05 — Voz realtime](sprints/sprint-05-voz-realtime.md) | Scribe realtime, IntentParser, 5 intenções, confirmação | S05: 6 UT · 2 CT · 1 EV · 1 GT · 3 E2E |
| [06 — Lembretes](sprints/sprint-06-lembretes.md) | Lembretes por voz + notificações nas 3 plataformas | S06: 4 UT · 2 IT · 1 GT · 2 E2E |
| [07 — Copilot CLI](sprints/sprint-07-copilot-cli.md) | Motor local Windows, watchdog, fallback, settings de motor | S07: 5 UT · 1 CT · 1 IT · 1 GT · 2 E2E |
| [08 — Hardening](sprints/sprint-08-hardening.md) | LGPD, wipe, evals em CI, regressão global, release v1.0 | S08: 2 UT · 2 IT · 1 GT · 2 E2E + suíte REG |

## ✅ Resumo dos gates (válidos em toda sprint)

```
flutter analyze                      # 0 warnings
dart format --set-exit-if-changed .  # formatado
dart run tool/check_imports.dart     # camadas respeitadas
flutter test --coverage              # 100% verde; domain+application ≥ 90%
flutter test integration_test/       # E2E da sprint verdes
```

Detalhes e critérios exatos: [`regras-do-projeto.md §2`](regras-do-projeto.md).
