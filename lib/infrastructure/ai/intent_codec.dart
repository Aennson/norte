import 'dart:convert';

import '../../domain/entities/intent_context.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/failures/failure.dart';

/// Turns an utterance into a request, and a model's answer back into a
/// [VoiceIntent] (`docs/architecture.md` §6.2).
///
/// The counterpart of `MeetingSummaryCodec`, and apart from the adapters for
/// the same reason: it is the piece every `AiEngine` shares. `ClaudeApiEngine`
/// uses it, `FakeAiEngine` uses it, and `CopilotCliEngine` will use it in
/// Sprint 07 — so S05-CT-02 compares adapters rather than comparing two
/// hand-written readers of the same JSON.
///
/// **The shape asked for**
///
/// ```json
/// {
///   "intent": "updateJira",
///   "slots": {"issueKey": "PROJ-123", "transition": "Done"},
///   "confidence": 0.92
/// }
/// ```
///
/// **What it refuses.** Anything it cannot read comes back as
/// [AiResponseFailure], and `IntentParser` turns that into
/// `IntentType.unknown`. The two-step matters: the codec's job is to say
/// honestly that it could not read the answer, and the parser's job is to
/// decide that an unreadable answer is not an action. An adapter that quietly
/// returned `unknown` itself would make a network failure and a shrugging
/// model indistinguishable.
class IntentCodec {
  const IntentCodec();

