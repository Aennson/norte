import 'dart:convert';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/failures/failure.dart';

/// Turns a template into a request, and a model's answer back into a
/// [MeetingSummary].
///
/// Lives apart from [ClaudeApiEngine] because it is the piece every `AiEngine`
/// shares: the Claude adapter uses it, `FakeAiEngine` uses it, and
/// `CopilotCliEngine` will use it in Sprint 07. One parser means the contract
/// suite (S03-CT-01) compares adapters rather than comparing two hand-written
/// readers of the same JSON.
///
/// **The shape asked for**
///
/// ```json
/// {
///   "sections": [{"title": "What went well", "body": "…"}],
///   "actionItems": [{"description": "…", "assignee": null, "dueDate": null}]
/// }
/// ```
class MeetingSummaryCodec {
  const MeetingSummaryCodec();

  /// The JSON Schema handed to the model as `output_config.format`.
  ///
  /// Structured outputs make a malformed answer rare rather than impossible —
  /// which is why the retry in `SummarizeMeeting` stays, and why [parse] below
  /// still refuses anything it cannot read.
  static Map<String, Object?> schemaFor(
    MeetingTemplate template,
  ) => <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'sections': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'title': <String, Object?>{
              'type': 'string',
              if (template.sections.isNotEmpty) 'enum': template.sectionTitles,
            },
            'body': <String, Object?>{'type': 'string'},
          },
          'required': <String>['title', 'body'],
          'additionalProperties': false,
        },
      },
      'actionItems': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'description': <String, Object?>{'type': 'string'},
            'assignee': <String, Object?>{
              'type': <String>['string', 'null'],
            },
            'dueDate': <String, Object?>{
              'type': <String>['string', 'null'],
              'description': 'ISO 8601 date, or null when none was named.',
            },
          },
          'required': <String>['description', 'assignee', 'dueDate'],
          'additionalProperties': false,
        },
      },
    },
    'required': <String>['sections', 'actionItems'],
    'additionalProperties': false,
  };

  /// The system message: the template's own prompt plus the output contract.
  ///
  /// **This is the cached prefix**, so nothing in it may vary per meeting — no
  /// transcript, no timestamp, no meeting id. A single changed byte here costs
  /// the whole cache (`docs/architecture.md` §7.2).
  String systemPromptFor(MeetingTemplate template) {
    final StringBuffer buffer = StringBuffer(template.systemPrompt)
      ..writeln()
      ..writeln()
      ..writeln('Produce exactly these sections, in this order:');
    for (final TemplateSection section in template.sections) {
      buffer.write('- ${section.title}');
      final String? guidance = section.guidance;
      buffer.writeln(guidance == null ? '' : ' — $guidance');
    }
    buffer
      ..writeln()
      ..writeln(
        'A section the meeting did not cover gets an empty body. Never drop a '
        'section, never invent one, and never invent content the transcript '
        'does not support.',
      )
      ..writeln()
      ..writeln(
        template.extractActionItems
            ? 'Also extract every follow-up the meeting committed to, with the '
                  'owner and due date when they were stated and null when they '
                  'were not. Return an empty list if there were none.'
            : 'Return an empty actionItems list — this template does not '
                  'extract follow-ups.',
      )
      ..writeln()
      ..writeln(
        'The transcript may contain [CPF], [PHONE] or [EMAIL] where personal '
        'data was removed before it reached you. Leave those markers as they '
        'are; do not guess at what they replaced.',
      );
    return buffer.toString();
  }

  /// The output contract in words, for a transport that cannot attach
  /// [schemaFor].
  ///
  /// **The Sprint 07 manual pass is what proved this necessary.** The API
  /// engine sends the schema as `output_config.format` and the model has no
  /// choice about the shape; a CLI has one prompt and no such affordance, and
  /// [systemPromptFor] — written for a transport that carried the schema
  /// alongside it — never says the word JSON. Asked to summarize a retro, the
  /// real Copilot CLI answered in Markdown headings: a perfectly good answer to
  /// the prompt it was actually given, and unreadable to [parse].
  ///
  /// Every fixture in the suite is JSON, so every fake agreed with the parser
  /// and nothing failed until a real model was asked. That is `sprint-05` §5's
  /// lesson arriving a third time: a fake written from the caller's
  /// expectations agrees with the caller about everything, including what both
  /// got wrong.
  ///
  /// Kept beside [schemaFor] deliberately. Two descriptions of one shape will
  /// drift; two descriptions in the same class at least drift in front of
  /// whoever is editing them.
  String outputContractFor(MeetingTemplate template) {
    final String titles = template.sectionTitles
        .map((String title) => '"$title"')
        .join(', ');
    return 'Answer with JSON only — no prose, no Markdown, no code fence.\n'
        'The whole answer is one object:\n'
        '{"sections": [{"title": "…", "body": "…"}], '
        '"actionItems": [{"description": "…", "assignee": null, '
        '"dueDate": null}]}\n'
        'Use exactly these section titles, in this order: $titles.\n'
        '"assignee" and "dueDate" are null when the meeting did not name them; '
        '"dueDate" is an ISO 8601 date when it did.';
  }

  /// Reads [raw] into a [MeetingSummary] shaped by [template].
  ///
  /// Throws [AiResponseFailure] rather than returning half a summary. The
  /// sprint is explicit that a silent partial summary is the one outcome not
  /// allowed: a retro that quietly lost "What to improve" looks exactly like a
  /// retro where nothing needed improving.
  MeetingSummary parse(
    String raw,
    MeetingTemplate template, {
    required DateTime generatedAt,
    String? engineId,
  }) {
    final Object? decoded = _decode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const AiResponseFailure(
        'the engine did not answer with a summary object',
      );
    }

    final Map<String, String> bodies = _bodiesFrom(decoded['sections']);
    final List<String> titles = template.sectionTitles;

    // A response that matched none of the template's headings is a response to
    // some other question. Returning it with every section empty would be the
    // silent partial summary the sprint forbids.
    if (titles.isNotEmpty &&
        !titles.any((String title) => bodies.containsKey(_key(title)))) {
      throw const AiResponseFailure(
        'the summary did not contain any of the template\'s sections',
      );
    }

    return MeetingSummary(
      sections: <String, String>{
        for (final String title in titles) title: bodies[_key(title)] ?? '',
      },
      actionItems: template.extractActionItems
          ? _itemsFrom(decoded['actionItems'])
          : const <ActionItem>[],
      generatedAt: generatedAt,
      engineId: engineId,
    );
  }

  /// Section title → body, keyed case-insensitively so a model that
  /// title-cases a heading still lands in the right place.
  Map<String, String> _bodiesFrom(Object? sections) {
    if (sections is! List<Object?>) {
      throw const AiResponseFailure('the summary had no sections');
    }
    final Map<String, String> bodies = <String, String>{};
    for (final Object? entry in sections) {
      if (entry is! Map<String, Object?>) continue;
      final Object? title = entry['title'];
      if (title is! String || title.trim().isEmpty) continue;
      bodies[_key(title)] = switch (entry['body']) {
        final String body => body.trim(),
        _ => '',
      };
    }
    return bodies;
  }

  List<ActionItem> _itemsFrom(Object? items) {
    if (items is! List<Object?>) return const <ActionItem>[];
    final List<ActionItem> parsed = <ActionItem>[];
    for (final Object? entry in items) {
      if (entry is! Map<String, Object?>) continue;
      final Object? description = entry['description'];
      if (description is! String || description.trim().isEmpty) continue;
      parsed.add(
        ActionItem(
          // Positional and deterministic: the same response always yields the
          // same ids, which is what lets a golden test and an E2E assert on
          // one (`docs/testing-strategy.md` §3).
          id: 'item-${parsed.length}',
          description: description.trim(),
          assignee: switch (entry['assignee']) {
            final String assignee when assignee.trim().isNotEmpty =>
              assignee.trim(),
            _ => null,
          },
          dueDate: switch (entry['dueDate']) {
            final String date => DateTime.tryParse(date)?.toUtc(),
            _ => null,
          },
        ),
      );
    }
    return List<ActionItem>.unmodifiable(parsed);
  }

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

  String _key(String title) => title.trim().toLowerCase();
}
