import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/save_meeting.dart';
import 'package:norte/application/usecases/summarize_meeting.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fake_ai_engine.dart';
import '../fakes/fake_clock.dart';
import '../fakes/fake_id_generator.dart';
import '../fakes/fake_meeting_repository.dart';
import '../support/meeting_fixtures.dart';

/// S03-UT-04 — ephemeral retention (BR-03).
///
/// The rule reads "a transcript with `retention = ephemeral` lives only in
/// memory". These cases assert the half a database can be made to prove: what
/// arrives at the repository, under each choice, along the whole path from a
/// pasted transcript to a stored row.
void main() {
  late FakeMeetingRepository meetings;
  late FakeAiEngine engine;
  late SummarizeMeeting summarize;
  late SaveMeeting save;

  setUp(() {
    meetings = FakeMeetingRepository();
    engine = FakeAiEngine()..alwaysAnswer(summaryFixture('retro.json'));
    summarize = SummarizeMeeting(
      engine: engine,
      clock: FakeClock(DateTime.utc(2026, 8, 8, 9)),
      idGenerator: FakeIdGenerator.fixed('meeting-1'),
    );
    save = SaveMeeting(repository: meetings);
  });

  tearDown(() => meetings.dispose());

  /// Runs the real path: summarize, then save.
  Future<Result<Meeting>> summarizeAndSave(RetentionPolicy retention) async {
    final Result<Meeting> summarized = await summarize(
      transcript: retroTranscript,
      template: retroTemplate,
      title: 'Sprint 12 retro',
      retention: retention,
    );
    return save(summarized.valueOrNull!);
  }

  group('S03-UT-04: ephemeral retention', () {
    test(
      'S03-UT-04: an ephemeral transcript never reaches the repository',
      () async {
        await summarizeAndSave(RetentionPolicy.ephemeral);

        final Meeting stored = meetings.saved.single;
        expect(stored.rawTranscript, isEmpty);
        // Not a substring of it either — the assertion is about the text, not
        // about a field name.
        expect(stored.rawTranscript, isNot(contains('outbox')));
      },
    );

    test('S03-UT-04: the summary is what survives', () async {
      await summarizeAndSave(RetentionPolicy.ephemeral);

      final Meeting stored = meetings.saved.single;
      expect(stored.summary, isNotNull);
      expect(stored.summary!.sections, hasLength(3));
      expect(stored.summary!.sections['What went well'], contains('outbox'));
      expect(stored.actionItems, hasLength(2));
    });

    test('S03-UT-04: a persisted transcript is stored whole', () async {
      await summarizeAndSave(RetentionPolicy.persisted);

      final Meeting stored = meetings.saved.single;
      expect(stored.rawTranscript, retroTranscript.trim());
      expect(stored.retention, RetentionPolicy.persisted);
    });

    test(
      'S03-UT-04: the caller is handed the stored form, not its argument',
      () async {
        // So a screen cannot go on displaying a transcript the app has just
        // committed to forgetting.
        final Result<Meeting> result = await summarizeAndSave(
          RetentionPolicy.ephemeral,
        );

        expect(result.valueOrNull!.rawTranscript, isEmpty);
      },
    );

    test('S03-UT-04: forStorage is the single gate, and it is idempotent', () {
      final Meeting ephemeral = Meeting(
        id: 'm1',
        title: 'Retro',
        createdAt: DateTime.utc(2026),
        rawTranscript: 'secret',
      );

      expect(ephemeral.forStorage.rawTranscript, isEmpty);
      expect(ephemeral.forStorage.forStorage.rawTranscript, isEmpty);
      // Everything else is untouched.
      expect(ephemeral.forStorage.title, 'Retro');
      expect(ephemeral.forStorage.retention, RetentionPolicy.ephemeral);
    });
  });

  group('what may be saved at all', () {
    test('a meeting with no summary is refused', () async {
      final Result<Meeting> result = await save(
        Meeting(id: 'm1', title: 'Retro', createdAt: DateTime.utc(2026)),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(meetings.saved, isEmpty);
    });

    test('a storage failure is returned, not thrown', () async {
      meetings.failWith = const StorageFailure('disk full');

      final Result<Meeting> result = await summarizeAndSave(
        RetentionPolicy.ephemeral,
      );

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('deleting a meeting', () {
    test('removes it and leaves any tasks it produced alone', () async {
      await summarizeAndSave(RetentionPolicy.persisted);
      final DeleteMeeting delete = DeleteMeeting(repository: meetings);

      final Result<void> result = await delete('meeting-1');

      expect(result.isOk, isTrue);
      expect(meetings.deleted, <String>['meeting-1']);
      expect(await meetings.findById('meeting-1'), isNull);
    });

    test('deleting an unknown id succeeds', () async {
      final DeleteMeeting delete = DeleteMeeting(repository: meetings);

      expect((await delete('nope')).isOk, isTrue);
    });
  });
}
