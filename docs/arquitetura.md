# Norte — Documento de Arquitetura
**App:** Norte — Assistente Pessoal de Produtividade
**Versão:** 1.0 · **Plataformas:** Android, iOS, Windows · **Framework:** Flutter

---

## 1. Visão Geral

**Norte** é um assistente pessoal para desenvolvedores — "dar um norte" ao dia de trabalho. O nome também funciona como vocativo natural nos comandos de voz ("Norte, cria uma tarefa"). O app é centrado em quatro capacidades: gestão de tarefas com vínculo opcional ao Jira, captura e resumo de reuniões, comandos por voz com intenção e lembretes rápidos por voz. O motor de IA e o motor de transcrição são plugáveis via camadas de abstração, permitindo troca sem impacto no domínio.

### 1.1 Princípios arquiteturais

1. **Clean Architecture** — domínio independente de frameworks, IA e transporte.
2. **Ports & Adapters** — IA, transcrição e Jira são *ports* (interfaces); implementações concretas são *adapters* substituíveis.
3. **Offline-first** — tarefas e lembretes funcionam sem rede; sincronização com Jira é oportunista.
4. **Privacidade por padrão (LGPD)** — transcrições processadas em memória; persistência apenas sob ação explícita do usuário; redação de PII antes de envio a APIs externas.
5. **Camada externa ao Jira** — o app nunca é fonte de verdade do Jira; ele referencia tickets, nunca os espelha integralmente.

---

## 2. Arquitetura em Camadas

```
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION (Flutter UI)                               │
│  Screens · Widgets · State (Riverpod)                   │
├─────────────────────────────────────────────────────────┤
│ APPLICATION (Use Cases)                                 │
│  CreateTask · LinkTaskToJira · SummarizeMeeting         │
│  ExecuteVoiceCommand · CreateVoiceReminder              │
├─────────────────────────────────────────────────────────┤
│ DOMAIN (Entities + Ports)                               │
│  Task · Meeting · Reminder · Intent · MeetingTemplate   │
│  AiEngine · TranscriptionEngine · JiraGateway (ports)   │
├─────────────────────────────────────────────────────────┤
│ INFRASTRUCTURE (Adapters)                               │
│  ClaudeApiEngine · CopilotCliEngine                     │
│  WhisperBatchEngine · ScribeRealtimeEngine              │
│  JiraRestAdapter · DriftDatabase · SecureStorage        │
└─────────────────────────────────────────────────────────┘
```

**Regra de dependência:** setas apontam sempre para dentro. Infrastructure conhece Domain; Domain não conhece ninguém.

### 2.1 Stack técnica

| Camada | Escolha | Justificativa |
|---|---|---|
| State management | Riverpod 2.x | Testável, DI nativa, sem context |
| Persistência local | Drift (SQLite) | Tipado, reativo, multiplataforma incl. Windows |
| Segredos | flutter_secure_storage | Keychain/Keystore/DPAPI (Windows) |
| HTTP | dio + interceptors | Retry, logging redigido, mTLS futuro |
| Áudio (gravação) | record / flutter_sound | Suporte desktop + mobile |
| Áudio (streaming) | web_socket_channel + PCM 16k | Requisito do Scribe v2 Realtime |
| Navegação | go_router | Deep links (abrir ticket via notificação) |
| Serialização | freezed + json_serializable | Imutabilidade no domínio |
| Background | workmanager (mobile) / isolates (Windows) | Sync Jira e lembretes |

---

## 3. Modelo de Domínio

### 3.1 Entidades principais

```dart
class Task {
  final String id;              // UUID local
  final String title;
  final String? description;
  final TaskStatus status;      // todo | inProgress | done | blocked
  final Priority priority;
  final DateTime? dueDate;
  final JiraLink? jiraLink;     // OPCIONAL — vínculo, não espelho
  final List<String> tags;
  final DateTime createdAt, updatedAt;
}

class JiraLink {
  final String issueKey;        // ex: PROJ-123
  final String siteUrl;
  final String? lastKnownStatus;   // cache exibicional, não autoritativo
  final DateTime? lastSyncedAt;
}

class Meeting {
  final String id;
  final String title;
  final MeetingType type;       // daily | retro | planning | oneOnOne | custom
  final String rawTranscript;   // colada pelo usuário OU gerada por Whisper
  final MeetingSummary? summary;
  final List<ActionItem> actionItems;  // conversíveis em Task com 1 toque
  final RetentionPolicy retention;     // ephemeral (default) | persisted
}

class MeetingTemplate {
  final String id;
  final MeetingType type;
  final String systemPrompt;    // instruções ao AiEngine
  final List<TemplateSection> sections; // ex: retro → "o que foi bem", "melhorar", "ações"
  final bool extractActionItems;
}

class Reminder {
  final String id;
  final String text;            // transcrito da voz
  final DateTime triggerAt;
  final String? sourceAudioNote; // descartado após transcrição (LGPD)
}

class VoiceIntent {
  final IntentType type;        // updateJira | addComment | createTask |
                                // createReminder | queryStatus | unknown
  final Map<String, dynamic> slots; // ex: {issueKey, newStatus, comment}
  final double confidence;
}
```

