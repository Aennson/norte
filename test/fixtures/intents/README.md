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

Current PT-BR headroom: 61/64 intents (95.3%) and 56/64 exact slot sets
(87.5%), against thresholds of 90% and 85%. Both are deliberately close enough
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

## The `triggerAt` convention

`createReminder` slots use the Sprint 06 fixture convention
(`docs/sprints/sprint-06-reminders.md` S06-UT-01): a relative offset (`+20m`,
`+1h`) or a resolved wall-clock phrase (`today 15:00`, `tomorrow 09:00`,
`friday 15:00`). Sprint 05 stores the reminder and does not schedule it, so
nothing here is resolved against a clock yet — that is Sprint 06's work.
