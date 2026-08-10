# Sprint 06 — Voice Reminders + Notifications on All 3 Platforms · Report

**Branch:** `sprint-06/voice-reminders` · **Flutter:** 3.44.9 stable · **Dart:** 3.12.2
**Host:** Windows 11 Pro 26200 (Developer's machine) · **CI:** `ubuntu-latest`

---

## 1. Entry criteria

| Criterion | Evidence | Result |
|---|---|---|
| Sprint 05 DoD complete — Scribe realtime + IntentParser working, `Reminder` persisted via the stub | `docs/reports/sprint-05-report.md`; merged at `57a3cc9`/PR #8. The stub was `CreateReminder`, and this sprint replaces it | ✅ |
| `FakeNotificationScheduler` and `FakeClock` available | `test/fakes/fake_notification_scheduler.dart`, `test/fakes/fake_clock.dart`, both shipped in Sprint 00 | ✅ |

**One thing the criteria do not cover, and it should be read before this PR is
merged.** Sprint 05b's Definition of Done has **one box open** — the manual
pass against the real Scribe, §5 of its report, which says in as many words
that the PR should not merge until it is filled in. PR #11 merged anyway, so
this sprint starts from a `master` carrying an unfinished sprint. Nothing in
Sprint 06 depends on that box: 05b is `taskRef` resolution and reminders
resolve no `taskRef`. But it is open, it is the Developer's to close, and it
does not become closed by a later sprint passing over it.

## 2. Quality gates

| Gate | Command | Result |
|---|---|---|
| G1 — static analysis | `flutter analyze` | `No issues found! (ran in 7.1s)` — 0 errors, 0 warnings, 0 infos ✅ |
| G2 — formatting | `dart format --set-exit-if-changed .` | `Formatted 274 files (0 changed)`, exit 0 ✅ |
| G3 — tests | `flutter test` | `01:09 +825: All tests passed!` ✅ |
| G4 — coverage | `flutter test --coverage` + `dart run tool/check_coverage.dart` | domain+application **94.3%** (764/810) · project **81.8%** (4734/5785) — `gate G4: OK` ✅ |
| G5 — dependency rule | `dart run tool/check_imports.dart` | `check_imports: OK — no layer or color violations in lib` ✅ |
| G6 — secrets | `grep -rEn "(api[_-]?key\|token)[[:space:]]*=[[:space:]]*['\"]" lib/` | no match (exit 1) ✅ |
| E2E | `flutter test integration_test/<suite>`, one per file (DEC-010) | **12 suites, 43 scenarios**, all passing ✅ |

The suite grew from 751 to 825. Domain+application coverage rose 93.9% →
94.3% while that layer gained 96 lines.

**Project coverage fell 84.5% → 81.8%, and the reason is worth naming rather
than absorbing.** Two of this sprint's three new adapters are platform
channels end to end, and `main.dart` — which grew by fifty lines of
composition — has no test at all, as `sprint-05` §5 recorded. 81.8% is above
the 80% floor with less headroom than the sprint before it, and the way back
up is a `main.dart` that can be exercised, not more tests for the two
adapters.

## 3. Tests

| ID | Where | Result |
|---|---|---|
| S06-UT-01 | `test/application/create_voice_reminder_test.dart` | ✅ 2 scenarios — the spoken utterance through the real codec, and the injected clock |
| S06-UT-02 | same | ✅ 4 scenarios — a past time, "now" exactly, an unreadable slot, a blank text |
| S06-UT-03 | same | ✅ 2 scenarios — both halves cancelled, and cancelling nothing |
| S06-UT-04 | same | ✅ 2 scenarios — success and rejected parse |
| S06-IT-01 | `test/application/reminders_launch_and_timezone_test.dart` | ✅ 4 scenarios — including the *second* launch, and a scheduler that refuses |
| S06-IT-02 | same | ✅ 4 scenarios — São Paulo, Rome, today, and the Friday that is not today |
| S06-GT-01 | `test/presentation/goldens/reminders_screen_golden_test.dart` | ✅ 21 scenarios — 5 states × 2 themes × 2 viewports, plus the muted-past assertion |
| S06-E2E-01 | `integration_test/reminders_flow_test.dart` | ✅ 2 scenarios |
| S06-E2E-02 | same | ✅ 2 scenarios — the question, and the typed fallback |

Three suites carry no sprint ID and exist under `docs/project-rules.md` §5.4:
`test/domain/trigger_time_test.dart` (the grammar, exhaustively),
`test/infrastructure/notification_scheduler_contract_test.dart` (the port
contract over every implementation), and
`test/infrastructure/local_notification_scheduler_test.dart`.

### The two assertions that could not pass by accident

**S06-IT-02 runs the same sentence through two zones.** "tomorrow 09:00"
resolves to 12:00 UTC in São Paulo and 07:00 UTC in Rome, from one clock and
one utterance. An implementation that read the zone and one that ignored it
agree on every single-zone assertion in the suite; only this pair separates
them, which is why the sprint's own case is written as two.

**S06-IT-01 asserts the *second* launch.** Delivering an overdue reminder on
the first launch is easy to get right. The case that matters is the one a
user meets every morning: the same reminder must not shout again, and only
`isFired` having been written makes that true.

### What the fake could not be lenient about

`FakeNotificationScheduler` and `WindowsToastScheduler` go through **one
contract suite**, per `docs/testing-strategy.md` §3 and the lesson of
`sprint-05` §5 — a fake written from what the caller expected agrees with the
caller about everything, including what both got wrong. Replacement by id,
ordering by `triggerAt`, and cancel-as-no-op are asserted against both.

`LocalNotificationScheduler` is deliberately **not** in that loop: every one
of its methods is a platform channel, so a contract test over it would be a
test of mocktail. What can be checked without a device is checked in its own
file — the id it derives, the payload it writes and reads back, the branch
that shows an overdue notification when the plugin refuses to schedule one,
and both failure translations.

## 4. What was built

**Domain.** `TimeZone` (port) with `FixedOffsetTimeZone` for tests and the
fallback; `TriggerTime`, which reads the five slot shapes
`IntentCodec.systemPrompt` tells the model to produce; and
`InvalidTriggerTimeFailure`, distinct from `ValidationFailure` because "say
another time" and "say it another way" send the user to different places.

**Application.** `CreateVoiceReminder` replaces the Sprint 05 stub —
validate, resolve, reject the past, **persist, then schedule**, in that
order. `CancelReminder` reaches the row *and* the registration.
`CheckDueReminders` is §12's check on launch.

**Infrastructure.** `LocalNotificationScheduler` (Android/iOS, via
`flutter_local_notifications` + `timezone`); `WindowsToastScheduler`
(WinRT toast via `windows_notification`); `PlatformTimeZone`, reading the
device zone from the same IANA database the mobile scheduler schedules
against.

**Presentation.** The reminders screen with its four states, an upcoming/past
split decided against the clock, cancel per row; `PushToTalkBar` with the
15-second countdown; `ReminderCapture`, the push-to-talk notifier;
a typed fallback and the targeted "for when?" sheet; `ReminderDetailScreen`
at `/reminders/:id`, which is where a tapped notification lands.

### Why there are two adapters rather than one with a branch

`windows_notification` shows a toast **now**. There is no "show this in two
hours" to hand WinRT, and nothing registered survives the app closing —
whereas `flutter_local_notifications` hands Android and iOS a registration
the OS keeps across a reboot. So the Windows adapter owns a `Timer` per
pending notification, and §12's check on launch is what covers the gap
between sessions. Neither half is optional there: the timers alone lose every
reminder at exit, and the launch check alone would only ever notify people
who happened to restart the app.

The same routine runs on mobile, where it is merely idempotent —
`schedule` replaces by id, so re-registering something already registered
cannot double-fire. One routine that behaves the same everywhere is worth
more than a platform branch nobody exercises on the other platform.

### The reminder id is not `String.hashCode`

`flutter_local_notifications` keys on an `int` and a `ScheduledNotification`
keys on a `String`. `notificationIdOf` is FNV-1a, because nothing in the
language promises `String.hashCode` is stable across processes or SDK
versions — and a `cancel` that computed a different number from the same
reminder would cancel nothing, leaving a notification to fire for something
the user deleted last week. The test pins the *specific* number, so changing
the algorithm (which would orphan every notification already registered on
every installed device) has to be a deliberate edit rather than a silent one.

## 5. Two things fixed that the sprint did not ask for

**`voiceLocaleProvider` was never overridden.** It always returned `pt-BR`
(`sprint-05` handoff §6 recorded it open), so a user reading the app in
English or Italian had their speech parsed as Portuguese. It could not stay
that way here: the notification title has to be localized *before* the
platform is handed it (BR-11), and the use case that hands it over has no
`BuildContext`. `appLocaleProvider` is now written into by `NorteApp` from
the locale `MaterialApp` resolved, and `voiceLocaleProvider` derives from it,
so there is one answer to "what language is this user in" rather than two
that can disagree.

The obvious implementation — a nested `ProviderScope` under `MaterialApp` —
is in the dartdoc as the thing **not** to do: a provider that is not itself
overridden initialises in the root container, so everything depending on the
locale would keep reading the default while the scope below held the real
one. It would have looked correct and done nothing.

**The Android manifest had none of the permissions this needs.**
`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`,
`RECEIVE_BOOT_COMPLETED`, and the two `flutter_local_notifications`
receivers. Without the boot receiver every reminder set before a restart is
silently lost — and no test in this repository could ever have said so, which
is precisely why it is listed here and in §6's manual script.

## 6. The manual script per platform — **OUTSTANDING**

**This is the box that is not ticked, and it cannot be ticked by anyone but
the Developer.** The DoD asks for a real notification firing with the app in
the foreground, in the background, and closed on mobile, plus a Windows toast
and the check on launch. Every test above replaces the notification platform
with a fake; what no fake can answer is whether the OS actually delivers.

### Windows

**Run `tool/register_windows_toast.ps1` once first.** Windows shows no toast
for an unpackaged Win32 app unless a Start Menu shortcut carries the same
AUMID the app files notifications under, and `flutter run -d windows` creates
no such shortcut. Skipping this makes every row below fail identically and
silently, for a reason that is not the code.

| # | Do | Expected | What it proves |
|---|---|---|---|
| 1 | Speak "me lembra em dois minutos de olhar o build", keep the app open | A toast after two minutes, titled **Lembrete** | The timer path, and the AUMID in `main.dart` matching the shortcut |
| 2 | Click the toast | Norte opens `/reminders/<id>` on that reminder | The tap callback and the deep link |
| 3 | Create a reminder two minutes out, **close Norte**, wait three minutes, reopen | A toast immediately on launch, and the row shows under **Past** | The check on launch — the half that has no timer behind it |
| 4 | Create one an hour out, close and reopen Norte | No toast; the reminder is still listed as upcoming | The launch check re-registers rather than firing everything overdue |
| 5 | Repeat 3 twice without cancelling | The toast fires **once**, on the first reopen | `isFired`, and the defect a user meets every morning |

If step 1 shows nothing at all, the AUMID is still the first suspect: the
shortcut has to point at the executable actually running, so a shortcut
registered against the Debug build proves nothing about a Release one. Re-run
the script with `-Target` to move it. Windows also caches the AUMID table, so
a first toast that does not appear may just need Explorer restarted.

**Steps 1 and 2 need a Scribe key and a Claude key** — they go through the
voice pipeline. Steps 3–5 do not: use **Type it instead** on the reminders
screen with `+2m` as the time, and the notification path is exercised with no
key configured at all. That is the fastest way to find out whether the toast
works before spending anything on an API call.

### Android

| # | Do | Expected |
|---|---|---|
| 6 | First launch | The notification permission is asked for |
| 7 | Reminder two minutes out, app in the **foreground** | The notification appears |
| 8 | Same, app in the **background** | Same |
| 9 | Same, app **swiped away** | Same — this is the one the exact-alarm permissions are for |
| 10 | Reminder ten minutes out, **reboot the device**, wait | It still fires — the boot receiver |
| 11 | Tap any of them | Norte opens on that reminder, from a cold start as well as a warm one |
| 12 | Refuse the permission, then create a reminder | The row is saved and the screen says the notification will not sound |

### iOS

**Not run, and not runnable here.** iOS has never been built or tested in
this project (`sprint-05` handoff §6, DEC-020), and Sprint 08 has to decide
whether v1.0 ships two platforms or three. Steps 6–12 apply unchanged when
somebody has a Mac.

**Until this section is filled in with real runs, the Definition of Done is
incomplete.**

## 7. Deviations

**One documented test's entry criteria were read differently than written.**
S06-UT-01 lists a realtime fake among its entry criteria; the test drives
`FakeAiEngine` and the real `IntentCodec` to produce the intent, then calls
the use case, and does **not** stand up a realtime session. The realtime leg
of that pipeline is asserted end to end by S06-E2E-01 through the real
composition root, where it is a stronger claim; duplicating it in a unit test
would have added a second fake and no assertion. Both halves of the exit
criteria — `triggerAt = 14:20` and the scheduler receiving the reminder's own
id — are asserted exactly as specified.

Nothing else in the sprint document was altered.

## 8. Notes for the next sprint

**`primeCache()` is still unverified** — carried forward from Sprint 05's
handoff §3, Sprint 05a §7 and Sprint 05b §7, untouched again.

**Sprint 05b's manual pass is still open** — §1 above.

**`WindowsToastScheduler.pending()` is in-memory, and honestly so.** It
reports what this process scheduled, which is all the platform knows.
`LocalNotificationScheduler.pending()` reads the OS's own list and restores
each `triggerAt` from the payload, because the platform reports the int key
and the text and nothing else. Both keep the port's ordering promise; only
one of them survives a restart.

**The reminder notification's title is the only localized string that
crosses into a use case.** `ReminderNotificationCopy` exists so that BR-11
holds at the point where text leaves the app for the operating system. If a
future sprint needs a second such string — a snooze action's label, say —
that port is where it goes, not a new parameter on a use case.

## 9. Definition of Done

- [x] Gates G1–G6 green; domain+application coverage ≥ 90% — **94.3%**, §2.
- [x] All S06-* tests passing — 9 IDs, 43 scenarios, §3.
- [ ] Manual script per available platform: a real notification with the app
      in the foreground, background and closed (mobile), and a Windows toast
      plus the check on launch — **outstanding**, §6. It is the Developer's to
      run, and the sprint is not closed until it is.
- [x] Report `docs/reports/sprint-06-report.md` — this document.
