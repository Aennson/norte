# Sprint 06 — Lembretes por Voz + Notificações nas 3 Plataformas

**Objetivo:** lembretes rápidos por voz (push-to-talk ≤15s) com parsing de data/hora natural pelo `AiEngine` e notificações agendadas em Android, iOS e Windows.

**Referências obrigatórias:** `docs/arquitetura.md` §8, §12 · RN-06

---

## Critérios de entrada

- [ ] Sprint 05 com DoD completo (Scribe realtime + IntentParser funcionando; entidade `Reminder` persistida via stub).
- [ ] `FakeNotificationScheduler` e `FakeClock` disponíveis.

## Escopo

**Dentro:** port `NotificationScheduler` implementado por plataforma (`flutter_local_notifications` + timezone em Android/iOS; `windows_notification` WinRT toast + verificação de lembretes vencidos ao abrir o app no Windows); use case `CreateVoiceReminder` completo (transcrição realtime → parse de data/hora nos slots do intent → persistência → agendamento); push-to-talk com limite de 15s; tela de Lembretes (listar futuros/passados, cancelar, criar manualmente por texto como fallback); disparo da notificação abre o app no lembrete (deep link via go_router).

**Fora:** TTS, lembretes recorrentes, snooze.

## Regras de validação da sprint

- Parsing de data/hora natural ("amanhã às 9", "daqui 20 minutos", "sexta às 15h") vem dos slots do `AiEngine` — sem lib de NLP dedicada; datas relativas resolvidas contra o relógio injetado e o timezone do dispositivo.
- Data/hora no passado → rejeição com mensagem clara antes de persistir.
- **RN-06:** `sourceAudioNote` descartado imediatamente após transcrição confirmada; nenhum áudio em disco.
- Push-to-talk corta em 15s com feedback visual.
- Windows: ao abrir o app, lembretes com `triggerAt` já vencido e não notificados disparam toast imediato (§12 — check on launch).
- Cancelar lembrete cancela também a notificação agendada (não só a linha no banco).

## Testes

#### S06-UT-01 — Criação com data relativa
- **O que valida:** pipeline do Pilar 5.
- **Critérios de entrada:** `FakeClock` em `2026-08-07T14:00`; fakes: realtime (committed "me lembra daqui 20 minutos de responder o e-mail"), AiEngine (intent `createReminder`, slots `{text: "responder o e-mail", triggerAt: "+20m"}` na convenção do fixture); scheduler espião.
- **Ação:** `CreateVoiceReminder`.
- **Critérios de saída:** reminder persistido com `text = "responder o e-mail"` e `triggerAt = 14:20`; scheduler recebeu agendamento para 14:20 com o id do reminder.

#### S06-UT-02 — Data no passado rejeitada
- **O que valida:** validação temporal.
- **Critérios de entrada:** clock em 14:00; intent com triggerAt 13:00 do mesmo dia.
- **Ação:** `CreateVoiceReminder`.
- **Critérios de saída:** `InvalidTriggerTimeFailure`; nada persistido, nada agendado.

#### S06-UT-03 — Cancelamento completo
- **O que valida:** consistência banco × scheduler.
- **Critérios de entrada:** reminder futuro persistido e agendado no fake scheduler.
- **Ação:** cancelar pelo use case.
- **Critérios de saída:** linha removida (ou marcada cancelada) e `cancel(id)` chamado no scheduler com o mesmo id.

#### S06-UT-04 — Descarte do áudio (RN-06)
- **O que valida:** LGPD — áudio nunca sobrevive à transcrição.
- **Critérios de entrada:** fluxo de voz com FS/streams espiões.
- **Ação:** criar lembrete por voz com sucesso e com falha de parse (2 cenários).
- **Critérios de saída:** nos dois cenários nenhum arquivo de áudio existe ao final; `sourceAudioNote` nulo no objeto persistido.

#### S06-IT-01 — Check on launch (Windows)
- **O que valida:** §12 — verificação ao abrir o app.
- **Critérios de entrada:** banco com 1 reminder vencido não-notificado, 1 vencido já notificado e 1 futuro; scheduler fake; clock controlado.
- **Ação:** executar a rotina de verificação de abertura.
- **Critérios de saída:** toast imediato apenas para o vencido não-notificado (marcado como notificado após); o futuro permanece agendado; o já notificado não dispara de novo.

#### S06-IT-02 — Timezone e horário absoluto
- **O que valida:** agendamento com timezone correto.
- **Critérios de entrada:** timezone do teste fixado em `America/Sao_Paulo`; intent "amanhã às 9".
- **Ação:** criar reminder.
- **Critérios de saída:** `triggerAt` corresponde a 09:00 do dia seguinte no timezone local (comparação em UTC correta).

#### S06-GT-01 — Tela de lembretes
- **O que valida:** 4 estados da tela + push-to-talk.
- **Critérios de entrada:** estados mockados (vazio, com futuros/passados, gravando com contador regressivo de 15s).
- **Ação:** renderizar dark/light.
- **Critérios de saída:** goldens estáveis; horários em fonte `mono`; lembretes passados com `textMuted`.

#### S06-E2E-01 — "Me lembra às 15h de responder o e-mail"
- **O que valida:** Pilar 5 de ponta a ponta.
- **Critérios de entrada:** fakes roteirizados (realtime + AiEngine com o intent correspondente); clock em 14:00; scheduler fake.
- **Ação:** push-to-talk → falar → confirmar (confidence 0.9, mutável local → executa direto) → abrir aba Lembretes → "disparar" a notificação manualmente no fake.
- **Critérios de saída:** lembrete listado para 15:00; disparo do fake navega para a tela do lembrete (deep link); lembrete passa a constar como passado.

#### S06-E2E-02 — Slot de horário ausente
- **O que valida:** pergunta dirigida no fluxo de lembrete.
- **Critérios de entrada:** intent `createReminder` sem `triggerAt`.
- **Ação:** comando de voz "me lembra de pagar o boleto".
- **Critérios de saída:** app pergunta "Para quando?"; resposta (segundo roteiro de voz ou input manual) completa o slot e o lembrete é criado; nada persistido antes da resposta.

## Definition of Done

- [ ] Gates G1–G6 verdes; cobertura domain+application ≥ 90%.
- [ ] Todos os testes S06-* passando.
- [ ] Roteiro manual por plataforma disponível: notificação real dispara com app em foreground, background e fechado (mobile) e toast Windows + check on launch — evidências no relatório.
- [ ] Relatório `docs/relatorios/sprint-06-relatorio.md`.
