# Intent datasets (S05-EV-01)

Three datasets feed the multilingual parsing eval: `ptbr_dataset.json` is the
product's target language and carries the full set, `en_dataset.json` and
`it_dataset.json` are smoke sets that prove the parser is not tuned to one
language (BR-11).

## Row shape

```json
{
  "id": "ptbr-001",
  "utterance": "muda o PROJ-123 pra concluído",
  "expected": { "intent": "updateJira", "slots": { "issueKey": "PROJ-123", "transition": "Done" } },
  "response": "{\"intent\":\"updateJira\",\"slots\":{…},\"confidence\":0.94}"
}
```

* **`expected`** is the ground truth — what a correct parse looks like. Rows
  labelled `unknown` carry empty slots and are the hard gate: 100% of them must
  come out `unknown`, because an ambiguous utterance that becomes an action is
  the one failure mode this eval exists to catch.
* **`response`** is the raw model answer the `FakeAiEngine` replays. It is fed
  through the **real** `IntentCodec`, so the eval measures the parsing pipeline,
  not the fake's memory.

## Why some responses are wrong on purpose

If every fixture answered perfectly the eval would report 100% forever and the
`≥ 90%` / `≥ 85%` thresholds in the sprint's exit criteria would never
distinguish a healthy parser from a broken one. The PT-BR set therefore carries
answers that a real model plausibly gets wrong — a question read as a command
(`ptbr-039`), a comment read as a task (`ptbr-018`), a truncated slot, an
untranslated transition name — plus answers in the shapes a model actually
emits: fenced JSON, JSON behind a sentence of prose, prose with no JSON at all,
JSON missing `intent`, and an `intent` outside the enum.

Current PT-BR headroom: 64/67 intents (95.5%) and 59/67 exact slot sets
(88.1%), against thresholds of 90% and 85%. Both are deliberately close enough
that a regression in the codec moves them below the line.

## Sprint 05a — the local task intents

Twelve PT-BR rows and three each in EN and IT cover `updateTask`, `deleteTask`,
`commentTask` and the rich `createTask` of §6.3. Two of the twelve are wrong on
purpose, and both are the local mirror of a mistake the Jira rows already
record:

* **`ptbr-056`** returns `"status": "bloqueada"` — the speaker's word instead of
  the enum name §6.3.2 asks for, exactly as `ptbr-004` does for an untranslated
  Jira transition. Intent right, slots wrong.
* **`ptbr-062`** reads a note on an existing task as a new task, as `ptbr-018`
  reads a Jira comment as one. The confusion is between *creating* and
  *annotating*, and it survives the move from Jira to the local list.

Adding perfect rows only would have raised the headroom and made the thresholds
easier to hit, which is the opposite of what they are for.

**None of these utterances names an issue key or says Jira**, which is what
S05a-UT-07 checks: it re-parses every row whose utterance carries neither and
fails if any of them produced `updateJira`, `addComment` or `queryStatus`.

## Sprint 05b — the optional `resolvesTo`

Three PT-BR rows (`ptbr-065..067`) carry a `taskRef` spelled the way a person
says it out loud rather than the way the title is written: `Hero Brazil-762`
for `HEROBRAZIL-762` (a space), `Hero Brasil-762` for the same (a Brazilian
speaker's spelling of an English word), and `ligar pra Samára` for `Ligar para
Samara`. Each carries an extra key:

```json
"resolvesTo": "HEROBRAZIL-762"
```

`resolvesTo` is the title the reference must reach through the ladder of
`docs/architecture.md` §6.3.1. S05b-EV-01 parses the row, routes it over a
list that includes the decoys the thresholds exist to keep apart —
`HEROBRAZIL-763` one digit away, and "Ligar para Samara de novo" — and fails
if the outcome named anything else. Rows without the key are references
spelled the way their title is, and the eval ignores them.

These three are correct on purpose, which raised the PT-BR headroom slightly
(95.3% → 95.5% intent, 87.5% → 88.1% slots). They measure resolution, not
parsing: the parse was never what failed on 2026-08-09.

## The `triggerAt` convention

`createReminder` slots use the Sprint 06 fixture convention
(`docs/sprints/sprint-06-reminders.md` S06-UT-01): a relative offset (`+20m`,
`+1h`) or a resolved wall-clock phrase (`today 15:00`, `tomorrow 09:00`,
`friday 15:00`). Sprint 05 stores the reminder and does not schedule it, so
nothing here is resolved against a clock yet — that is Sprint 06's work.
