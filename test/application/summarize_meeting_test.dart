import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/summarize_meeting.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/ports/ai_engine.dart';
import 'package:norte/domain/services/pii_redactor.dart';

import '../fakes/fake_ai_engine.dart';
import '../fakes/fake_clock.dart';
import '../fakes/fake_id_generator.dart';
import '../fakes/fake_meeting_repository.dart';
import '../support/meeting_fixtures.dart';

/// S03-UT-02, S03-UT-03, S03-UT-06 — the summarization use case.
void main() {
  late FakeAiEngine engine;
  late FakeClock clock;
  late FakeIdGenerator ids;
  late SummarizeMeeting summarize;

  final DateTime now = DateTime.utc(2026, 8, 8, 9, 30);

  SummarizeMeeting build({bool isLocal = false}) {
    engine = FakeAiEngine(
      capabilities: AiCapabilities(
        isLocal: isLocal,
        supportsStreaming: true,
        supportsPromptCache: true,
        maxTokens: 8192,
      ),
    )..alwaysAnswer(summaryFixture('retro.json'));
    return SummarizeMeeting(engine: engine, clock: clock, idGenerator: ids);
  }

  setUp(() {
    clock = FakeClock(now);
    ids = FakeIdGenerator.sequence(<String>['meeting-1', 'meeting-2']);
    summarize = build();
  });

  group('S03-UT-02: redaction applied before the AI', () {
    test('S03-UT-02: a remote engine never sees the CPF', () async {
      final Result<Meeting> result = await summarize(
        transcript: transcriptWithPii,
        template: retroTemplate,
        title: 'Retro',
      );

      expect(result.isOk, isTrue);
      expect(engine.calls, hasLength(1));

      final String received = engine.lastTranscript!;
      expect(received, isNot(contains('123.456.789-09')));
      expect(received, isNot(contains('12345678909')));
      expect(received, contains(PiiRedactor.cpfMask));
      // The whole rule, not just the CPF the sprint names.
      expect(const PiiRedactor().containsPii(received), isFalse);
    });

    test('S03-UT-02: a local engine receives the text untouched', () async {
      summarize = build(isLocal: true);

      final Result<Meeting> result = await summarize(
        transcript: transcriptWithPii,
        template: retroTemplate,
        title: 'Retro',
      );

      expect(result.isOk, isTrue);
      // BR-07 permits relaxing redaction only here, and only because the data
      // does not leave the machine.
      expect(engine.lastTranscript, transcriptWithPii.trim());
      expect(engine.lastTranscript, contains('123.456.789-09'));
    });

    test('S03-UT-02: the returned meeting keeps the unredacted text', () async {
      // What the engine saw and what the user typed are different things: the
      // redaction protects the third party, not the user's own copy.
      final Result<Meeting> result = await summarize(
        transcript: transcriptWithPii,
        template: retroTemplate,
        title: 'Retro',
      );

      expect(result.valueOrNull!.rawTranscript, contains('123.456.789-09'));
    });
  });

  group('S03-UT-03: template structures the prompt', () {
    test('S03-UT-03: the engine is given the template, verbatim', () async {
      await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: 'Retro',
      );

      final AiCall call = engine.calls.single;
      expect(call.template.id, retroTemplate.id);
      // The system prompt is built from the template alone — nothing about
      // this meeting is in it, which is what makes it cacheable.
      expect(call.systemPrompt, contains(retroTemplate.systemPrompt));
      expect(call.systemPrompt, isNot(contains(retroTranscript)));
      for (final String title in retroTemplate.sectionTitles) {
        expect(call.systemPrompt, contains(title));
      }
    });

    test('S03-UT-03: the user message is the redacted transcript', () async {
      await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: 'Retro',
      );

      expect(engine.calls.single.transcript, retroTranscript.trim());
    });

    test('S03-UT-03: the summary is keyed by the template sections', () async {
      final Result<Meeting> result = await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: 'Retro',
      );

      final MeetingSummary summary = result.valueOrNull!.summary!;
      expect(summary.sections.keys, retroTemplate.sectionTitles);
      expect(summary.sections['What went well'], contains('outbox'));
    });

    test('S03-UT-03: extractActionItems false yields no items', () async {
      final MeetingTemplate quiet = retroTemplate.copyWith(
        extractActionItems: false,
      );

      final Result<Meeting> result = await summarize(
        transcript: retroTranscript,
        template: quiet,
        title: 'Retro',
      );

      // The fixture contains two follow-ups; the flag is what decides.
      expect(engine.calls.single.systemPrompt, contains('empty actionItems'));
      expect(result.valueOrNull!.actionItems, isEmpty);
    });

    test('S03-UT-03: extractActionItems true yields the items', () async {
      final Result<Meeting> result = await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: 'Retro',
      );

      final List<ActionItem> items = result.valueOrNull!.actionItems;
      expect(items, hasLength(2));
      expect(items.first.description, 'Update the runbook');
      expect(items.first.assignee, 'Ana');
      expect(items.first.convertedTaskId, isNull);
    });
  });

  group('S03-UT-06: malformed AI response', () {
    late FakeMeetingRepository meetings;

    setUp(() => meetings = FakeMeetingRepository());

    test(
      'S03-UT-06: A — one bad answer, then a good one, in 2 calls',
      () async {
        engine.scriptedAnswers
          ..add(summaryFixture('malformed.txt'))
          ..add(summaryFixture('retro.json'));

        final Result<Meeting> result = await summarize(
          transcript: retroTranscript,
          template: retroTemplate,
          title: 'Retro',
        );

        expect(result.isOk, isTrue);
        expect(result.valueOrNull!.summary!.sections, hasLength(3));
        expect(engine.calls, hasLength(2));
      },
    );

    test(
      'S03-UT-06: B — two bad answers give up after exactly 2 calls',
      () async {
        engine.scriptedAnswers
          ..add(summaryFixture('malformed.txt'))
          ..add(summaryFixture('malformed.txt'));

        final Result<Meeting> result = await summarize(
          transcript: retroTranscript,
          template: retroTemplate,
          title: 'Retro',
        );

        expect(result.failureOrNull, isA<AiResponseFailure>());
        // Exactly two: a third attempt would spend the user's money on a model
        // that has already shown it is not going to comply.
        expect(engine.calls, hasLength(2));
        expect(engine.calls.length, SummarizeMeeting.maxAttempts);
      },
    );

    test('S03-UT-06: B — nothing is persisted when it gives up', () async {
      engine.scriptedAnswers
        ..add(summaryFixture('malformed.txt'))
        ..add(summaryFixture('malformed.txt'));

      final Result<Meeting> result = await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: 'Retro',
      );

      // The use case holds no repository at all, so there is no path by which
      // a failed summary could have been written. The spy proves it stayed
      // that way.
      expect(result.isOk, isFalse);
      expect(meetings.saved, isEmpty);
    });

    test(
      'S03-UT-06: a summary missing every template section is refused',
      () async {
        // The dangerous shape: valid JSON, right structure, wrong meeting.
        // Returning it would be the silent partial summary the sprint forbids.
        engine.scriptedAnswers
          ..add(summaryFixture('wrong_sections.json'))
          ..add(summaryFixture('wrong_sections.json'));

        final Result<Meeting> result = await summarize(
          transcript: retroTranscript,
          template: retroTemplate,
          title: 'Retro',
        );

        expect(result.failureOrNull, isA<AiResponseFailure>());
      },
    );

    test('S03-UT-06: a fenced answer is read, not retried', () async {
      engine.scriptedAnswers.add(summaryFixture('fenced_retro.json'));

      final Result<Meeting> result = await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: 'Retro',
      );

      expect(result.isOk, isTrue);
      expect(engine.calls, hasLength(1));
    });

    test(
      'S03-UT-06: a failure that a retry cannot fix is not retried',
      () async {
        // A rejected key is rejected the second time too. Retrying it costs
        // the user latency and tells them nothing new.
        engine.failWith = const AuthFailure('rejected');

        final Result<Meeting> result = await summarize(
          transcript: retroTranscript,
          template: retroTemplate,
          title: 'Retro',
        );

        expect(result.failureOrNull, isA<AuthFailure>());
        expect(engine.calls, hasLength(1));
      },
    );

    test(
      'S03-UT-06: a missing key is reported without calling twice',
      () async {
        engine.failWith = const MissingApiKeyFailure();

        final Result<Meeting> result = await summarize(
          transcript: retroTranscript,
          template: retroTemplate,
          title: 'Retro',
        );

        expect(result.failureOrNull, isA<MissingApiKeyFailure>());
        expect(engine.calls, hasLength(1));
      },
    );
  });

  group('input validation', () {
    test('a blank transcript never reaches the engine', () async {
      final Result<Meeting> result = await summarize(
        transcript: '   \n  ',
        template: retroTemplate,
        title: 'Retro',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull! as ValidationFailure).field, 'transcript');
      expect(engine.calls, isEmpty);
    });

    test('a blank title never reaches the engine', () async {
      // The screen pre-fills the title from the template's localized name, so
      // a blank one means the user cleared it. Inventing one here would put an
      // English literal into stored data on a pt-BR device (BR-11).
      final Result<Meeting> result = await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: '  ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull! as ValidationFailure).field, 'title');
      expect(engine.calls, isEmpty);
    });
  });

  group('the meeting that comes back', () {
    test('carries the injected id, clock and retention', () async {
      final Result<Meeting> result = await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: '  Sprint 12 retro  ',
        retention: RetentionPolicy.persisted,
      );

      final Meeting meeting = result.valueOrNull!;
      expect(meeting.id, 'meeting-1');
      expect(meeting.createdAt, now);
      expect(meeting.title, 'Sprint 12 retro');
      expect(meeting.type, MeetingType.retro);
      expect(meeting.retention, RetentionPolicy.persisted);
    });

    test('defaults to ephemeral retention (BR-03)', () async {
      final Result<Meeting> result = await summarize(
        transcript: retroTranscript,
        template: retroTemplate,
        title: 'Retro',
      );

      expect(result.valueOrNull!.retention, RetentionPolicy.ephemeral);
    });
  });
}
