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

Next: one manual pass with the real engine, read the three p95s off the
console, *then* decide which half to attack.

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

- **p95 above target** — §3 above. Now instrumented per stage, but **not yet
  re-measured against the real Scribe and the real Claude**: every number in
  the sprint-05 report predates the split, and none of them includes Scribe.
- **iOS never built or tested**, no `macos/` golden set (DEC-020). Sprint 08
  has to decide a two- or three-platform v1.0.
- **The name of a transcript frame** is matched by substring rather than
  known exactly; the `[voice] unrecognised frame` log names it the first time
  it does not match.
- **`voiceLocaleProvider` is never overridden** — it is always `pt-BR`, which
  only matters for a user running the app in another language.
