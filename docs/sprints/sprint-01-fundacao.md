# Sprint 01 — Fundação: Domínio, Persistência e Tasks CRUD Local

**Objetivo:** implementar o modelo de domínio, a persistência Drift e o CRUD completo de tarefas **100% local** (sem Jira), com a tela de tarefas funcional no design system.

**Referências obrigatórias:** `docs/arquitetura.md` §3, §11 · `docs/design-system.md` §4 · RN-01

---

## Critérios de entrada

- [ ] Sprint 00 com DoD completo (CI verde, tema e componentes prontos).
- [ ] Fakes e fixtures da Sprint 00 disponíveis.

## Escopo

**Dentro:** entidades do domínio (`Task`, `JiraLink`, `Meeting`, `MeetingTemplate`, `Reminder`, `VoiceIntent` — todas, ainda que só `Task` seja usada agora) com `freezed`; enums (`TaskStatus`, `Priority`, `MeetingType`, `IntentType`, `RetentionPolicy`); `Failure` sealed classes; ports `TaskRepository` e `NotificationScheduler` (interface apenas); schema Drift + `DriftTaskRepository`; use cases `CreateTask`, `UpdateTask`, `DeleteTask`, `ListTasks` (filtro por status/tag, ordenação por prioridade/dueDate); tela de Tarefas completa (listar, criar, editar, concluir, excluir, filtrar) com os 4 estados obrigatórios.

**Fora:** qualquer código Jira (a entidade `JiraLink` existe, mas nenhum uso), IA, voz, reuniões.

## Regras de validação da sprint

- Entidades imutáveis; alterações via `copyWith` retornando nova instância com `updatedAt` atualizado pelo use case (não pela entidade).
- `Task.id` é UUID v4 gerado no use case; `createdAt`/`updatedAt` via relógio injetado (testável).
- Repositório expõe `Stream<List<Task>>` reativo (Drift watch) — a UI nunca faz polling.
- Exclusão de task pede confirmação na UI (ação destrutiva, botão `error` do design system).
- Nenhum acesso a Drift fora de `infrastructure/persistence/`.

## Testes

#### S01-UT-01 — Criação de Task válida
- **O que valida:** RN-01 (task independe de Jira) e defaults corretos.
- **Critérios de entrada:** `CreateTask` com repositório mockado e `FakeClock` fixado.
- **Ação:** executar com título "Revisar PR".
- **Critérios de saída:** task persistida com `status = todo`, `jiraLink == null`, `createdAt == updatedAt == clock.now`, id UUID v4 válido.

#### S01-UT-02 — Título obrigatório
- **O que valida:** validação de entrada do use case.
- **Critérios de entrada:** `CreateTask` mockado.
- **Ação:** executar com título vazio e só espaços.
- **Critérios de saída:** retorna `ValidationFailure`; repositório **não** é chamado.

#### S01-UT-03 — Atualização preserva criação
- **O que valida:** semântica de `updatedAt`/imutabilidade.
- **Critérios de entrada:** task existente com `createdAt = T0`; clock em `T1 > T0`.
- **Ação:** `UpdateTask` mudando status para `inProgress`.
- **Critérios de saída:** `createdAt == T0`, `updatedAt == T1`, demais campos preservados.

#### S01-UT-04 — Filtro e ordenação de ListTasks
- **O que valida:** regras de listagem.
- **Critérios de entrada:** repositório mockado com 5 tasks de status/prioridades/dueDates variados.
- **Ação:** listar com filtro `status = todo` e ordenação por prioridade.
- **Critérios de saída:** apenas tasks `todo`, ordenadas prioridade desc; empate resolvido por `dueDate` asc, nulls por último.

#### S01-IT-01 — Round-trip Drift
- **O que valida:** mapeamento entidade ↔ tabela sem perda.
- **Critérios de entrada:** `DriftTaskRepository` com banco em memória.
- **Ação:** salvar task com todos os campos preenchidos (incl. tags e `jiraLink`), ler de volta.
- **Critérios de saída:** objeto lido é igual (==) ao salvo, incluindo tags em ordem e datas com precisão de milissegundo.

#### S01-IT-02 — Stream reativo
- **O que valida:** UI reativa sem polling.
- **Critérios de entrada:** banco em memória vazio; stream de `watchAll()` sob escuta.
- **Ação:** inserir, atualizar e deletar uma task.
- **Critérios de saída:** stream emite após cada mutação com o estado correto (3 emissões além da inicial).

#### S01-IT-03 — Delete idempotente
- **O que valida:** robustez do repositório.
- **Critérios de entrada:** banco com 1 task.
- **Ação:** deletar a mesma task duas vezes.
- **Critérios de saída:** primeira remove; segunda não lança erro e não afeta outras linhas.

#### S01-GT-01 — Tela de tarefas nos 4 estados
- **O que valida:** design system §6 (loading skeleton, vazio, erro, conteúdo).
- **Critérios de entrada:** providers overridados para forçar cada estado.
- **Ação:** renderizar em dark e light, mobile e desktop.
- **Critérios de saída:** goldens estáveis; estado vazio usa `EmptyState`; cards usam `NorteCard`/`StatusBadge`.

#### S01-E2E-01 — CRUD completo pela UI
- **O que valida:** fluxo do usuário de ponta a ponta com persistência real (memória).
- **Critérios de entrada:** app iniciado com Drift em memória, lista vazia.
- **Ação:** criar task "Comprar café" (prioridade alta) → editar título para "Comprar café especial" → marcar como concluída → excluir (confirmando o diálogo).
- **Critérios de saída:** cada passo reflete na tela imediatamente; após criação a task existe no banco; após exclusão a lista mostra `EmptyState` e o banco está vazio.

#### S01-E2E-02 — Cancelamento de exclusão
- **O que valida:** confirmação de ação destrutiva.
- **Critérios de entrada:** app com 1 task.
- **Ação:** iniciar exclusão e cancelar no diálogo.
- **Critérios de saída:** task continua na lista e no banco.

## Definition of Done

- [ ] Gates G1–G6 verdes; cobertura domain+application ≥ 90%.
- [ ] Todos os testes S01-* passando; goldens commitados.
- [ ] Tarefas persistem entre reinícios do app (verificação manual registrada no relatório).
- [ ] Relatório `docs/relatorios/sprint-01-relatorio.md` com evidências.