### 3.2 Regras de negócio essenciais

- `Task` existe independentemente do Jira; `JiraLink` pode ser adicionado/removido a qualquer momento.
- Conflito de status (local ≠ Jira): o app **nunca sobrescreve automaticamente** — exibe divergência e pede decisão.
- `Meeting.rawTranscript` com `retention = ephemeral` vive só em memória; sai da tela → é descartado (resta apenas o `summary`, se o usuário salvou).
- `VoiceIntent` com `confidence < 0.75` exige confirmação explícita antes de executar ações mutáveis (especialmente escrita no Jira).

---

## 4. Pilar 1 — Gestão de Tarefas + Vínculo Jira

### 4.1 Estratégia de integração

O app é uma **camada externa**: lê e escreve via Jira Cloud REST API v3, mas mantém identidade própria das tarefas.

```
Task (local, Drift) ──opcional──> JiraLink ──REST──> Jira Cloud
```

**Operações suportadas na v1.0:**
| Operação | Endpoint | Direção |
|---|---|---|
| Vincular ticket | `GET /issue/{key}` (validação) | leitura |
| Atualizar status | `POST /issue/{key}/transitions` | escrita |
| Adicionar comentário | `POST /issue/{key}/comment` | escrita |
| Criar issue a partir de Task | `POST /issue` | escrita |
| Refresh de status | `GET /issue/{key}?fields=status` | leitura |

### 4.2 Autenticação

- **v1.0:** API Token (Basic auth) por simplicidade — armazenado em `flutter_secure_storage`.
- **Evolução:** OAuth 2.0 (3LO) quando houver distribuição pública.

### 4.3 Sincronização

- **Pull sob demanda** + refresh em background a cada 15 min (apenas tasks vinculadas e não concluídas).
- Fila de escrita offline: mutações no Jira entram numa `outbox` local (Drift) e são despachadas quando há rede, com retry exponencial e idempotência por `operationId`.

---

## 5. Pilar 2 — Captura e Resumo de Reuniões

### 5.1 Fluxos de entrada

1. **Transcrição colada** (v1.0 principal): usuário cola texto de qualquer fonte (Teams, Meet, Whisper externo).
2. **Áudio gravado no app → Whisper batch**: gravação local, envio do arquivo ao Whisper, transcrição retorna e alimenta o mesmo pipeline.

### 5.2 Pipeline de resumo

```
transcript ──> PII Redactor (regex BR: CPF, telefone, e-mail)
           ──> MeetingTemplate.systemPrompt + sections
           ──> AiEngine.summarize()
           ──> MeetingSummary + ActionItems
           ──> UI: revisar → converter ActionItems em Tasks
```

### 5.3 Templates configuráveis

Templates são dados, não código — armazenados em Drift e editáveis pelo usuário:

```json
{
  "type": "retro",
  "systemPrompt": "Você é um facilitador ágil. Estruture a retro em...",
  "sections": ["O que foi bem", "O que melhorar", "Itens de ação"],
  "extractActionItems": true
}
```

O app envia `systemPrompt` como prompt de sistema (habilitando **prompt caching** no adapter Claude) e o transcript como user message. Templates padrão embarcados: daily, retro, planning, 1:1.

---

## 6. Pilar 3 — Comandos por Voz com Intenção

### 6.1 Pipeline

```
mic ──PCM 16k──> ScribeRealtimeEngine (WebSocket, ~150ms)
    ──transcript parcial/committed──> IntentParser (AiEngine, JSON estrito)
    ──VoiceIntent──> IntentRouter ──> Use Case correspondente
    ──> Confirmação (se mutável ou confidence < 0.75) ──> Execução
```

### 6.2 Parsing de intenção

O `AiEngine` recebe um prompt curto e cacheável que define o schema de saída:

