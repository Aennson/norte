# Sprint 00 — Setup, Design System e Infraestrutura de Testes

**Objetivo:** criar o esqueleto do projeto Flutter multiplataforma com a estrutura de camadas, o tema visual (design system), os fakes de teste e o CI — a base sobre a qual todas as sprints seguintes rodam.

**Referências obrigatórias:** `docs/arquitetura.md` §2, §11 · `docs/design-system.md` · `docs/estrategia-de-testes.md` · `docs/regras-do-projeto.md`

---

## Critérios de entrada

- [ ] Repositório vazio ou apenas com `docs/`.
- [ ] Flutter SDK estável 3.x instalado (`flutter doctor` sem erros para as plataformas alvo disponíveis no ambiente).

## Escopo

**Dentro:** projeto Flutter (Android/iOS/Windows habilitados), estrutura de pastas de `docs/arquitetura.md §11`, dependências da stack (§2.1), tema dark+light com tokens do design system, componentes compartilhados (`NorteButton`, `NorteCard`, `StatusBadge`, `EmptyState`), shell de navegação (bottom nav mobile / rail desktop) com telas placeholder, fakes de teste, script `tool/check_imports.dart`, CI GitHub Actions.

**Fora:** qualquer regra de negócio, entidades reais, persistência, chamadas de rede.

## Entregáveis

1. App compila e roda nas plataformas disponíveis; `main.dart` é o composition root com `ProviderScope`.
2. `presentation/shared/theme/` com `NorteColors` (ThemeExtension, dark+light) e `NorteTypography` conforme `docs/design-system.md`.
3. Componentes compartilhados listados no escopo, cada um com golden test.
4. Navegação `go_router` com 4 destinos placeholder (Tarefas, Reuniões, Lembretes, Ajustes) + botão de voz (sem função ainda).
5. `test/fakes/` com os 6 fakes de `docs/estrategia-de-testes.md §3` (interfaces provisórias onde o port ainda não existe são permitidas **somente** para fakes que dependem de sprints futuras — neste caso criar o port real já em `domain/ports/`).
6. `tool/check_imports.dart` — falha (exit ≠ 0) se qualquer arquivo violar a regra de dependência de `docs/regras-do-projeto.md §3`, e se houver `Color(0x...)` fora de `presentation/shared/theme/`.
7. Workflow CI `.github/workflows/ci.yml`: analyze → format → check_imports → test → coverage gate.

## Regras de validação da sprint

- Tokens de cor **exatamente** os hex de `docs/design-system.md §2` — sem cores inventadas.
- Nenhuma tela usa cor literal fora do tema (verificado pelo check_imports).
- Estrutura de pastas idêntica à de `docs/arquitetura.md §11` (pastas vazias podem ter `.gitkeep`).

## Testes

#### S00-UT-01 — Tokens do tema dark
- **O que valida:** fidelidade da paleta dark ao design system.
- **Critérios de entrada:** `NorteColors.dark` instanciado.
- **Ação:** ler cada token.
- **Critérios de saída:** cada token corresponde ao hex da tabela `design-system.md §2.1` (assert por valor).

#### S00-UT-02 — Tokens do tema claro
- **O que valida:** fidelidade da paleta light (§2.2).
- **Critérios de entrada:** `NorteColors.light` instanciado.
- **Ação:** ler cada token.
- **Critérios de saída:** todos os hex batem com a tabela §2.2.

#### S00-UT-03 — Lerp do ThemeExtension
- **O que valida:** transição de tema não quebra (requisito do ThemeExtension).
- **Critérios de entrada:** instâncias dark e light.
- **Ação:** `lerp(dark, light, 0.5)` e `copyWith()`.
- **Critérios de saída:** nenhum token nulo; `lerp(a, b, 0) == a` e `lerp(a, b, 1) == b`.

#### S00-UT-04 — Contraste AA
- **O que valida:** acessibilidade WCAG AA (design-system §2, regra final).
- **Critérios de entrada:** função de razão de contraste implementada no teste.
- **Ação:** calcular contraste dos pares (`textPrimary`/`bg`, `textPrimary`/`surface`, `textSecondary`/`surface`, branco/`accent`) nos dois temas.
- **Critérios de saída:** todos ≥ 4.5:1.

#### S00-GT-01 — Goldens dos componentes compartilhados
- **O que valida:** aparência de `NorteButton` (4 estados), `NorteCard`, `StatusBadge` (4 status), `EmptyState`.
- **Critérios de entrada:** fonte mono embarcada carregada no teste; tamanho de superfície fixo.
- **Ação:** renderizar cada componente em dark e light.
- **Critérios de saída:** goldens gerados e commitados; execução subsequente passa sem diff.

#### S00-GT-02 — Shell de navegação
- **O que valida:** layout responsivo (design-system §5).
- **Critérios de entrada:** app shell com telas placeholder.
- **Ação:** renderizar em 390×844 (mobile) e 1280×800 (desktop).
- **Critérios de saída:** mobile mostra bottom nav com 4 itens + botão de voz; desktop mostra navigation rail; goldens estáveis.

#### S00-IT-01 — check_imports detecta violação
- **O que valida:** o gate G5 realmente falha quando deve.
- **Critérios de entrada:** arquivo temporário em `domain/` importando `package:flutter/material.dart` criado pelo teste em diretório sintético.
- **Ação:** rodar a análise do script sobre o diretório sintético.
- **Critérios de saída:** script reporta a violação (e exit ≠ 0); removendo o arquivo, passa.

#### S00-E2E-01 — Smoke de navegação
- **O que valida:** app sobe e navega entre os 4 destinos.
- **Critérios de entrada:** app iniciado via `integration_test` com `ProviderScope` padrão.
- **Ação:** tocar em cada item de navegação.
- **Critérios de saída:** cada tela placeholder aparece (título esperado encontrado); sem exceções no log.

## Definition of Done

- [ ] Gates G1–G6 verdes (`docs/regras-do-projeto.md §2`); cobertura ainda sem gate de domínio (não há domínio) — gate de projeto ≥ 80% aplicado ao que existe.
- [ ] Todos os testes S00-* implementados e passando.
- [ ] CI executa e passa no push.
- [ ] Relatório `docs/relatorios/sprint-00-relatorio.md` criado com evidências.
