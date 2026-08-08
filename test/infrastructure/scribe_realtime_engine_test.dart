import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/transcription_engine.dart';
import 'package:norte/infrastructure/transcription/scribe_realtime_engine.dart';

import '../fakes/fake_transcription_credential_store.dart';
import '../support/fake_realtime_socket.dart';

/// Bytes of synthetic PCM worth [duration] at the engine's format.
///
/// Not silence: a repeating ramp, so a test asserting "these bytes came back"
/// is asserting on data that could not survive being dropped and re-derived.
Uint8List pcmFor(Duration duration, {int seed = 0}) {
  final int bytes =
      ScribeRealtimeEngine.sampleRate *
      ScribeRealtimeEngine.bytesPerSample *
      duration.inMilliseconds ~/
      1000;
  return Uint8List.fromList(<int>[
    for (int i = 0; i < bytes; i++) (seed + i) % 251,
  ]);
}

/// S05-UT-06 — reconnection with the five-second buffer.
void main() {
  late FakeSocketConnector connector;
  late ScribeRealtimeEngine engine;
  late StreamController<Uint8List> microphone;

  /// Every backoff wait the engine is currently sitting in.
  ///
  /// The test holds the clock rather than the engine: a suite that slept its
  /// way through four real retries would add seven seconds to every run to
  /// prove arithmetic, and — more to the point — an outage that ends the
  /// instant it begins is not an outage. Leaving a wait pending is what keeps
  /// the connection down long enough for the buffer to matter.
  late List<Completer<void>> waits;

  setUp(() {
    connector = FakeSocketConnector();
    microphone = StreamController<Uint8List>();
    waits = <Completer<void>>[];
    engine = ScribeRealtimeEngine(
      credentialStore: FakeTranscriptionCredentialStore('synthetic-key'),
      connect: connector.call,
      sleep: (Duration _) {
        final Completer<void> wait = Completer<void>();
        waits.add(wait);
        return wait.future;
      },
    );
  });

  /// Runs every pending backoff wait to completion.
  Future<void> letTheBackoffElapse() async {
    while (waits.isNotEmpty) {
      waits.removeAt(0).complete();
      await pumpEventQueue();
    }
  }

  /// Kills the live socket and keeps the network down.
  Future<void> beginOutage() async {
    connector.isDown = true;
    await connector.current.drop();
    await pumpEventQueue();
  }

  /// Lets the network come back and the engine reconnect.
  Future<void> endOutage() async {
    connector.isDown = false;
    await letTheBackoffElapse();
  }

  tearDown(() async {
    await engine.stop();
    // Not awaited: closing a controller nobody subscribed to completes only
    // once someone does, and a test that never started a session never will.
    if (!microphone.isClosed) unawaited(microphone.close());
  });

  /// Starts a session and returns the events as they arrive.
  Future<List<TranscriptEvent>> listen() async {
    final List<TranscriptEvent> events = <TranscriptEvent>[];
    engine.start(microphone.stream).listen(events.add, onError: (Object _) {});
    await pumpEventQueue();
    return events;
  }

  group('S05-UT-06: the session', () {
    test(
      'S05-UT-06: audio reaches the socket and transcripts come back',
      () async {
        final List<TranscriptEvent> events = await listen();

        microphone.add(pcmFor(const Duration(milliseconds: 100)));
        await pumpEventQueue();

        connector.current
          ..emitPartial('muda o')
          ..emitPartial('muda o PROJ-123')
          ..emitCommitted('muda o PROJ-123 pra concluído');
        await pumpEventQueue();

        expect(
          connector.current.audio,
          pcmFor(const Duration(milliseconds: 100)),
        );
        expect(events.map((TranscriptEvent e) => e.isCommitted), <bool>[
          false,
          false,
          true,
        ]);
        expect(events.last.text, 'muda o PROJ-123 pra concluído');
      },
    );

    test('S05-UT-06: the key is presented and never held in a field', () async {
      await listen();
      expect(connector.keys, <String>['synthetic-key']);
    });

    test('S05-UT-06: no key configured is MissingApiKeyFailure', () async {
      final ScribeRealtimeEngine keyless = ScribeRealtimeEngine(
        credentialStore: FakeTranscriptionCredentialStore(),
        connect: connector.call,
        sleep: (Duration _) async {},
      );

      final List<Object> errors = <Object>[];
      keyless
          .start(const Stream<Uint8List>.empty())
          .listen((_) {}, onError: errors.add);
      await pumpEventQueue();

      expect(errors.single, isA<MissingApiKeyFailure>());
      expect(connector.attempts, 0, reason: 'nothing is dialled without a key');
    });
  });

  group('S05-UT-06: reconnection', () {
    test(
      'S05-UT-06: three seconds spoken during an outage are re-sent, whole',
      () async {
        await listen();

        // Before the drop.
        final Uint8List before = pcmFor(const Duration(milliseconds: 500));
        microphone.add(before);
        await pumpEventQueue();
        expect(connector.current.audio, before);

        await beginOutage();

        // Three seconds of speech into a socket that is not there.
        final Uint8List during = pcmFor(const Duration(seconds: 3), seed: 7);
        microphone.add(during);
        await pumpEventQueue();
        expect(
          engine.bufferedBytes,
          during.length,
          reason: 'the whole outage is held — three seconds is under the cap',
        );

        await endOutage();

        // A second socket was dialled and the held audio arrived on it, byte
        // for byte and in order — this is the "no loss" of §9.3.
        expect(connector.sockets, hasLength(2));
        expect(connector.current.audio, during);
        expect(engine.bufferedBytes, 0, reason: 'a flushed buffer is empty');

        // And the session carries on: the sentence completes on the new
        // socket.
        connector.current.emitCommitted('muda o PROJ-123 pra concluído');
        await pumpEventQueue();
      },
    );

    test(
      'S05-UT-06: past five seconds only the last five are kept, oldest first '
      'to go',
      () async {
        await listen();
        await beginOutage();

        // Seven seconds while the socket is down. The cap is five.
        final Uint8List seven = pcmFor(const Duration(seconds: 7), seed: 3);
        microphone.add(seven);
        await pumpEventQueue();
        expect(engine.bufferedBytes, ScribeRealtimeEngine.maxBufferedBytes);

        await endOutage();

        final Uint8List replayed = connector.current.audio;
        expect(replayed, hasLength(ScribeRealtimeEngine.maxBufferedBytes));
        // The *last* five seconds: what the user said most recently is what
        // they are still expecting to see appear.
        expect(
          replayed,
          Uint8List.sublistView(
            seven,
            seven.length - ScribeRealtimeEngine.maxBufferedBytes,
          ),
        );
      },
    );

    test('S05-UT-06: the cap holds across many small chunks', () async {
      // The platform delivers frames, not seconds. A cap that only worked on
      // one big chunk would be a cap that never worked in production.
      await listen();
      await beginOutage();

      for (int i = 0; i < 70; i++) {
        microphone.add(pcmFor(const Duration(milliseconds: 100), seed: i));
        expect(
          engine.bufferedBytes,
          lessThanOrEqualTo(ScribeRealtimeEngine.maxBufferedBytes),
        );
      }
      await pumpEventQueue();
      await endOutage();

      expect(
        connector.current.audio,
        hasLength(ScribeRealtimeEngine.maxBufferedBytes),
      );
    });

    test(
      'S05-UT-06: the backoff is spent before the session gives up',
      () async {
        connector.failFirst = 2;
        final List<TranscriptEvent> events = await listen();
        await letTheBackoffElapse();

        // Two refusals, then a socket. The session survives.
        expect(connector.attempts, 3);
        expect(events, isEmpty);
        expect(connector.sockets, hasLength(1));
      },
    );

    test('S05-UT-06: past the last backoff the session fails, once', () async {
      connector.failFirst = 99;

      final List<Object> errors = <Object>[];
      engine.start(microphone.stream).listen((_) {}, onError: errors.add);
      await pumpEventQueue();
      await letTheBackoffElapse();

      expect(connector.attempts, ScribeRealtimeEngine.defaultBackoff.length);
      expect(errors.single, isA<NetworkFailure>());
    });

    test('S05-UT-06: a rejected key is not retried', () async {
      connector
        ..failFirst = 99
        ..failWith = const AuthFailure('rejected');

      final List<Object> errors = <Object>[];
      engine.start(microphone.stream).listen((_) {}, onError: errors.add);
      await pumpEventQueue();

      // One attempt, not four: the second would be refused for the same
      // reason as the first.
      expect(connector.attempts, 1);
      expect(errors.single, isA<AuthFailure>());
      expect(waits, isEmpty, reason: 'no backoff was even entered');
    });
  });

  group('S05-UT-06: BR-06 — nothing reaches disk', () {
    test('S05-UT-06: no file is created during a reconnection', () async {
      // The FS spy: every `File(...)` in the zone is recorded, so a buffer
      // that spilled to disk to survive the outage would be caught by the
      // attempt, not by the leftovers.
      final List<String> touched = <String>[];

      await IOOverrides.runZoned(
        () async {
          await listen();
          await beginOutage();
          microphone.add(pcmFor(const Duration(seconds: 7)));
          await pumpEventQueue();
          await endOutage();
          await engine.stop();
        },
        // Deliberately does not return a `File`: the default constructor
        // consults the overrides again, so handing one back would recurse. A
        // spy that only has to prove nothing happened does not need to.
        createFile: (String path) {
          touched.add(path);
          throw StateError('BR-06 violated: the pipeline opened "$path"');
        },
      );

      expect(
        touched,
        isEmpty,
        reason: 'BR-06: voice audio is never written to disk',
      );
    });

    test('S05-UT-06: stopping drops the held audio', () async {
      await listen();
      await beginOutage();
      microphone.add(pcmFor(const Duration(seconds: 2)));
      await pumpEventQueue();
      expect(engine.bufferedBytes, greaterThan(0));

      await engine.stop();

      expect(engine.bufferedBytes, 0);
    });
  });

  group('S05-UT-06: the wire format is diagnosable (DEC-026)', () {
    test('S05-UT-06: an unreadable frame is reported, not swallowed', () async {
      // The one thing no automated test can verify is the service's actual
      // frame names, so the ambiguous manual outcome — "it connects but
      // nothing appears" — has to leave evidence. Silence here would make a
      // protocol mismatch indistinguishable from a dead microphone.
      final List<String> lines = <String>[];
      final FakeSocketConnector spy = FakeSocketConnector();
      final ScribeRealtimeEngine logged = ScribeRealtimeEngine(
        credentialStore: FakeTranscriptionCredentialStore('synthetic-key'),
        connect: spy.call,
        log: lines.add,
        sleep: (Duration _) async {},
      );
      addTearDown(logged.stop);

      final List<TranscriptEvent> events = <TranscriptEvent>[];
      logged
          .start(const Stream<Uint8List>.empty())
          .listen(events.add, onError: (Object _) {});
      await pumpEventQueue();

      spy.current.emitRaw(<String, Object?>{
        'type': 'speech_segment',
        'utterance': 'muda o PROJ-123 pra concluído',
      });
      await pumpEventQueue();

      expect(events, isEmpty);
      expect(lines.single, contains('speech_segment'));
      expect(lines.single, contains('utterance'));
      // Shape, never content: the transcript does not go in a log (BR-06).
      expect(lines.single, isNot(contains('PROJ-123')));
    });

    test('S05-UT-06: a frame it can read is not reported', () async {
      final List<String> lines = <String>[];
      final FakeSocketConnector spy = FakeSocketConnector();
      final ScribeRealtimeEngine logged = ScribeRealtimeEngine(
        credentialStore: FakeTranscriptionCredentialStore('synthetic-key'),
        connect: spy.call,
        log: lines.add,
        sleep: (Duration _) async {},
      );
      addTearDown(logged.stop);

      logged
          .start(const Stream<Uint8List>.empty())
          .listen((_) {}, onError: (Object _) {});
      await pumpEventQueue();

      // Every spelling the tolerant reader accepts.
      spy.current
        ..emitPartial('muda o')
        ..emitCommitted('muda o PROJ-123 pra concluído')
        ..emitRaw(<String, Object?>{
          'type': 'transcript',
          'is_final': true,
          'transcript': 'outra coisa',
        });
      await pumpEventQueue();

      expect(lines, isEmpty);
    });
  });

  group('S05-UT-06: service errors', () {
    test('S05-UT-06: an error frame ends the session', () async {
      final List<TranscriptEvent> events = await listen();
      connector.current.emitError('rate_limit_error');
      await pumpEventQueue();

      expect(events, isEmpty);
    });

    test('S05-UT-06: a rate-limit frame is RateLimitFailure', () async {
      final List<Object> errors = <Object>[];
      engine.start(microphone.stream).listen((_) {}, onError: errors.add);
      await pumpEventQueue();

      connector.current.emitError('rate_limit_error');
      await pumpEventQueue();

      expect(errors.single, isA<RateLimitFailure>());
    });
  });
}
