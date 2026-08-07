# Sprint 06 — Voice Reminders + Notifications on All 3 Platforms

**Objective:** quick voice reminders (push-to-talk ≤15s) with natural date/time parsing by the `AiEngine` and scheduled notifications on Android, iOS, and Windows.

**Mandatory references:** `docs/architecture.md` §8, §12 · BR-06

---

## Entry criteria

- [ ] Sprint 05 DoD complete (Scribe realtime + IntentParser working; `Reminder` entity persisted via the stub).
- [ ] `FakeNotificationScheduler` and `FakeClock` available.

## Scope

**In:** `NotificationScheduler` port implemented per platform (`flutter_local_notifications` + timezone on Android/iOS; `windows_notification` WinRT toast + overdue-reminder check on app launch on Windows); complete `CreateVoiceReminder` use case (realtime transcription → date/time parsing from the intent slots → persistence → scheduling); push-to-talk with a 15s limit; Reminders screen (list upcoming/past, cancel, create manually by text as a fallback); notification tap opens the app at the reminder (deep link via go_router).

**Out:** TTS, recurring reminders, snooze.

## Sprint validation rules

- Natural date/time parsing ("tomorrow at 9", "in 20 minutes", "Friday at 3pm") comes from the `AiEngine` slots — no dedicated NLP lib; relative dates resolved against the injected clock and the device timezone.
- A date/time in the past → rejection with a clear message before persisting.
- **BR-06:** `sourceAudioNote` discarded immediately after confirmed transcription; no audio on disk.
- Push-to-talk cuts off at 15s with visual feedback.
- Windows: on app launch, reminders with an already-elapsed `triggerAt` that were not notified fire an immediate toast (§12 — check on launch).
- Cancelling a reminder also cancels the scheduled notification (not just the database row).

## Tests

#### S06-UT-01 — Creation with a relative date
- **What it validates:** the Pillar 5 pipeline.
- **Entry criteria:** `FakeClock` at `2026-08-07T14:00`; fakes: realtime (committed "remind me in 20 minutes to reply to the e-mail" — spoken in PT-BR), AiEngine (`createReminder` intent, slots `{text: "reply to the e-mail", triggerAt: "+20m"}` per the fixture convention); spy scheduler.
- **Action:** `CreateVoiceReminder`.
- **Exit criteria:** reminder persisted with `text = "reply to the e-mail"` and `triggerAt = 14:20`; the scheduler received a schedule for 14:20 with the reminder's id.

#### S06-UT-02 — Past date rejected
- **What it validates:** temporal validation.
- **Entry criteria:** clock at 14:00; intent with triggerAt 13:00 the same day.
- **Action:** `CreateVoiceReminder`.
- **Exit criteria:** `InvalidTriggerTimeFailure`; nothing persisted, nothing scheduled.

#### S06-UT-03 — Complete cancellation
- **What it validates:** database × scheduler consistency.
- **Entry criteria:** future reminder persisted and scheduled in the fake scheduler.
- **Action:** cancel via the use case.
- **Exit criteria:** row removed (or marked cancelled) and `cancel(id)` called on the scheduler with the same id.

#### S06-UT-04 — Audio discard (BR-06)
- **What it validates:** LGPD — audio never outlives the transcription.
- **Entry criteria:** voice flow with FS/stream spies.
- **Action:** create a voice reminder with success and with a parse failure (2 scenarios).
- **Exit criteria:** in both scenarios no audio file exists at the end; `sourceAudioNote` is null on the persisted object.

#### S06-IT-01 — Check on launch (Windows)
- **What it validates:** §12 — the check when the app opens.
- **Entry criteria:** database with 1 overdue non-notified reminder, 1 overdue already-notified, and 1 future; fake scheduler; controlled clock.
- **Action:** run the launch check routine.
- **Exit criteria:** an immediate toast only for the overdue non-notified one (marked as notified afterwards); the future one stays scheduled; the already-notified one does not fire again.

#### S06-IT-02 — Timezone and absolute time
- **What it validates:** scheduling with the correct timezone.
- **Entry criteria:** test timezone pinned to `America/Sao_Paulo`; "tomorrow at 9" intent.
- **Action:** create the reminder.
- **Exit criteria:** `triggerAt` corresponds to 09:00 the next day in the local timezone (correct comparison in UTC).

#### S06-GT-01 — Reminders screen
- **What it validates:** the screen's 4 states + push-to-talk.
- **Entry criteria:** mocked states (empty, with upcoming/past, recording with a 15s countdown).
- **Action:** render dark/light.
- **Exit criteria:** stable goldens; times in the `mono` font; past reminders in `textMuted`.

#### S06-E2E-01 — "Remind me at 3pm to reply to the e-mail" (spoken in PT-BR)
- **What it validates:** Pillar 5 end to end.
- **Entry criteria:** scripted fakes (realtime + AiEngine with the corresponding intent); clock at 14:00; fake scheduler.
- **Action:** push-to-talk → speak → confirm (confidence 0.9, local mutating → executes directly) → open the Reminders tab → "fire" the notification manually in the fake.
- **Exit criteria:** reminder listed for 15:00; the fake's firing navigates to the reminder's screen (deep link); the reminder then appears as past.

#### S06-E2E-02 — Missing time slot
- **What it validates:** the targeted question in the reminder flow.
- **Entry criteria:** `createReminder` intent without `triggerAt`.
- **Action:** voice command "remind me to pay the bill" (spoken in PT-BR).
- **Exit criteria:** the app asks "For when?"; the answer (via the voice script or manual input) completes the slot and the reminder is created; nothing persisted before the answer.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [ ] All S06-* tests passing.
- [ ] Manual script per available platform: a real notification fires with the app in the foreground, background, and closed (mobile), and a Windows toast + check on launch — evidence in the report.
- [ ] Report `docs/reports/sprint-06-report.md`.
