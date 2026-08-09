# Sprint 10 — The Audit Log: an account of what the app did

**Objective:** give the app a durable, queryable, exportable record of every
action it takes on the user's data — what happened, when, on whose instruction,
and how it ended — without recording a single word of what was said, typed, or
transcribed.

**Mandatory references:** `docs/architecture.md` §2, §10, §11 · BR-03, BR-06,
BR-07, BR-08, BR-10, BR-11, BR-12 · `docs/reports/decisions.md` DEC-033

> **Scheduled last, deliberately.** This sprint instruments code that every
> other sprint wrote. Running it earlier would mean instrumenting a moving
> target and re-instrumenting after each sprint; running it last means the
> surface it records is finished. Nothing in Sprints 00–09 depends on it, and
> it changes no existing behaviour — see *Why last, and what that costs* below.

---

## Why this sprint exists

The app writes to the user's tasks, pushes changes into their team's Jira,
listens to their microphone, sends redacted text to a third party, and holds
three credentials. Today it can tell the user what its data *currently looks
like*. It cannot tell them **what it did to get there.**

Three concrete questions have no answer today:

1. *"Why is PROJ-123 marked Done? I didn't do that."* — The app may have
   transitioned it from a voice command, from the outbox retrying, or the
   change may have come from a teammate and merely been refreshed into the
   display cache. Three very different facts, indistinguishable after the fact.
2. *"Something was sent to Claude — what, and when?"* — The `[ai]` diagnostic
   answers this while the console is open and forgets it the moment the app
   closes.
3. *"I pressed 'delete everything'. Did it actually run?"* — The evidence that
   a wipe happened is destroyed by the wipe.

An audit log answers all three. What it must **never** become is a second copy
of the data it is auditing: this app's whole privacy posture (BR-03, BR-06,
BR-07, BR-08) rests on transcripts, audio and secrets not being written down,
and an audit trail that quietly wrote them down would undo every one of those
rules at once. That constraint is the design, not a caveat on it — see
*The rule this sprint adds* below.

## The rule this sprint adds

**BR-12 — the audit log records facts about actions, never the content of
them.** An entry says *that* a task was created, *which* task, *when*, on whose
instruction, and how it ended. It never carries a title, a description, a
comment body, an utterance, a transcript, a summary, a Jira payload, a
credential, or any free text a person wrote or spoke.

The distinction is the one this codebase already practises in its diagnostics —
`[voice]` logs `committed segment: 98 chars`, never the segment; `[ai]` logs
token counts, never the prompt. This sprint promotes that habit to a rule and
makes it checkable (S10-UT-08, `tool/check_audit.dart`).

**What may be recorded:** entity type and id; enum values (intent type, status,
priority, outcome, failure type, engine id, model id); counts, lengths,
durations, token counts, confidence scores; timestamps; the actor.

**What may never be recorded:** any string the user or the model authored. When
in doubt, the length of it is a fact; the text of it is content.

## Entry criteria

- [ ] Sprints 00–09 with DoD complete and merged; all S00–S09 tests green in
      CI.
- [ ] No sprint open. This one rewrites call sites across every use case, and
      doing that under another sprint's branch would make both unreviewable.
- [ ] `docs/reports/decisions.md` DEC-033 accepted (the wipe rule of §"Right to
      erasure" below changes an existing guarantee and must be decided before
      it is built, not after).

## Scope

**In:**

*Domain* — `AuditEvent` (`freezed`): `id`, `occurredAt` (UTC), `actor`,
`category`, `action`, `subject` (`AuditSubject`: entity type + id, both
enum/opaque), `outcome` (`ok` | `failed`, with the `Failure` subtype's name
when failed), and `details: Map<String, Object>` restricted to scalars.
`AuditActor` (`user`, `app`, `sync`), `AuditCategory` (`task`, `jira`,
`meeting`, `voice`, `reminder`, `engine`, `security`), and the `AuditAction`
enumeration. Port `AuditLog` with `record`, `query`, `purgeOlderThan`, and
`count`. `AuditQuery` (category set, actor set, date range, outcome, limit).

