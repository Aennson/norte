import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/clock.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/transcript.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/ports/notification_scheduler.dart';
import 'package:norte/domain/ports/transcription_engine.dart';

import '../support/meeting_fixtures.dart';
import 'fakes.dart';

/// Sanity suite for the six test doubles of `docs/testing-strategy.md` §3.
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4
/// ("the executing AI may add tests beyond those specified"). Every later
/// sprint builds on these fakes, so their contract is pinned here rather than
/// discovered when a real test starts failing for the wrong reason.
void main() {
  group('FakeClock', () {
    test('is deterministic and only moves when the test moves it', () {
      final FakeClock clock = FakeClock.fixed();
      final DateTime first = clock.now();

      expect(clock.now(), first, reason: 'time must not drift on its own');

      clock.advance(const Duration(hours: 2));
      expect(clock.now(), first.add(const Duration(hours: 2)));

      clock.setTo(DateTime.utc(2030));
      expect(clock.now(), DateTime.utc(2030));
      expect(clock.readings, hasLength(4));
    });

    test('SystemClock is the production implementation of the port', () {
      const Clock clock = SystemClock();
      expect(
        clock.now().difference(DateTime.now()).abs().inSeconds,
        lessThan(5),
      );
    });
  });

  group('FakeNotificationScheduler', () {
    late FakeNotificationScheduler scheduler;

    ScheduledNotification notification(String id, {int hour = 9}) =>
        ScheduledNotification(
          id: id,
          title: 'Reminder',
          body: 'Answer the e-mail',
          triggerAt: DateTime.utc(2026, 1, 1, hour),
        );

    setUp(() => scheduler = FakeNotificationScheduler());

    test(
      'records schedules and returns them ordered by trigger time',
      () async {
        await scheduler.schedule(notification('b', hour: 15));
        await scheduler.schedule(notification('a', hour: 9));

        expect(
          (await scheduler.pending()).map((ScheduledNotification n) => n.id),
          <String>['a', 'b'],
        );
      },
    );

    test(
      'scheduling the same id twice replaces instead of duplicating',
      () async {
        await scheduler.schedule(notification('a', hour: 9));
        await scheduler.schedule(notification('a', hour: 18));

        final List<ScheduledNotification> pending = await scheduler.pending();
        expect(pending, hasLength(1));
        expect(pending.single.triggerAt.hour, 18);
      },
    );

    test('fire delivers a pending notification exactly once', () async {
      await scheduler.schedule(notification('a'));

      expect(scheduler.fire('a')?.id, 'a');
      expect(scheduler.fired, <String>['a']);
      expect(scheduler.fire('a'), isNull, reason: 'already delivered');
      expect(await scheduler.pending(), isEmpty);
    });

    test('cancel is a no-op for an unknown id', () async {
      await scheduler.cancel('nope');
      expect(scheduler.cancelled, <String>['nope']);
      expect(await scheduler.pending(), isEmpty);
    });

    test('failWith simulates a denied notification permission', () async {
      scheduler.failWith = const AuthFailure('permission denied');

      await expectLater(
        scheduler.schedule(notification('a')),
        throwsA(isA<AuthFailure>()),
      );
      expect(await scheduler.pending(), isEmpty);

      scheduler.reset();
      await scheduler.schedule(notification('a'));
      expect(await scheduler.pending(), hasLength(1));
    });
  });

  // Promoted in Sprint 03: `FakeAiEngine` now implements the real `AiEngine`
  // and returns a parsed `MeetingSummary`. The cases below are the sprint-00
  // ones, unchanged in intent — fixtures in, calls recorded, unknown input
  // loud, failures and hangs injectable — restated against that port.
  group('FakeAiEngine', () {
    const String answer =
        '{"sections":[{"title":"What went well","body":"Shipped."}],'
        '"actionItems":[]}';

    test('answers from fixtures and records every call', () async {
      final FakeAiEngine engine = FakeAiEngine(
        summaries: <String, String>{'transcript': answer},
        intents: <String, String>{
          'cria tarefa':
              '{"intent":"createTask","slots":{"title":"revisar o PR"},'
              '"confidence":0.9}',
        },
      );

      final MeetingSummary summary = await engine.summarize(
        'transcript',
        retroTemplate,
      );
      expect(summary.sections['What went well'], 'Shipped.');
      // Read through the real `IntentCodec`, not handed back as text: the
      // fake cannot be more forgiving than production (S05-CT-02).
      final VoiceIntent intent = await engine.parseIntent(
        'cria tarefa',
        const IntentContext(),
      );
      expect(intent.type, IntentType.createTask);
      expect(intent.slots, <String, dynamic>{'title': 'revisar o PR'});
      expect(intent.confidence, 0.9);
      expect(engine.utterances, <String>['cria tarefa']);

      expect(engine.calls, hasLength(1));
      expect(engine.transcripts, <String>['transcript']);
      // The template travels with the call, which is what S03-UT-03 asserts
      // the prompt is built from.
      expect(engine.calls.single.template.id, retroTemplate.id);
    });

    test('an unknown input is a loud test bug, not a silent empty answer', () {
      final FakeAiEngine engine = FakeAiEngine();
      expect(
        () => engine.summarize('unseen', retroTemplate),
        throwsA(isA<StateError>()),
      );
    });

    test('failWith surfaces an engine failure', () async {
      final FakeAiEngine engine = FakeAiEngine(
        summaries: <String, String>{'t': answer},
      )..failWith = const EngineFailure();

      await expectLater(
        engine.summarize('t', retroTemplate),
        throwsA(isA<EngineFailure>()),
      );

      engine.reset();
      expect((await engine.summarize('t', retroTemplate)).sections, isNotEmpty);
    });

    test(
      'hang never completes, so timeout handling can be exercised',
      () async {
        final FakeAiEngine engine = FakeAiEngine(
          summaries: <String, String>{'t': answer},
        )..hang = true;

        await expectLater(
          engine
              .summarize('t', retroTemplate)
              .timeout(const Duration(milliseconds: 20)),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test('it parses with the production codec, not a lenient stand-in', () {
      // The property that makes S03-CT-01 a contract test rather than two
      // suites agreeing with themselves.
      final FakeAiEngine engine = FakeAiEngine()..alwaysAnswer('not json');

      expect(
        () => engine.summarize('t', retroTemplate),
        throwsA(isA<AiResponseFailure>()),
      );
    });

    test('capabilities.isLocal defaults to a remote engine', () {
      expect(FakeAiEngine().capabilities.isLocal, isFalse);
    });
  });

  group('FakeJiraGateway', () {
    test('loads the synthetic issues from the fixture file', () async {
      final FakeJiraGateway jira = FakeJiraGateway.fromFixture();

      expect(jira.issues.keys, contains('PROJ-123'));
      expect((await jira.getIssue('NORTE-1')).status, 'To Do');
      expect(jira.reads, <String>['NORTE-1']);
    });

    test(
      'a write replayed with the same operationId is applied once (BR-05)',
      () async {
        final FakeJiraGateway jira = FakeJiraGateway.fromFixture();

        await jira.transitionIssue(
          issueKey: 'NORTE-1',
          status: 'Done',
          operationId: 'op-1',
        );
        await jira.transitionIssue(
          issueKey: 'NORTE-1',
          status: 'Done',
          operationId: 'op-1',
        );

        expect(jira.writesFor('NORTE-1'), hasLength(1));
        expect((await jira.getIssue('NORTE-1')).status, 'Done');
      },
    );

    test('comments are recorded and idempotent too', () async {
      final FakeJiraGateway jira = FakeJiraGateway.fromFixture();

      await jira.addComment(
        issueKey: 'PROJ-123',
        body: 'deployed to staging',
        operationId: 'op-2',
      );
      await jira.addComment(
        issueKey: 'PROJ-123',
        body: 'deployed to staging',
        operationId: 'op-2',
      );

      expect(
        jira.writes.where((JiraWrite w) => w.kind == 'comment'),
        hasLength(1),
      );
    });

    test('an unknown issue is a NotFoundFailure', () async {
      final FakeJiraGateway jira = FakeJiraGateway.fromFixture();

      await expectLater(
        jira.getIssue('NOPE-1'),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        jira.transitionIssue(
          issueKey: 'NOPE-1',
          status: 'Done',
          operationId: 'op',
        ),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        jira.addComment(issueKey: 'NOPE-1', body: 'x', operationId: 'op'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('simulates 401, 429 and a dropped connection', () async {
      final FakeJiraGateway jira = FakeJiraGateway.fromFixture();

      for (final Failure failure in <Failure>[
        const AuthFailure(),
        const RateLimitFailure('slow down', Duration(seconds: 30)),
        const NetworkFailure(),
      ]) {
        jira.failWith = failure;
        await expectLater(jira.getIssue('NORTE-1'), throwsA(same(failure)));
      }

      jira.reset();
      expect((await jira.getIssue('NORTE-1')).issueKey, 'NORTE-1');
    });
  });

  group('FakeBatchTranscription', () {
    test('returns the fixture transcript and reports progress', () async {
      final FakeBatchTranscription engine = FakeBatchTranscription(
        transcripts: <String, Transcript>{
          'daily.m4a': const Transcript(text: 'bom dia', language: 'pt'),
        },
      );
      addTearDown(engine.dispose);

      final Future<List<double>> progress = engine.progress.take(4).toList();
      final Transcript transcript = await engine.transcribeFile('daily.m4a');

      expect(transcript.text, 'bom dia');
      expect(engine.requestedFiles, <String>['daily.m4a']);
      expect(await progress, <double>[0.25, 0.5, 0.75, 1]);
    });

    test('an explicit language overrides the fixture language', () async {
      final FakeBatchTranscription engine = FakeBatchTranscription(
        transcripts: <String, Transcript>{
          'a.m4a': const Transcript(text: 'hello', language: 'pt'),
        },
      );
      addTearDown(engine.dispose);

      expect(
        (await engine.transcribeFile('a.m4a', language: 'en')).language,
        'en',
      );
    });

    test('failWith and unknown files surface as errors', () async {
      final FakeBatchTranscription engine = FakeBatchTranscription();
      addTearDown(engine.dispose);

      // The fixture map is the fake's filesystem, so an unknown path is a
      // missing file and fails as the real adapter fails for one (S04-CT-01).
      await expectLater(
        engine.transcribeFile('missing.m4a'),
        throwsA(isA<NotFoundFailure>()),
      );

      engine.failWith = const NetworkFailure();
      await expectLater(
        engine.transcribeFile('missing.m4a'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('declares the batch mode', () {
      final FakeBatchTranscription engine = FakeBatchTranscription();
      addTearDown(engine.dispose);

      expect(engine.mode, TranscriptionMode.batch);
    });
  });

  group('FakeRealtimeTranscription', () {
    test(
      'replays the scripted partial/committed sequence from the fixture',
      () async {
        final FakeRealtimeTranscription engine =
            FakeRealtimeTranscription.fromFixture();

        final List<TranscriptEvent> events = await engine
            .start(Stream<Uint8List>.value(Uint8List.fromList(<int>[0, 1, 2])))
            .toList();

        expect(events, hasLength(4));
        expect(
          events.take(3).every((TranscriptEvent e) => !e.isCommitted),
          isTrue,
        );
        expect(events.last.isCommitted, isTrue);
        expect(events.last.text, 'muda o PROJ-123 pra concluído');
        expect(engine.receivedChunks, <Uint8List>[
          Uint8List.fromList(<int>[0, 1, 2]),
        ]);
      },
    );

    test('disconnectAfter reproduces a dropped socket mid-session', () async {
      final FakeRealtimeTranscription engine =
          FakeRealtimeTranscription.fromFixture()..disconnectAfter = 2;

      final List<TranscriptEvent> received = <TranscriptEvent>[];
      Object? error;
      final Completer<void> done = Completer<void>();

      // `asFuture` would intercept the error before onError sees it, so the
      // subscription is drained through an explicit onDone instead.
      engine
          .start(const Stream<Uint8List>.empty())
          .listen(
            received.add,
            onError: (Object e) => error = e,
            onDone: done.complete,
          );
      await done.future;

      expect(received, hasLength(2));
      expect(error, isA<NetworkFailure>());
    });

    test('stop is safe to call and is recorded', () async {
      final FakeRealtimeTranscription engine = FakeRealtimeTranscription();

      await engine.stop();
      await engine.stop();

      expect(engine.stopCount, 2);
      expect(engine.isRunning, isFalse);
    });
  });

  group('Failure', () {
    test('every failure carries a message and a readable toString', () {
      const List<Failure> failures = <Failure>[
        NetworkFailure(),
        AuthFailure(),
        NotFoundFailure(),
        RateLimitFailure(),
        TimeoutFailure(),
        EngineFailure(),
      ];

      for (final Failure failure in failures) {
        expect(failure.message, isNotEmpty);
        expect(failure.toString(), contains(failure.message));
      }
      expect(
        const RateLimitFailure('429', Duration(seconds: 30)).retryAfter,
        const Duration(seconds: 30),
      );
    });
  });
}
