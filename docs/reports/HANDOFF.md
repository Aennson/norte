# Handoff — where Sprint 05 stopped and Sprint 05a begins

Written 2026-08-09 at the end of a long session, for whoever picks this up
next. Read `docs/project-rules.md` first as always; this only says what is
**true right now** and what the next hour should do.

---

## 1. State

| | |
|---|---|
| Branch | `sprint-05/realtime-voice`, worktree `.claude/worktrees/sprint-05-realtime-voice` |
| Head | `6a3256f` — pushed, working tree clean |
| CI | **green** on `6a3256f` (analyze/format/imports/secrets · tests+coverage+goldens · E2E Linux) |
| PR | [#7](https://github.com/Aennson/norte/pull/7), **open, not merged** |
| Tests | 644 passing · coverage 93.2% domain+application, 84.1% project |

### PR #7 merged early — and **`master` is red**

PR #7 was merged at `57a3cc9`, **three commits before the branch tip**. What
looked for twenty minutes like GitHub lagging was GitHub telling the truth: a
closed PR freezes its head, and I read the frozen value as a stale one.

`master` therefore carries the continuous-listening change (DEC-031) **without**
the goldens and the E2E assertion that change required. Six overlay goldens and
S05-E2E-01 fail on it right now.

**[PR #8](https://github.com/Aennson/norte/pull/8) carries the tail and fixes
it.** Merge that first, before anything else.

| Commit | |
|---|---|
| `76f3316` | The truthful report — the manual pass, six defects, p95 3973 ms |
| `6a3256f` | **The red-build fix** — regenerated goldens, E2E updated for DEC-031 |
| `e116311` | This document |

---

## 2. Sprint 05 — closed, with one number that misses its target

The voice pipeline works end to end. During the manual pass a spoken command
created a task.

**p95 = 3973 ms against a target of < 3 s** (`architecture.md` §15). The DoD box
is ticked for the *measurement* it asks for; §8 of the report carries the number
as open and missed. Do not quietly re-baseline it.

Full record: `docs/reports/sprint-05-report.md` — §7.1 lists the six defects the
manual pass found, §7.2 the latency, §7.3 how the wire format was settled.

---

## 3. What Sprint 05a should do first — and it is not code

**Split the latency measurement.** ✅ **Done** — branch
`claude/scribe-claude-latency-split-a53827`. `VoiceLatencySample` now carries
three fields and `VoiceLatencyLog` a percentile for each:

| Stage | Whose | Measured from |
|---|---|---|
| `transcription` | **Scribe** | last partial → committed segment |
| `grounding` | ours | commit → parse request sent (the issue-key read) |
| `parse` | **Claude** | request → intent in hand |

Reading the code to instrument it corrected the premise above, and the
correction matters more than the instrument:

> **The 3973 ms never contained Scribe at all.** `_committedAt` was stamped
> when the *commit event arrived*, so the number that missed the target was
> already post-commit — grounding plus Claude, and grounding is a local
> database read. The two halves were not indistinguishable; one of them was
> simply absent. The real wait after the user's last word is 3973 ms **plus**
> Scribe's silence window, still unmeasured against the real service.

So the answer the split was meant to produce is mostly known before the first
manual run: **Claude dominates the number we already have**, and the candidate
lever — shortening the cached system prompt in `IntentCodec.systemPrompt` — is
the right one. `effort: 'low'` and the 512-token ceiling are already in place.
What the manual run now adds is Scribe's share, which is new information and
may be the larger number of the two.

**The anchor is a proxy, deliberately.** Nothing this side of the socket knows
when the user stopped speaking; the last partial is the closest observable, and
it trails the speech slightly, so `transcription` under-reports. That is the
safe direction for a number used to blame a service.

### The measurement — 2026-08-09, real Scribe, real Claude, 7 commands

| # | Scribe | local | Claude | total | result |
|---|---|---|---|---|---|
| 1 | 977 ms | 9 ms | 3891 ms | 4877 ms | createTask 0.82 |
| 2 | 134 ms | 0 ms | 4505 ms | 4639 ms | **unknown** |
| 3 | 136 ms | 1 ms | 5700 ms | 5837 ms | **unknown** |
| 4 | 290 ms | 1 ms | 3292 ms | 3583 ms | createTask 0.93 |
| 5 | 353 ms | 1 ms | 3312 ms | 3666 ms | createTask 0.92 |
| 6 | 926 ms | 1 ms | 3430 ms | 4357 ms | createTask 0.92 |
| 7 | 373 ms | 2 ms | 3661 ms | 4036 ms | createTask 0.82 |

**Claude is ~90% of every command** (median 91%). Scribe's median is 353 ms and
its worst is 977 ms; the local read never exceeded 9 ms.

**The decisive number is Claude's fastest call: 3292 ms.** Every one of the
seven missed the 3 s target on Claude's share *alone*. Scribe's entire
contribution, at its worst, is smaller than the gap between Claude's median and
the target — so no amount of work on transcription could have reached it, and
the split is what makes that provable rather than arguable.

Two of the seven are worth reading twice: the slowest calls, 4505 ms and
5700 ms, are the two that came back `unknown`. Two samples is not a finding,
but "the model spent the longest on the utterance it could not map" is the
shape you would expect if it were deliberating.

### What was done about it

**`thinking: {type: 'disabled'}` on the intent request** — the one line the
numbers pointed at. On this model thinking is **on by default**: omitting the
field is not "off", and the `effort: 'low'` already in place does not turn it
off either. Every one of those seven commands was paying for deliberation on a
six-way classification of one spoken sentence.

**Token and cache-read logging** — `[ai] usage: in N (cache read R, written W)
· out M` on every call. The system prompt is marked `cache_control` and is
byte-identical per command, but nothing ever checked that it *hits*, and a
cache that silently never hits looks exactly like one that always does.

**That check has to happen before anyone shortens the prompt.** The cacheable
floor on this model is 512 tokens and `IntentCodec.systemPrompt` is roughly
450–500 — near enough that shortening it could drop the prefix below the floor
and lose caching altogether, making every command slower. The handoff's
original candidate lever is the one that most needs a measurement first.

### Second measurement — thinking off, 5 commands

| # | Scribe | Claude | cache | out |
|---|---|---|---|---|
| 1 | 332 ms | **7406 ms** | written 1509, **read 0** | 85 |
| 2 | 915 ms | 2908 ms | read 1509 | 85 |
| 3 | 692 ms | 3160 ms | read 1509 | 84 |
| 4 | 909 ms | 2822 ms | read 1509 | 84 |
| 5 | 509 ms | 2676 ms | read 1509 | 87 |

**Thinking off is worth roughly 800 ms.** Claude's warm median went 3661 →
2865 ms, and its worst warm call (3160 ms) now beats its previous best
(3292 ms). Nothing regressed: every command parsed, confidences 0.72–0.92.

**The cold cache is now the single worst number in the log.** Writing 1509
tokens cost 7406 ms against ~2900 ms warm — and it landed on the first command
of the session, which is the one the user judges the feature by. That is what
`primeCache()` addresses: the warm-up fires when the microphone opens, so the
write happens during the dialling and the drawing of breath instead of during
a command.

**Two corrections to what §3 said above.** The prompt is **1509 tokens**, not
the 450–500 estimated — three times the 512-token cacheable floor, so there is
real room to shorten it without losing caching. But that also means shortening
it is *not* the lever it was hoped to be: those tokens are read from cache on
every command after the first, and cached reads are the cheap part. The
measurement moved this from "the largest remaining variable" to "measured, and
small".

### Third measurement — the warm-up did not take, and the number that justified it did not reproduce

| # | Scribe | Claude | cache |
|---|---|---|---|
| 1 | 697 ms | 3002 ms | written 1509, **read 0** |
| 2 | 434 ms | 2800 ms | read 1509 |

Two things went wrong, and the second is the more important one.

**The warm-up did not take.** The first command still *wrote* the cache, so
either `primeCache()` never completed, or it wrote an entry the parse request
could not match. It reported neither, because the first version swallowed the
outcome along with the error — a diagnostic that cannot say what it observed,
which is the §5.3 lesson of sprint 05 committed a second time by the person who
wrote it down. It now logs `prime: HTTP 200 — cache written N`, the API's own
message on a 4xx, and the failure type on anything else.

**The 7406 ms did not reproduce.** The cold command this time cost 3002 ms
against 2800 ms warm — a penalty of roughly 200 ms, not the 4500 ms measured
once before. So the case for the warm-up is currently *unproven*: `n = 2`, and
the two runs disagree by more than the effect. The 7406 ms was probably
connection setup or model-side variance, not the cache write. **Do not quote it
as the cost of a cold cache** until a third pass says so.

What the next pass answers, from one line:

| `prime:` says | Meaning | Next |
|---|---|---|
| `cache written 1509` | It warmed, and the parse still missed it | The two requests do not share a cache key — most likely because the warm-up omits `output_config.format` (`max_tokens: 0` forbids it) and that field is part of the system-cache key. A warm-up shaped like the real request — `max_tokens: 1`, format present — would be the thing to try |
| `cache written 0` | It ran, it warmed nothing | `max_tokens: 0` does not write on this model; same alternative as above |
| `HTTP 4xx …` | Refused | Read the message. It names the field |
| nothing at all | It never ran | The session is not calling it, or the future is being dropped |

If the cold penalty stays near 200 ms, the honest answer may be to **delete the
warm-up** rather than fix it: 200 ms once per session is not worth a port
method and a request the user pays for.

### What is left, and what it would take

Warm totals now run 3185–3853 ms against the 3 s target — the gap is roughly
850 ms at p95. Two levers remain, in order of how well they are understood:

1. **The eight required nullable slots** in `IntentCodec.schema`. Every answer
   is 84–87 output tokens, and an intent that fills one slot still emits the
   other seven as `null` — close to half the output, generated one token at a
   time. This is the biggest measured waste left. **It is not committed**,
   because the codec's own dartdoc labels that strictness *unverified*: it was
   adopted on a hypothesis about a 400 that the API's message then
   contradicted, and this project has already spent a round on a schema guess
   that made every parse fail. Try it behind one manual pass, and if the API
   refuses it, the refusal message names the reason — read it rather than
   guessing again.
2. **The model.** `ClaudeApiEngine.model` is a constructor argument. A six-way
   classification of one spoken sentence does not obviously need the largest
   model available, and the smaller ones are several times faster. The
   Developer's call: the key is theirs, and the eval thresholds (≥ 90% intent,
   ≥ 85% slots) would have to be re-run against the new model before it could
   ship.

**Scribe deserves a second look before either.** Its median moved 353 → 692 ms
and its p95 to 915 ms between the two passes — still not the bottleneck, but no
longer negligible, and the two runs disagree enough that neither is yet a
reliable number.

Then execute `docs/sprints/sprint-05a-task-commands.md` in order. Its entry
criteria require Sprint 05 merged.

---

## 4. Decisions that will surprise you if you have not read them

| DEC | What it changes |
|---|---|
| **026** | The Scribe wire format, as observed. Audio is **base64 in a JSON text frame**, `message_type` discriminates, a commit rides on an audio chunk. Settled from `zefa-ia`, the Developer's working implementation — read it before touching the protocol |
| **028** | Three BYOK credentials, three slots. `SecureTranscriptionCredentialStore` has **no default constructor** on purpose |
| **029** | The realtime key goes in the `xi-api-key` **header**, never the query string |
| **030** | Sprint 05a is lettered because 00–08 are specified and 09 opens v1.1 |
| **031** | **Continuous listening.** The microphone stays open until the user stops it; a failed command does not end the session |
| **032** | Hesitation filtered twice, asymmetrically. `zefa-ia` does **not** do this, contrary to the premise given |

---

## 5. The lesson this sprint actually taught

Six defects reached the Developer's hands. Not one was reachable by any test in
the suite, and five were invisible *because* the suite was green.

They shared a cause. **Every fake was written from what the code expected
rather than from what the world does**, so each was more forgiving than reality
on exactly the axis that mattered: `FakeRealtimeSocket` spoke an invented
dialect, so the contract suite held two implementations to a protocol neither
had seen — and they agreed. `main()` has no test at all, so two credential
defects lived there untouched. `realtime_socket.dart` had 0 of 14 lines
covered, so the API key was accepted as an argument and dropped.

Three habits came out of it, and they are worth keeping:

1. **A black-box probe can refute but never confirm.** An accepted message
   proves its shape works; a refused one proves nothing about *why*. Where a
   working implementation exists, read it first.
2. **A diagnostic must not be able to break what it observes.** The audio meter
   threw on an unaligned frame and killed the session it was there to
   illuminate.
3. **When a component knows why something failed, make it say so.** Four
   separate times this sprint — the microphone, the socket, the router, the
   Claude API — the reason was caught and discarded, and each time the next
   round of debugging was a guess. The logs added along the way (`[mic]`,
   `[voice]`, `[ai]`) are what turned the last two rounds from an afternoon
   into minutes.

---

## 6. Open, and deliberately not closed

- **p95 above target, but closing** — §3 above. Thinking off took Claude's warm
  median from 3661 to 2865 ms; warm totals now run 3185–3853 ms against a 3 s
  target. The cold-cache first command (7406 ms) is addressed by `primeCache()`
  and **that fix is unverified** — it needs one manual pass showing
  `cache read 1509` on the *first* command instead of `written 1509`. No
  automated test can confirm it: the evals run against `FakeAiEngine`.
- **iOS never built or tested**, no `macos/` golden set (DEC-020). Sprint 08
  has to decide a two- or three-platform v1.0.
- **The name of a transcript frame** is matched by substring rather than
  known exactly; the `[voice] unrecognised frame` log names it the first time
  it does not match.
- **`voiceLocaleProvider` is never overridden** — it is always `pt-BR`, which
  only matters for a user running the app in another language.