*Infrastructure* — `DriftAuditLog`, a table and the schema migration for it
(the next schema version at the time of execution — Sprints 05a, 06 and 07 each
move it, so the number is deliberately not fixed here). Retention: a rolling
window of **180 days or 50 000 entries, whichever comes first**, enforced on
write. `AuditExporter` writing NDJSON to a path the user chooses.

*Application* — `RecordAuditEvent`, and the instrumentation of every existing
mutating use case (see *The event taxonomy*). `PurgeAuditLog`. `ExportAuditLog`.

*Presentation* — an Audit section in Settings: a reverse-chronological list,
filters for category/actor/date/outcome, the 4 mandatory screen states, and an
Export button. Strings in all three ARBs (BR-11).

*Tooling* — `tool/check_audit.dart`, run in CI beside `tool/check_imports.dart`:
every use case under `lib/application/usecases/` that writes must map to an
`AuditAction`, and no `AuditEvent` construction may pass a value whose static
type is `String` outside the allowed keys (BR-12, mechanically).

**Out:**

- **Reading anything back into the app.** The log is written and displayed;
  nothing in the app ever branches on its contents. An audit trail that changes
  behaviour is a data store with an audit trail's name.
- **Remote or shared logs.** Nothing is uploaded. This is the user's record of
  their own machine.
- **Tamper-*proofing*.** §"What the hash chain does and does not prove" is
  explicit about the limit; a stronger guarantee needs a server, which v1.x
  does not have.
- **Editing or deleting individual entries.** All-or-nothing, via retention or
  the wipe. A log with a delete button is a draft.
- Instrumenting reads. Opening a screen is not an action on the user's data;
  recording it would bury the entries that matter under navigation noise.

## Sprint validation rules

- **BR-12 holds mechanically, not by review.** `tool/check_audit.dart` fails the
  build on a free-text value reaching an event. A rule enforced only by
  reviewers is a rule that survives exactly as long as attention does.
