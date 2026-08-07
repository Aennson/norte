# Sprint 04 — Whisper Batch: Gravação de Áudio e Transcrição de Reuniões

**Objetivo:** segundo fluxo de entrada de reuniões — gravar áudio no app, transcrever via `WhisperBatchEngine` e alimentar o **mesmo** pipeline de resumo da Sprint 03.

**Referências obrigatórias:** `docs/arquitetura.md` §5.1, §9 · RN-03, RN-07

---

## Critérios de entrada

- [ ] Sprint 03 com DoD completo (pipeline de resumo funcionando).
- [ ] `FakeBatchTranscription` disponível.

## Escopo

**Dentro:** ports `TranscriptionEngine`/`BatchTranscription` (interface da §9.1); `WhisperBatchEngine` (upload de arquivo, key em secure storage, idioma opcional); captura de áudio (`record`) com permissão de microfone, indicador de gravação (tempo decorrido, nível), pausa/retomada, limite configurável (default 90 min); use case `TranscribeMeetingAudio` que conecta gravação → transcrição → pipeline da Sprint 03; estados de progresso na UI (gravando → enviando → transcrevendo → resumindo).

**Fora:** transcrição realtime/Scribe (Sprint 05), captura de áudio do sistema (fora do escopo v1.0).

## Regras de validação da sprint

- Arquivo de áudio de reunião é **temporário**: gravado em diretório temp do app, excluído após transcrição bem-sucedida **ou** quando o usuário descarta; nunca no diretório de documentos.
- Transcrição concluída entra no pipeline da Sprint 03 **sem código duplicado** — mesmo use case `SummarizeMeeting`, mesmas regras de PII e retenção (RN-03/RN-07 se aplicam ao transcript gerado).
- Permissão de microfone negada → tela explicativa com link para configurações do sistema; nunca crash.
- Falha de upload/transcrição → o arquivo de áudio local é **mantido** e o usuário pode tentar de novo sem regravar.
- Interrupção da gravação (chamada telefônica, app em background em mobile) → gravação pausada e recuperável.

## Testes

#### S04-UT-01 — Orquestração do fluxo
- **O que valida:** transcrever → resumir sem duplicação.
- **Critérios de entrada:** `TranscribeMeetingAudio` com `FakeBatchTranscription` (retorna transcript fixo) e `SummarizeMeeting` espião; arquivo fake.
- **Ação:** executar com template daily.
- **Critérios de saída:** `SummarizeMeeting` recebido exatamente o transcript do engine e o template escolhido; estados emitidos na ordem enviando → transcrevendo → resumindo → concluído.

#### S04-UT-02 — Falha de transcrição preserva o áudio
- **O que valida:** regra de retry sem regravar.
- **Critérios de entrada:** fake programado para `TranscriptionFailure`; arquivo fake existente.
- **Ação:** executar; verificar arquivo; reexecutar com fake ok.
- **Critérios de saída:** após a falha o arquivo ainda existe e o erro é propagado; o retry funciona com o mesmo arquivo; após sucesso o arquivo é excluído.

#### S04-UT-03 — Limpeza pós-sucesso e pós-descarte
- **O que valida:** ciclo de vida do arquivo temporário.
- **Critérios de entrada:** gravação concluída em diretório temp fake.
- **Ação:** cenário A: fluxo completo com sucesso; cenário B: usuário descarta antes de transcrever.
- **Critérios de saída:** em ambos os cenários o arquivo é excluído; nenhum arquivo de áudio remanescente no diretório.

#### S04-IT-01 — WhisperBatchEngine: request correto
- **O que valida:** conformidade com a API de transcrição.
- **Critérios de entrada:** servidor HTTP fake; arquivo de áudio pequeno de fixture; key fake.
- **Ação:** `transcribeFile(audio, language: 'pt')`.
- **Critérios de saída:** multipart com o arquivo e o idioma; auth presente; resposta parseada em `Transcript` com o texto do fake; 401 → `AuthFailure`; 5xx → `TranscriptionFailure`.

#### S04-CT-01 — Contrato BatchTranscription
- **O que valida:** `WhisperBatchEngine` (servidor fake) e `FakeBatchTranscription` no mesmo contrato.
- **Critérios de entrada:** suíte parametrizada; mesmo arquivo fixture.
- **Ação:** `transcribeFile` em cada adapter; casos: sucesso, arquivo inexistente, erro de servidor.
- **Critérios de saída:** mesmo shape de `Transcript` e mesmos `Failure`s nos dois adapters.

#### S04-GT-01 — Tela de gravação
- **O que valida:** UI de gravação no design system.
- **Critérios de entrada:** estados gravando / pausado / enviando / transcrevendo mockados.
- **Ação:** renderizar dark/light.
- **Critérios de saída:** goldens estáveis; timer em fonte `mono`; indicador de gravação usa `accent`; progresso por etapa visível.

#### S04-E2E-01 — Gravar → transcrever → resumir
- **O que valida:** Pilar 2 fluxo 2 de ponta a ponta.
- **Critérios de entrada:** app com `FakeBatchTranscription` (transcript de daily) e `FakeAiEngine` (resumo de daily); captura de áudio fake injetada (produz arquivo dummy).
- **Ação:** nova reunião → "Gravar áudio" → gravar → parar → confirmar transcrição → processar com template daily → salvar.
- **Critérios de saída:** resumo com as seções do daily na tela; meeting salvo; arquivo de áudio ausente do sistema de arquivos ao final (verificado por assert).

#### S04-E2E-02 — Permissão de microfone negada
- **O que valida:** UX de permissão.
- **Critérios de entrada:** provider de permissão overridado para "negado".
- **Ação:** tentar iniciar gravação.
- **Critérios de saída:** tela explicativa com ação para configurações; nenhum crash; voltar e usar o fluxo de colar continua funcionando.

## Definition of Done

- [ ] Gates G1–G6 verdes; cobertura domain+application ≥ 90%.
- [ ] Todos os testes S04-* passando.
- [ ] Roteiro manual: gravação real de ~1 min em cada plataforma disponível + transcrição Whisper real (key própria) → evidência no relatório.
- [ ] Relatório `docs/relatorios/sprint-04-relatorio.md`.