```json
{
  "intent": "updateJira",
  "slots": { "issueKey": "PROJ-123", "transition": "Done" },
  "confidence": 0.92
}
```

- Resposta **somente JSON** (validada com schema; falha de parse → `IntentType.unknown` → pedir reformulação).
- Slots incompletos → o app pergunta apenas o que falta ("Qual ticket?").
- Ações de **escrita no Jira sempre confirmam** por padrão (configurável).

### 6.3 Intenções da v1.0

| Intenção | Exemplo de fala | Ação |
|---|---|---|
| `updateJira` | "muda o PROJ-123 pra concluído" | Transition via outbox |
| `addComment` | "comenta no PROJ-45: subiu pra staging" | Comment via outbox |
| `createTask` | "cria tarefa revisar PR do conector" | Task local |
| `createReminder` | "me lembra às 15h de responder o e-mail" | Reminder + notificação |
| `queryStatus` | "como tá o PROJ-99?" | GET status + TTS opcional |

---

## 7. Pilar 4 — Abstração do Motor de IA

### 7.1 Port

```dart
abstract interface class AiEngine {
  Future<MeetingSummary> summarize(String transcript, MeetingTemplate tpl);
  Future<VoiceIntent> parseIntent(String utterance, IntentContext ctx);
  Future<String> complete(AiRequest request); // uso genérico
  AiCapabilities get capabilities; // streaming? cache? maxTokens? local?
}
```

### 7.2 Adapters

**`ClaudeApiEngine`** (remoto)
- HTTP via dio → `POST /v1/messages`.
- **Prompt caching** nos system prompts de templates e do intent parser (payload fixo, reduz custo/latência).
- Streaming de resposta para resumos longos (UX progressiva).
- Requer API key do usuário (secure storage) — modelo BYOK na v1.0.

**`CopilotCliEngine`** (local, **somente Windows** na v1.0)
- Invoca o Copilot CLI como subprocesso (`Process.start`), modo programático, stdout parseado.
- `capabilities.isLocal = true` → o PII Redactor pode ser relaxado (dados não saem da máquina).
- Timeout e watchdog: CLI travado → fallback configurável para `ClaudeApiEngine`.
- Em Android/iOS o adapter reporta `unavailable`; a UI oculta a opção.

### 7.3 Seleção e fallback

```dart
final aiEngineProvider = Provider<AiEngine>((ref) {
  final prefs = ref.watch(settingsProvider);
  return switch ((prefs.engine, Platform.isWindows)) {
    (EnginePref.copilotCli, true)  => CopilotCliEngine(fallback: ClaudeApiEngine()),
    _                              => ClaudeApiEngine(),
  };
});
```

Política: falha do motor primário (timeout 30s, erro de processo, rate limit) → 1 retry → fallback (se habilitado) → erro claro ao usuário. Toda troca é logada localmente para diagnóstico.

---

## 8. Pilar 5 — Lembretes Rápidos por Voz

- Captura curta (push-to-talk, ≤15s) → **Scribe Realtime** (mesma infra do Pilar 3).
- Parsing de data/hora natural ("amanhã às 9", "daqui 20 minutos") pelo `AiEngine` no mesmo passo do intent — sem lib de NLP dedicada.
- Agendamento:
  - **Android/iOS:** `flutter_local_notifications` + timezone.
  - **Windows:** `windows_notification` (WinRT toast) + verificação ao abrir o app.
- Áudio original é descartado imediatamente após transcrição confirmada.

---

## 9. Pilar 6 — Abstração de Transcrição

### 9.1 Port com dois modos

```dart
abstract interface class TranscriptionEngine {
  TranscriptionMode get mode; // batch | realtime
}

abstract interface class BatchTranscription implements TranscriptionEngine {
  Future<Transcript> transcribeFile(File audio, {String? language});
}

abstract interface class RealtimeTranscription implements TranscriptionEngine {
  Stream<TranscriptEvent> start(Stream<Uint8List> pcm16k); // partial | committed
  Future<void> stop();
}
```

### 9.2 Adapters e roteamento por caso de uso

| Caso de uso | Motor | Motivo |
|---|---|---|
| Reunião gravada | `WhisperBatchEngine` | Custo baixo, latência irrelevante, arquivos longos |
| Comando de voz | `ScribeRealtimeEngine` | ~150ms, parciais via WebSocket, VAD |
| Lembrete por voz | `ScribeRealtimeEngine` | Fala curta, resposta imediata |