- **Every mutating use case records exactly one event.** Not zero (a silent
  mutation), not two (a double-count that makes the log's own arithmetic wrong).
  The event is recorded **after** the mutation succeeds or fails, carrying the
  outcome — never before, which would record intentions as facts.
- **Recording never fails a command.** A full disk, a locked database, a
  migration mid-flight: the audit write is best-effort and its failure is
  swallowed after being surfaced to the diagnostics sink. The user's task gets
  created even if the note about it does not. *(The audio-meter defect of
  Sprint 05, §7.4: a diagnostic that can break what it observes is worse than
  no diagnostic.)*
- **The log is written in the application layer**, at use-case boundaries —
  never in `infrastructure/`. A repository does not know whether it was called
  by the user, by the outbox, or by a sync, and `actor` is exactly that
  distinction.
- **Timestamps come from the injected `Clock`** (`docs/project-rules.md` §5.5).
- **BR-08 is not relaxed.** A credential event records that a slot was written,
  which slot, and by whom — never the value, never a prefix of it, never its
  length.
- **Right to erasure keeps working.** "Delete everything" wipes the audit log
  too, and then writes exactly one event recording that the wipe happened, with
  the count of entries it removed. That single entry is the log's whole content
  afterwards. *(Rationale and the alternative considered: DEC-033.)*

## The event taxonomy

The complete set for v1.x. `tool/check_audit.dart` holds this list; adding a
use case without adding its action fails the build.

| Category | Actions |
|---|---|
| `task` | `created`, `updated`, `deleted`, `commented` |
| `jira` | `linked`, `unlinked`, `operationEnqueued`, `operationSent`, `operationFailed`, `statusRefreshed`, `conflictShown`, `conflictResolved` |
| `meeting` | `recorded`, `transcribed`, `summarized`, `saved`, `discarded`, `actionItemConverted` |
| `voice` | `sessionStarted`, `sessionStopped`, `commandExecuted`, `commandNotUnderstood`, `confirmationShown`, `confirmationAccepted`, `confirmationRefused` |
| `reminder` | `created`, `fired`, `dismissed`, `cancelled` |
| `engine` | `requestSucceeded`, `requestFailed`, `fellBack` (BR-10's "every switch is logged" gets its home here) |
| `security` | `credentialStored`, `credentialCleared`, `settingChanged`, `dataWiped`, `auditExported` |

## What the hash chain does and does not prove

Each row carries the SHA-256 of `(previous row's hash ‖ this row's canonical
fields)`. Verification walks the chain and reports the first row where it
breaks.

**It proves:** that no row was silently altered or removed *by the app* — a
regression that rewrote history would be caught by the verifier, and so would a
partial write.

**It does not prove** that the user did not edit the SQLite file themselves.
They own the machine and the file; nothing running on that machine can prevent
it. The chain is an integrity check, not a custody guarantee, and the Audit
screen must say so in those terms rather than displaying a padlock. Claiming
more than this would be the app lying to its user about its own limits — the
exact failure the audio meter taught (`sprint-05` report §7.4).

## Why last, and what that costs

Instrumenting nine sprints of finished code in one pass is a large, boring,
error-prone change. Two things make it tractable, and both are load-bearing:

1. **One layer.** Every event is recorded in `application/`, so the change is
   confined to use cases — not scattered across repositories, adapters and
   widgets where it could not be reviewed as a whole.
2. **A completeness check, not a checklist.** `tool/check_audit.dart` is what
   makes "every mutating use case" a fact rather than an intention. Written
   first, it fails loudly and lists exactly what is missing; the sprint is done
   when it passes.

The cost is honest: this sprint touches more files than any since Sprint 01,
and its risk is a missed call site rather than a broken one. That is what the
tool and S10-UT-08 exist to remove.

## Tests

#### S10-UT-01 — An event carries facts, never content
- **What it validates:** BR-12, the sprint's central rule.
- **Entry criteria:** a `createTask` command whose title is
  "Ligar para Samara sobre o orçamento" and whose description is non-empty.
- **Action:** run the use case with a fake `AuditLog`; read the recorded event.
- **Exit criteria:** exactly one event; `subject` names the task's id and type;
  no field of the event, serialized to JSON, contains "Samara", "orçamento", or
  any substring of the title or description. Length-of-title as an integer is
  permitted and asserted present.

#### S10-UT-02 — Every mutating use case records exactly one event
- **What it validates:** the completeness rule.
- **Entry criteria:** each mutating use case in `lib/application/usecases/`,
  with fakes for its ports.
- **Action:** execute each, once, on the success path.
- **Exit criteria:** exactly one event per execution, with the `AuditAction`
  the taxonomy assigns it. A use case with no mapping fails the test by name,
  so the failure message says which one.

#### S10-UT-03 — A failed action is recorded as failed, not omitted
- **What it validates:** that the log is not a record of successes.
- **Entry criteria:** `UpdateJiraStatus` with a gateway that raises
  `AuthFailure`; `CreateTask` with a repository that raises.
- **Action:** run each.
- **Exit criteria:** one event each, `outcome = failed`, carrying the failure
  subtype's **name**; the failure's `message` is **not** carried (it can quote
  user content). The use case still returns its `Err` unchanged.

#### S10-UT-04 — A broken audit log never breaks the command
- **What it validates:** the best-effort rule.
- **Entry criteria:** an `AuditLog` that throws on `record`.
- **Action:** run `CreateTask`.
- **Exit criteria:** the task is created and `Ok` is returned; the audit
  failure reached the diagnostics sink exactly once; nothing propagated.

#### S10-UT-05 — The actor distinguishes the user from the machine
- **What it validates:** the question "*I didn't do that*" is answerable.
- **Entry criteria:** the same Jira transition arriving three ways — a voice
  command, an outbox retry, and a status refresh from the server.
- **Action:** run each.
- **Exit criteria:** `actor` is `user`, `app` and `sync` respectively, and the
  three are distinguishable by no other field.

#### S10-UT-06 — Retention is enforced on write, by age and by count
- **What it validates:** the rolling window.
- **Entry criteria:** a log holding 50 000 entries; separately, a log holding
  entries 181 days old (`FakeClock`).
- **Action:** record one more.
- **Exit criteria:** the oldest is gone in both cases, count never exceeds the
  cap, and the newest is intact. Purging is not itself an audit event
  (retention is not an action on user data).

#### S10-UT-07 — The wipe leaves exactly one entry, and it is the wipe
- **What it validates:** the right-to-erasure rule (DEC-033).
- **Entry criteria:** a log with 40 assorted entries.
- **Action:** run the "delete everything" use case.
- **Exit criteria:** the log holds exactly one entry, `security/dataWiped`, with
  `removedCount = 40`; the hash chain restarts from it and verifies.

#### S10-UT-08 — The BR-12 checker catches a free-text field
- **What it validates:** `tool/check_audit.dart`, i.e. the enforcement itself.
- **Entry criteria:** a fixture use case that puts a task's title into
  `details`; and a second that puts its length.
- **Action:** run the checker over both.
- **Exit criteria:** the first fails, naming file and line; the second passes.
  *(A checker with no failing case is a checker nobody has seen work.)*

#### S10-UT-09 — Query filters compose
- **What it validates:** the Audit screen's filters.
- **Entry criteria:** events across every category, two actors, and a 10-day
  span.
- **Action:** query `{jira, voice}` + `actor: user` + a 3-day range.
- **Exit criteria:** the intersection, newest first; an empty result is an
  empty list, never null.

#### S10-CT-01 — Every `AuditLog` implementation obeys one contract
- **What it validates:** the port.
- **Entry criteria:** the shared suite run against `DriftAuditLog` (in-memory)
  and `FakeAuditLog`.
- **Action:** the same script — record, query, purge, count, verify.
- **Exit criteria:** identical observable behaviour, including ordering and the
  empty cases.

#### S10-IT-01 — The log survives a round-trip and the migration
- **What it validates:** the schema change.
- **Entry criteria:** in-memory Drift at the *previous* schema, carrying tasks,
  meetings and outbox rows.
- **Action:** migrate; write 100 events; read them back; verify the chain.
- **Exit criteria:** pre-existing data intact, events return in insertion order
  with UTC timestamps, chain verifies.

#### S10-IT-02 — A tampered row is located, not merely flagged
- **What it validates:** the hash chain's stated guarantee.
- **Entry criteria:** 20 events; row 7 altered directly in the database.
- **Action:** verify.
- **Exit criteria:** verification fails and names row 7 as the first break; rows
  1–6 still verify.

#### S10-GT-01 — The Audit screen
- **What it validates:** `docs/design-system.md` §4, BR-11.
- **Entry criteria:** the 4 states — loading, empty ("nothing recorded yet"),
  error, and content with mixed categories and one failed entry.
- **Action:** render dark/light, mobile/desktop, in all three locales.
- **Exit criteria:** stable goldens; a failed entry is visibly distinct from a
  successful one; no golden contains a task title or an utterance.

#### S10-E2E-01 — A spoken command leaves the right trail, and only it
- **What it validates:** the sprint end to end.
- **Entry criteria:** the app with fakes; "cria a atividade Ligar para Samara".
- **Action:** speak it, then open Settings → Audit.
- **Exit criteria:** exactly three entries — `voice/sessionStarted`,
  `engine/requestSucceeded`, `voice/commandExecuted` — plus `task/created`;
  the screen shows them; **no entry anywhere contains "Samara"**, asserted
  against the database, not the widget tree.

#### S10-E2E-02 — Export writes what the screen shows, and nothing more
- **What it validates:** the export path.
- **Entry criteria:** 30 entries; a filter narrowing them to 8.
- **Action:** export.
- **Exit criteria:** 8 NDJSON lines, one JSON object each, matching the visible
  rows in order; an `auditExported` event is recorded (with the count, not the
  path); the file contains no free text.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%; project ≥ 80%.
- [ ] All S10-* tests passing.
- [ ] `tool/check_audit.dart` in CI, and passing over the whole of
      `lib/application/`.
- [ ] BR-12 added to `docs/project-rules.md` §4 and DEC-033 recorded.
- [ ] The three ARB files at key parity (S00-UT-06).
- [ ] A manual pass, recorded in `docs/reports/sprint-10-report.md`: create a
      task by voice, link it to Jira, let the outbox fail once, wipe everything
      — then read the log and confirm it tells that story, and that nothing the
      Developer said or typed appears anywhere in it.
