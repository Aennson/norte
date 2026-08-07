# Norte — Regras Obrigatórias do Projeto

> **Este documento é lei.** Toda sprint, toda tarefa e todo teste devem obedecer a estas regras.
> A IA executora deve reler este arquivo antes de iniciar qualquer sprint.

---

## 1. Fluxo de execução das sprints

1. As sprints são executadas **em ordem** (`sprint-00` → `sprint-08`). Nenhuma sprint inicia sem que a anterior tenha o **Definition of Done (DoD) 100% cumprido**.
2. Cada sprint possui **Critérios de Entrada** (pré-condições verificáveis) e **Critérios de Saída** (DoD). Ambos são checklists objetivos — não há interpretação subjetiva.
3. Ao final de cada sprint, gerar um relatório em `docs/relatorios/sprint-XX-relatorio.md` contendo:
   - Checklist do DoD com evidência (comando executado + resultado).
   - Saída de `flutter test --coverage` (percentual por camada).
   - Lista de desvios/pendências (se houver, a sprint **não** está concluída).
4. Commits pequenos e frequentes, mensagem no formato: `sprint-XX: <descrição imperativa>`, seguindo a autoria definida no §7.1.
5. Todo o trabalho segue o **fluxo Git obrigatório do §7** — branch/worktree por funcionalidade e PR com CI 100% verde ao final de cada sprint. Isso é **premissa do projeto**, não sugestão.

## 2. Gates de qualidade (obrigatórios em TODA sprint)

Uma sprint só é considerada entregue se **todos** os comandos abaixo passarem sem erro:

| Gate | Comando | Critério de aceite |
|---|---|---|
| G1 — Análise estática | `flutter analyze` | 0 errors, 0 warnings |
| G2 — Formatação | `dart format --set-exit-if-changed .` | exit code 0 |
| G3 — Testes | `flutter test` | 100% dos testes passando |
| G4 — Cobertura | `flutter test --coverage` | domain+application ≥ 90%; projeto ≥ 80% |
| G5 — Regra de dependência | script `tool/check_imports.dart` (criado na sprint 00) | nenhum import ilegal entre camadas |
| G6 — Segredos | busca por tokens/keys no código (`grep -rE "(api[_-]?key|token)\s*=\s*['\"]"` em `lib/`) | nenhum segredo hardcoded |

## 3. Regra de dependência entre camadas (Clean Architecture)

```
presentation ──> application ──> domain <── infrastructure
```

- `domain/` **não importa nada** de fora de `domain/` (exceto Dart core e freezed).
- `application/` importa apenas `domain/`.
- `infrastructure/` importa `domain/` (implementa os ports). **Nunca** importa `presentation/` nem `application/`.
- `presentation/` importa `application/` e `domain/` (entidades). **Nunca** importa `infrastructure/` diretamente — a ligação acontece só no composition root (`main.dart` / providers).
- Violação de import = build reprovado no gate G5.

## 4. Regras de negócio invioláveis

Estas regras vêm da arquitetura (`docs/arquitetura.md`) e **devem ter teste automatizado cobrindo cada uma**:

| ID | Regra | Teste obrigatório em |
|---|---|---|
| RN-01 | `Task` existe independente do Jira; `JiraLink` é opcional e removível | Sprint 01 e 02 |
| RN-02 | Conflito de status local ≠ Jira **nunca** é resolvido automaticamente; UI exibe divergência e pede decisão | Sprint 02 |
| RN-03 | Transcript com `retention = ephemeral` vive só em memória; ao sair da tela é descartado (persiste apenas o summary salvo explicitamente) | Sprint 03 |
| RN-04 | `VoiceIntent` com `confidence < 0.75` exige confirmação explícita antes de qualquer ação mutável | Sprint 05 |
| RN-05 | Escrita no Jira **sempre** passa pela outbox (nunca chamada direta da UI) e é idempotente por `operationId` | Sprint 02 |
| RN-06 | Áudio de voz (comandos/lembretes) é descartado imediatamente após transcrição confirmada; nunca gravado em disco nos fluxos realtime | Sprints 05 e 06 |
| RN-07 | PII (CPF, telefone, e-mail — padrões BR) é redigida antes de envio a qualquer API externa; redação pode ser desativada apenas se `AiEngine.capabilities.isLocal == true` | Sprints 03 e 08 |
| RN-08 | Segredos (Jira token, Claude key) só em secure storage; nunca em Drift, SharedPreferences ou logs | Sprint 02 em diante |
| RN-09 | O app nunca espelha o Jira: armazena apenas `issueKey`, `siteUrl`, `lastKnownStatus` (cache exibicional) e `lastSyncedAt` | Sprint 02 |
| RN-10 | Falha do motor de IA primário: 1 retry → fallback (se habilitado) → erro claro ao usuário; toda troca é logada | Sprint 07 |

## 5. Regras de testes

1. **Todo caso de teste documentado nas sprints tem ID único** (ex.: `S02-UT-03`) e o código do teste deve referenciar o ID no nome:
   `test('S02-UT-03: outbox não duplica operação com mesmo operationId', ...)`.
2. Formato obrigatório de todo caso de teste (documentado antes de implementar):
   - **Critérios de entrada** — estado/fixtures necessários antes de executar.
   - **Passos/ação** — o que é executado.
   - **Critérios de saída** — resultado observável que define aprovação.
   - **O que está sendo validado** — a regra/comportamento coberto.
