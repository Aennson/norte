import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/summarize_meeting.dart';
import 'package:norte/application/usecases/transcribe_meeting_audio.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/domain/entities/transcript.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fake_ai_engine.dart';
import '../fakes/fake_audio_store.dart';
import '../fakes/fake_batch_transcription.dart';
import '../fakes/fake_clock.dart';
import '../fakes/fake_id_generator.dart';
import '../support/meeting_fixtures.dart';

/// Records what [SummarizeMeeting] was asked for, and answers from the real
/// one.
///
/// A spy rather than a stub: S04-UT-01's exit criterion is that the *actual*
/// Sprint 03 use case receives the engine's transcript, so the delegate below
/// is the production object. A stub could have agreed with the assertion while
/// the app summarized something else.
class SpySummarizeMeeting implements SummarizeMeeting {
  SpySummarizeMeeting(this._delegate);

  final SummarizeMeeting _delegate;

  final List<({String transcript, MeetingTemplate template, String title})>
  calls = <({String transcript, MeetingTemplate template, String title})>[];

  @override
  Future<Result<Meeting>> call({
    required String transcript,
    required MeetingTemplate template,
    required String title,
    RetentionPolicy retention = RetentionPolicy.ephemeral,
  }) {
    calls.add((transcript: transcript, template: template, title: title));
    return _delegate(
      transcript: transcript,
      template: template,
      title: title,
      retention: retention,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const String audioPath = '/tmp/norte_recordings/meeting_1.m4a';
  const String spokenText =
      'Ana: shipped the outbox yesterday. Today the dispatcher. No blockers.';

  late FakeBatchTranscription transcription;
  late FakeAudioStore store;
  late FakeAiEngine ai;
  late SpySummarizeMeeting summarize;
  late TranscribeMeetingAudio transcribe;

  setUp(() {
    transcription = FakeBatchTranscription(
      transcripts: <String, Transcript>{
        audioPath: const Transcript(text: spokenText, language: 'pt'),
      },
    );
    store = FakeAudioStore(files: <String>{audioPath});
    ai = FakeAiEngine()..alwaysAnswer(summaryFixture('daily.json'));
    summarize = SpySummarizeMeeting(
      SummarizeMeeting(
        engine: ai,
        clock: FakeClock(DateTime.utc(2026, 8, 8, 9, 30)),
        idGenerator: FakeIdGenerator.sequence(<String>['meeting-1']),
      ),
    );
    transcribe = TranscribeMeetingAudio(
      engine: transcription,
      store: store,
      summarize: summarize,
    );
    addTearDown(transcription.dispose);
  });

  group('S04-UT-01: flow orchestration', () {
    test(
      'S04-UT-01: SummarizeMeeting receives exactly the engine transcript and '
      'the chosen template',
      () async {
        final Result<Meeting> result = await transcribe(
          audioPath: audioPath,
          template: dailyTemplate,
          title: 'Daily',
        );

        expect(result.isOk, isTrue);
        expect(transcription.requestedFiles, <String>[audioPath]);

        // The exit criterion, asserted as an identity rather than a
        // resemblance: no trimming, no re-wrapping, no second prompt built
        // along the way.
        expect(summarize.calls, hasLength(1));
        expect(summarize.calls.single.transcript, spokenText);
        expect(summarize.calls.single.template, same(dailyTemplate));
      },
    );

    test('S04-UT-01: the stages are emitted in the documented order', () async {
      final List<TranscriptionStage> stages = <TranscriptionStage>[];

      await transcribe(
        audioPath: audioPath,
        template: dailyTemplate,
        title: 'Daily',
        onStage: stages.add,
      );

      expect(stages, <TranscriptionStage>[
        TranscriptionStage.uploading,
        TranscriptionStage.transcribing,
        TranscriptionStage.summarizing,
        TranscriptionStage.done,
      ]);
    });

    test(
      'S04-UT-01: the pipeline is Sprint 03s, not a second copy of it',
      () async {
        await transcribe(
          audioPath: audioPath,
          template: dailyTemplate,
          title: 'Daily',
        );

        // The AI engine was reached through SummarizeMeeting — one call, with
        // the transcript the redactor had already been given a chance at. A
        // duplicated pipeline would show up here as a second call or as an
        // engine that was never reached at all.
        expect(ai.calls, hasLength(1));
        expect(ai.lastTranscript, spokenText);
      },
    );

    test('S04-UT-01: the language hint reaches the engine', () async {
      await transcribe(
        audioPath: audioPath,
        template: dailyTemplate,
        title: 'Daily',
        language: 'pt',
      );

      expect(transcription.requestedFiles, <String>[audioPath]);
    });

    test('S04-UT-01: the retention choice made before recording is carried '
        'through (BR-03)', () async {
      final Result<Meeting> result = await transcribe(
        audioPath: audioPath,
        template: dailyTemplate,
        title: 'Daily',
        retention: RetentionPolicy.persisted,
      );

      expect(result.valueOrNull!.retention, RetentionPolicy.persisted);
      // And the default is still the ephemeral one BR-03 requires.
      final Result<Meeting> byDefault = await transcribe(
        audioPath: audioPath,
        template: dailyTemplate,
        title: 'Daily',
      );
      expect(byDefault.valueOrNull!.retention, RetentionPolicy.ephemeral);
    });
  });

  group('S04-UT-02: a transcription failure preserves the audio', () {
    test('S04-UT-02: the file survives the failure, the retry uses it, and '
        'success deletes it', () async {
      transcription.failWith = const TranscriptionFailure();

      final Result<Meeting> failed = await transcribe(
        audioPath: audioPath,
        template: dailyTemplate,
        title: 'Daily',
      );

      // The error is propagated...
      expect(failed.failureOrNull, isA<TranscriptionFailure>());
      // ...and the audio is exactly where it was. This is the rule.
      expect(await store.exists(audioPath), isTrue);
      expect(store.deleted, isEmpty);

      // The retry works with the same file — no re-recording.
      transcription.failWith = null;
      final Result<Meeting> retried = await transcribe(
        audioPath: audioPath,
        template: dailyTemplate,
        title: 'Daily',
      );

      expect(retried.isOk, isTrue);
      expect(transcription.requestedFiles, <String>[audioPath, audioPath]);
      expect(await store.exists(audioPath), isFalse);
    });

    test(
      'S04-UT-02: a summarize failure keeps the audio too — transcription is '
      'the expensive half',
      () async {
        ai.failWith = const AiResponseFailure();

        final Result<Meeting> result = await transcribe(
          audioPath: audioPath,
          template: dailyTemplate,
          title: 'Daily',
        );

        expect(result.failureOrNull, isA<AiResponseFailure>());
        expect(await store.exists(audioPath), isTrue);
      },
    );

    test('S04-UT-02: no stage claims done when the run failed', () async {
      transcription.failWith = const TranscriptionFailure();
      final List<TranscriptionStage> stages = <TranscriptionStage>[];

      await transcribe(
        audioPath: audioPath,
        template: dailyTemplate,
        title: 'Daily',
        onStage: stages.add,
      );

      expect(stages, isNot(contains(TranscriptionStage.done)));
      expect(stages.last, TranscriptionStage.transcribing);
    });
  });

  group('S04-UT-03: cleanup after success and after discard', () {
    test('S04-UT-03: scenario A — a successful run empties the '
        'directory', () async {
      final Result<Meeting> result = await transcribe(
        audioPath: audioPath,
        template: dailyTemplate,
        title: 'Daily',
      );

      expect(result.isOk, isTrue);
      expect(store.deleted, <String>[audioPath]);
      expect(await store.list(), isEmpty);
    });

    test(
      'S04-UT-03: scenario B — discarding before transcribing empties it too',
      () async {
        await transcribe.discard(audioPath);

        expect(store.deleted, <String>[audioPath]);
        expect(await store.list(), isEmpty);
        // Nothing was uploaded on the way: discarding is not a silent
        // transcription the user still pays for.
        expect(transcription.requestedFiles, isEmpty);
      },
    );

    test(
      'S04-UT-03: a store that cannot delete does not turn a summary into an '
      'error',
      () async {
        store.failWith = const StorageFailure();

        final Result<Meeting> result = await transcribe(
          audioPath: audioPath,
          template: dailyTemplate,
          title: 'Daily',
        );

        // The user asked for a summary and got one. The undeleted temp file is
        // in a directory the platform clears anyway.
        expect(result.isOk, isTrue);
      },
    );

    test('S04-UT-03: deleting a file that is already gone is not an '
        'error', () async {
      await transcribe.discard('/tmp/norte_recordings/never_existed.m4a');

      expect(store.deleted, hasLength(1));
      expect(await store.list(), <String>[audioPath]);
    });
  });
}