O roteamento é **fixo por caso de uso** (não é escolha do usuário) — evita configuração errada e mantém o custo previsível. Ambos adapters ficam atrás do port, então trocar Whisper por faster-whisper local (futuro) ou Scribe por Deepgram não toca o domínio.

### 9.3 Detalhes do Scribe Realtime

- WebSocket, PCM 16kHz mono, eventos `partial` e `committed`, commit por VAD.
- Reconexão com backoff; buffer local de áudio durante reconexão (≤5s) para não perder fala.

---

## 10. Segurança e LGPD

| Tema | Decisão |
|---|---|
| Transcrições de reunião | Efêmeras por padrão; persistência opt-in por reunião |
| PII antes de API externa | Redação de CPF, telefone, e-mail (regex BR) — desativável quando `AiEngine.isLocal` |
| Segredos (Jira token, Claude key) | Secure storage nativo; nunca em Drift/logs |
| Logs | Estruturados, com redação automática de payloads |
| Áudio de voz | Descartado pós-transcrição; nunca gravado em disco nos fluxos realtime |
| Rede | TLS 1.2+; certificate pinning nos hosts de IA e Jira (v1.1) |
| Direito de exclusão | "Apagar tudo" nas configurações: wipe do Drift + secure storage |

---

## 11. Estrutura de Projeto

```
lib/
├── domain/
│   ├── entities/        (task, meeting, reminder, intent, template)
│   ├── ports/           (ai_engine, transcription_engine, jira_gateway,
│   │                     task_repository, notification_scheduler)
│   └── failures/
├── application/
│   └── usecases/        (create_task, link_jira, summarize_meeting,
│                         execute_voice_command, create_voice_reminder)
├── infrastructure/
│   ├── ai/              (claude_api_engine, copilot_cli_engine)
│   ├── transcription/   (whisper_batch, scribe_realtime)
│   ├── jira/            (jira_rest_adapter, outbox_dispatcher)
│   ├── persistence/     (drift schema, repositories)
│   └── platform/        (audio_capture, notifications — impl por plataforma)
├── presentation/
│   ├── tasks/  meetings/  voice/  reminders/  settings/
│   └── shared/
└── main.dart            (composition root: providers Riverpod)
```

---

## 12. Considerações por Plataforma

| Aspecto | Android/iOS | Windows |
|---|---|---|
| Copilot CLI | Indisponível (UI oculta opção) | Disponível via subprocess |
| Notificações | flutter_local_notifications | WinRT toast + check on launch |
| Background sync | workmanager | Isolate + timer (app aberto) |
| Áudio realtime | record → PCM stream | record (WASAPI por baixo) |
| Secure storage | Keystore / Keychain | DPAPI |

---

## 13. Testes

- **Domain/Application:** unit tests puros (ports mockados) — cobertura alvo 90%.
- **Adapters:** contract tests — os dois `AiEngine` passam pela mesma suíte de contrato (mesmos inputs → shape de output válido).
- **Intent parsing:** dataset de 50+ frases reais em PT-BR (incluindo ambíguas) → assert de intent/slots; roda em CI como eval de regressão.
- **Outbox Jira:** testes de idempotência e retry com servidor fake.
- **Golden tests** nas telas principais.

---

## 14. Roadmap v1.0 (ordem de implementação)

1. **Fundação:** domain + Drift + Riverpod + Tasks CRUD local.
2. **Jira:** JiraLink, adapter REST, outbox, refresh de status.
3. **Reuniões (colada):** templates + `ClaudeApiEngine.summarize` + ActionItems→Tasks.
4. **Whisper batch:** gravação + upload + mesmo pipeline de resumo.
5. **Voz realtime:** Scribe adapter + IntentParser + 5 intenções + confirmação.
6. **Lembretes por voz** + notificações nas 3 plataformas.
7. **CopilotCliEngine** (Windows) + fallback + settings de motor.
8. **Hardening:** PII redactor, wipe, evals de intent em CI.

**Fora do escopo v1.0:** OAuth Jira, captura de áudio do sistema (loopback), sync bidirecional automática, multiusuário, TTS de respostas.

---

## 15. Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Latência do intent (STT + LLM) > 3s | Prompt caching + prompt mínimo + streaming; medir p95 |
| Copilot CLI mudar interface/output | Adapter isolado + contract tests + fallback |
| Custo de API imprevisível | Whisper para batch, disparo por evento, contador de uso nas settings |
| Rate limit Jira | Outbox com backoff + batching de refresh |
| Escrita errada no Jira por intent mal interpretado | Confirmação obrigatória em mutações + threshold de confiança |