3. **Tipos de teste e nomenclatura de IDs:**
   - `UT` unit (domain/application, ports mockados com `mocktail`).
   - `CT` contract (mesma suíte aplicada a todos os adapters de um port).
   - `IT` integration (Drift real em memória, servidores HTTP fake).
   - `GT` golden (telas principais, `flutter_test` golden files).
   - `E2E` end-to-end (`integration_test/`, app real com adapters fake injetados no composition root).
4. **E2E nunca chama APIs reais.** Adapters fake (`FakeAiEngine`, `FakeJiraGateway`, `FakeTranscriptionEngine`) são injetados via Riverpod overrides e respondem com fixtures determinísticas definidas em `test/fixtures/`.
5. Testes não podem depender de rede, relógio real (usar `clock`/injeção de `DateTime.now`), nem de ordem de execução.
6. Um bug encontrado = um teste de regressão novo antes do fix.

## 6. Regras de código

- Dart 3.x, null-safety estrito, `freezed` para entidades imutáveis do domínio.
- Nenhum `dynamic` em assinaturas públicas (exceto `VoiceIntent.slots`, definido pela arquitetura).
- Erros do domínio modelados como `Failure` sealed classes em `domain/failures/` — nunca lançar exceções cruas através das camadas.
- Todo port (`abstract interface class`) documentado com dartdoc descrevendo contrato, erros possíveis e garantias.
- Logs estruturados com redação automática de payloads sensíveis (nunca logar transcript, token, key, corpo de request de IA).
- Strings de UI em PT-BR nesta v1.0, centralizadas (preparadas para l10n futura).

## 7. Fluxo Git obrigatório — branches, worktrees, PRs e CI 100%

> **Premissa do projeto: tudo 100%.** Nenhum merge acontece com qualquer teste falhando, qualquer warning,
> qualquer gate vermelho ou qualquer job de Actions pendente. Não existe "merge com ressalva".

### 7.1 Branches e autoria

1. **`master` é a branch principal e protegida.** Nunca commitar diretamente em `master` — todo código chega via Pull Request.
2. **Autoria dos commits:** todo commit é feito em nome do **Desenvolvedor** (`Aennson <aennson@gmail.com>` — configurar `git config user.name/user.email` no início de cada sessão). A IA assistente entra como **contribuidora** via trailer no rodapé da mensagem:
   ```
   Co-Authored-By: <nome da IA> <email-noreply da IA>
   ```
3. Nomenclatura de branches:
   - Sprint: `sprint-XX/<slug>` (ex.: `sprint-02/jira`)
   - Funcionalidade dentro da sprint: `feature/sprint-XX-<slug>` (ex.: `feature/sprint-02-outbox`)

### 7.2 Worktrees — uma por funcionalidade

**Cada nova funcionalidade deve ser desenvolvida em uma branch separada criada como worktree**, para agilizar a verificação (permite rodar `flutter analyze`/`flutter test` em uma worktree enquanto se desenvolve em outra, sem trocar de branch nem sujar o diretório principal):

```bash
# abrir a worktree da sprint a partir de master
git worktree add ../norte-sprint-XX -b sprint-XX/<slug> master

# funcionalidades da sprint: worktrees a partir da branch da sprint
git worktree add ../norte-feat-<slug> -b feature/sprint-XX-<slug> sprint-XX/<slug>

# ao concluir a funcionalidade: merge na branch da sprint e remoção da worktree
git worktree remove ../norte-feat-<slug>
```

Regras:
- O diretório principal do repositório permanece em `master`; desenvolvimento acontece **sempre** nas worktrees.
- Funcionalidade concluída = gates G1–G6 verdes **na worktree** antes do merge na branch da sprint.
- Worktrees são removidas após o merge (não acumular worktrees mortas; `git worktree prune` ao final da sprint).

### 7.3 Pull Request ao final de cada sprint

1. Ao final de cada sprint, abrir **um PR** da branch `sprint-XX/<slug>` para `master`.
2. O PR deve conter na descrição: escopo entregue, checklist do DoD preenchido e link para o relatório `docs/relatorios/sprint-XX-relatorio.md` (commitado na própria branch).
3. **O merge só é permitido quando o GitHub Actions estiver 100% verde** — todos os jobs do workflow de CI (analyze, format, check_imports, testes + cobertura, goldens, E2E) aprovados, sem exceção, sem `skip` e sem re-run mascarando flake (teste flaky é bug: corrigir antes de mergear).
4. Reprovou no Actions → corrigir na própria branch da sprint e aguardar novo run verde. A sprint **não está concluída** enquanto o PR não estiver mergeável com CI 100%.
5. Após o merge, a próxima sprint parte de `master` atualizada (`git fetch && git worktree add ... master`).

## 8. O que a IA executora NÃO deve fazer

- ❌ Implementar funcionalidade de sprint futura ("já que estou aqui...").
- ❌ Pular teste documentado ou marcar `skip` para fechar sprint.
- ❌ Trocar dependências definidas na stack (`docs/arquitetura.md §2.1`) sem registrar decisão em `docs/relatorios/decisoes.md`.
- ❌ Chamar APIs reais em testes ou commitar chaves/fixtures com dados reais.
- ❌ Resolver conflito local×Jira automaticamente (viola RN-02).
- ❌ Persistir transcript efêmero ou áudio de voz (viola RN-03/RN-06).