  /// The JSON Schema handed to the model as `output_config.format`.
  ///
  /// Constant, which is what makes it part of the cached prefix.
  ///
  /// **`confidence` carries no `minimum` or `maximum`.** Structured output
  /// rejects them outright:
  ///
  /// ```
  /// output_config.format.schema:
  /// For 'number' type, properties maximum, minimum are not supported
  /// ```
  ///
  /// Every parse request came back HTTP 400 because of those two words, so the
  /// pipeline reached a real transcript and then failed, every time. The range
  /// is enforced in [_confidenceFrom] instead, which clamps — and which had to
  /// exist anyway, because a schema is a request and not a guarantee.
  ///
  /// **Every slot is declared, required and nullable.** This one is *not*
  /// known to have been necessary: it was changed on a hypothesis about the
  /// 400 that the API's message then contradicted, and the API reports one
  /// error at a time, so whether an open `{"type": "object"}` would also have
  /// been refused is untested. It is kept because it is stricter and valid —
  /// but the honest label is "unverified", not "required".
  ///
  /// The worry that argued for the open object — that a union invites the
  /// model to fill in slots belonging to some other intent — is handled where
  /// it always was: [_slotsFrom] drops nulls and blanks, and
  /// `IntentType.requiredSlots` decides what an intent actually needs.
  static const Map<String, Object?> schema = <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'intent': <String, Object?>{'type': 'string', 'enum': _intents},
      'slots': <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'taskRef': _nullableString,
          'title': _nullableString,
          'description': _nullableString,
          'status': _nullableString,
          'priority': _nullableString,
          'dueDate': _nullableString,
          'comment': _nullableString,
          'issueKey': _nullableString,
          'transition': _nullableString,
          'text': _nullableString,
          'triggerAt': _nullableString,
        },
        // Strict structured output requires every declared property to be
        // required; nullability is what lets an intent leave the ones that are
        // not its own empty.
        'required': _slots,
        'additionalProperties': false,
      },
      'confidence': <String, Object?>{'type': 'number'},
    },
    'required': <String>['intent', 'slots', 'confidence'],
    'additionalProperties': false,
  };

  static const Map<String, Object?> _nullableString = <String, Object?>{
    'type': <String>['string', 'null'],
  };

  /// The wire names of every intent, in the order §6.3 introduces them.
  ///
  /// Written out rather than derived from `IntentType.values`: the schema is
  /// the cached prefix, and deriving it would make a stray enum value
  /// reordering the cache key of every request in flight.
  static const List<String> _intents = <String>[
    'createTask',
    'updateTask',
    'deleteTask',
    'commentTask',
    'updateJira',
    'addComment',
    'queryStatus',
    'createReminder',
    'unknown',
  ];

  /// Every slot any intent can carry, in the same order as `properties` above
  /// — the two lists are written out separately because a `const` map cannot
  /// be built from a `for` element, and they must not drift apart.
  ///
  /// **Eleven required nullable slots is a measured cost, not an oversight.**
  /// An intent that fills two of them still emits the other nine as `null`,
  /// which is most of an 85-token answer generated one token at a time. It is
  /// kept because strict structured output requires every declared property to
  /// be required, and the alternative — an open `{"type": "object"}` — is
  /// untested against this API (`sprint-05` report §7.3).
  static const List<String> _slots = <String>[
    'taskRef',
    'title',
    'description',
    'status',
    'priority',
    'dueDate',
    'comment',
    'issueKey',
    'transition',
    'text',
    'triggerAt',
  ];

  /// The system message.
  ///
  /// **This is the cached prefix** (`docs/architecture.md` §7.2), so it takes
  /// no argument and holds nothing that varies per call — no utterance, no
  /// issue keys, no locale. Everything situational rides in the user message
  /// built by [userMessageFor], where changing it costs nothing.
  String get systemPrompt => '''
You convert a spoken utterance from a developer into a single structured
intent. Answer with JSON only — no prose, no code fence.

The user's own task list (local — none of these touches Jira):
- createTask    {"title": "…", "description": "…" (optional),
                 "status": one of the status values below (optional),
                 "priority": one of the priority values below (optional),
                 "dueDate": ISO 8601 date (optional)}
- updateTask    {"taskRef": "…", plus at least one of "status", "priority",
                 "title", "description", "dueDate"}
- deleteTask    {"taskRef": "…"}
- commentTask   {"taskRef": "…", "comment": "…"}

Jira — only when an issue key or the word Jira is spoken:
- updateJira    {"issueKey": "PROJ-123", "transition": "Done"}
- addComment    {"issueKey": "PROJ-123", "comment": "…"}
- queryStatus   {"issueKey": "PROJ-123"}

Reminders:
- createReminder {"text": "…", "triggerAt": "+20m" | "+1h" | "today 15:00" |
                 "tomorrow 09:00" | "friday 15:00"}

- unknown       {}

Slot vocabularies — return the value below, never a translation of it:
- "status":   "todo" | "inProgress" | "done" | "blocked"
- "priority": "low" | "medium" | "high" | "urgent"
"a fazer", "pendente" and "to do" are all `todo`; "em progresso", "fazendo"
and "in progress" are all `inProgress`; "crítica", "critical" and "urgente"
are all `urgent`. Omit the slot entirely when the utterance did not say.

Rules:
- **A "task" is this app's own, never a Jira issue.** "cria tarefa…",
  "nova atividade…", "anota uma tarefa…" are `createTask` and nothing else.
- **Jira must be asked for explicitly.** Choose `updateJira`, `addComment` or
  `queryStatus` only when the utterance names an issue key (`PROJ-123`) or
  says Jira outright. Without one of those, an utterance about work is about a
  local task: "marca a tarefa X como concluída" is `updateTask`, "apaga a
  tarefa X" is `deleteTask`, "comenta na tarefa X: …" is `commentTask`. When
  in doubt, prefer the local intent: a wrong local task is a row the user
  deletes, a wrong Jira write is a change their team saw.
- `taskRef` is **the part of the task's title the user said**, and nothing
  else. Strip the verb and the article — "apaga a tarefa Ligar para Samara"
  gives `"taskRef": "Ligar para Samara"`. Never invent a fuller title than was
  spoken: the app matches it against the list and asks when several fit, so a
  short reference is safe and an embellished one is wrong.
- A comment on a *task* is `commentTask` and stays on the user's own row. Only
  an issue key or the word Jira makes it `addComment`, which their whole team
  will read.
- Issue keys are uppercase, `LETTERS-NUMBER`, exactly as the project writes
  them. Correct an obvious mishearing against the keys given as context, but
  never invent a key that was not spoken.
- `transition` is the English Jira status name — "Done", "In Progress",
  "To Do", "In Review", "Blocked" — whatever language the speaker used.
- A question about an issue is `queryStatus`, never `updateJira`. "Is PROJ-5
  done?" asks; it does not instruct.
- Use `unknown` whenever the utterance names no action, is small talk, or
  refers to something only the speaker could resolve ("do that thing we
  agreed on"). `unknown` carries no slots. Guessing is worse than refusing:
  the user can repeat themselves, but they cannot un-transition a ticket
  their team already saw.
- `confidence` is your own, in 0.0–1.0. Be honest and low when the utterance
  was ambiguous — below 0.75 the user is asked to confirm before anything
  happens, which is the safety this number exists to trigger.
- The utterance may be in Brazilian Portuguese, English, or Italian. Slot
  values keep the speaker's language, except `transition`.
''';

  /// The user message: the utterance plus the situation it was spoken in.
  ///
  /// Sits after the cache breakpoint, so none of it invalidates the prefix.
  String userMessageFor(String utterance, IntentContext context) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('locale: ${context.locale}');
    if (context.knownIssueKeys.isNotEmpty) {
      buffer.writeln('linked issues: ${context.knownIssueKeys.join(', ')}');
    }
    final IntentType? pending = context.pendingIntent;
    if (pending != null) {
      buffer
        ..writeln()
        ..writeln(
          'This answers a question the app asked to finish an earlier '
          'command. The intent is already known to be `${pending.name}` and '
          'these slots are already established: '
          '${jsonEncode(context.providedSlots)}. Read the utterance below as '
          'the missing slot only, keep the established ones, and return the '
          'completed intent — do not reinterpret it as a new command.',
        );
    }
    buffer
      ..writeln()
      ..writeln('utterance: $utterance');
    return buffer.toString();
  }

  /// Reads [raw] into a [VoiceIntent].
  ///
  /// Throws [AiResponseFailure] when the answer is not JSON, carries no
  /// `intent`, or names one outside the enum.
  ///
  /// [context] contributes the slots already established in a missing-slot
  /// exchange: the model is asked to echo them back, and a model that forgets
  /// half of them must not undo the user's earlier answer.
  VoiceIntent parse(String raw, {IntentContext? context}) {
    final Object? decoded = _decode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const AiResponseFailure(
        'the engine did not answer with an intent object',
      );
    }

    final Object? wire = decoded['intent'];
    if (wire is! String || wire.trim().isEmpty) {
      throw const AiResponseFailure('the answer named no intent');
    }

    final IntentType type = IntentType.fromWire(wire.trim());
    if (type == IntentType.unknown && wire.trim() != IntentType.unknown.name) {
      throw AiResponseFailure('the answer named no intent this app knows');
    }

    // `unknown` never carries slots, whatever the model attached to it. The
    // whole guarantee is that an unrecognised utterance cannot become an
    // action, and slots are what an action is made of.
    if (type == IntentType.unknown) {
      return const VoiceIntent(type: IntentType.unknown);
    }

    return VoiceIntent(
      type: type,
      slots: <String, dynamic>{
        ...?context?.providedSlots,
        ..._slotsFrom(decoded['slots']),
      },
      confidence: _confidenceFrom(decoded['confidence']),
    );
  }

  /// Scalar slots only, trimmed, with the blank ones dropped.
  ///
  /// A slot the model left empty is a slot it did not fill: keeping `""` would
  /// make [VoiceIntent.missingSlots] believe the question was answered and
  /// send an empty issue key to Jira.
  Map<String, dynamic> _slotsFrom(Object? slots) {
    if (slots is! Map<String, Object?>) return const <String, dynamic>{};
    final Map<String, dynamic> parsed = <String, dynamic>{};
    for (final MapEntry<String, Object?> entry in slots.entries) {
      switch (entry.value) {
        case final String value when value.trim().isNotEmpty:
          parsed[entry.key] = value.trim();
        case final num value:
          parsed[entry.key] = value;
        case final bool value:
          parsed[entry.key] = value;
        default:
        // Null, empty text, a nested object: not a slot value this app acts
        // on.
      }
    }
    return parsed;
  }

  /// Confidence in `0.0..1.0`.
  ///
  /// An absent or unreadable one is **0.0**, not a default that lets the
  /// action through. Under BR-04 that means the user is asked to confirm — the
  /// safe reading of "the model did not say how sure it was".
  double _confidenceFrom(Object? value) => switch (value) {
    final num number => number.toDouble().clamp(0.0, 1.0),
    final String text => (double.tryParse(text) ?? 0.0).clamp(0.0, 1.0),
    _ => 0.0,
  };

  /// [raw] as JSON, tolerating the two things a model does to it: wrapping it
  /// in a ```json fence, and writing a sentence before it.
  Object? _decode(String raw) {
    final String text = _unfence(raw.trim());
    try {
      return jsonDecode(text);
    } on FormatException {
      // Fall through to the brace scan below.
    }

    final int start = text.indexOf('{');
    final int end = text.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    try {
      return jsonDecode(text.substring(start, end + 1));
    } on FormatException {
      return null;
    }
  }

  String _unfence(String text) {
    if (!text.startsWith('```')) return text;
    final int firstBreak = text.indexOf('\n');
    final int lastFence = text.lastIndexOf('```');
    if (firstBreak == -1 || lastFence <= firstBreak) return text;
    return text.substring(firstBreak + 1, lastFence).trim();
  }
}
