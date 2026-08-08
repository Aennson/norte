import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/ports/transcription_engine.dart';
import 'package:norte/infrastructure/transcription/scribe_realtime_engine.dart';

import '../fakes/fake_realtime_transcription.dart';
import '../fakes/fake_transcription_credential_store.dart';
import '../support/fake_realtime_socket.dart';

/// The one utterance both engines are held to, in the order VAD produces it.
const List<TranscriptEvent> _script = <TranscriptEvent>[
  TranscriptEvent(text: 'muda o', isCommitted: false),
  TranscriptEvent(text: 'muda o PROJ', isCommitted: false),
  TranscriptEvent(text: 'muda o PROJ-123', isCommitted: false),
  TranscriptEvent(text: 'muda o PROJ-123 pra concluído', isCommitted: true),
];

/// One engine under test, plus the two things the shared cases need to do to
/// it: make the service speak, and make it speak late.
class _Subject {
  _Subject({
    required this.name,
    required this.engine,
    required this.speak,
    required this.speakLate,
  });

  final String name;
  final RealtimeTranscription engine;

  /// Plays [_script] through whatever stands in for the service.
  final Future<void> Function() speak;

  /// Tries to push one more committed segment — used after `stop`.
  final void Function(String text) speakLate;
}

/// S05-CT-01 — the `RealtimeTranscription` contract.
///
/// **The same script, on every implementation.** `FakeRealtimeTranscription`
/// is what the router, widget and E2E suites are shown; `ScribeRealtimeEngine`
/// is what a user's voice actually goes through. If the two ever disagree
/// about the order of `partial` and `committed`, or about whether `stop`
/// really ends the session, every test above them is testing something the app
/// does not do.
void main() {
  late FakeRealtimeTranscription fake;
  late FakeSocketConnector connector;
  late ScribeRealtimeEngine scribe;
  late StreamController<Uint8List> microphone;

  setUp(() {
    microphone = StreamController<Uint8List>.broadcast();

    fake = FakeRealtimeTranscription(script: _script)..autoplay = false;

    connector = FakeSocketConnector();
    scribe = ScribeRealtimeEngine(
      credentialStore: FakeTranscriptionCredentialStore('synthetic-key'),
      connect: connector.call,
      sleep: (Duration _) async {},
    );
  });

  tearDown(() async {
    await fake.stop();
    await scribe.stop();
    if (!microphone.isClosed) unawaited(microphone.close());
  });

  List<_Subject> subjects() => <_Subject>[
    _Subject(
      name: 'FakeRealtimeTranscription',
      engine: fake,
      speak: () async {
        for (final TranscriptEvent event in _script) {
          fake.emit(event);
        }
        await pumpEventQueue();
      },
      speakLate: fake.emitCommitted,
    ),
    _Subject(
      name: 'ScribeRealtimeEngine',
      engine: scribe,
      speak: () async {
        for (final TranscriptEvent event in _script) {
          if (event.isCommitted) {
            connector.current.emitCommitted(event.text);
          } else {
            connector.current.emitPartial(event.text);
          }
        }
        await pumpEventQueue();
      },
      speakLate: (String text) {
        if (connector.sockets.isNotEmpty) {
          connector.current.emitCommitted(text);
        }
      },
    ),
  ];

  for (int index = 0; index < 2; index++) {
    // Resolved inside each test, because `setUp` rebuilds the subjects.
    _Subject subject() => subjects()[index];
    final String name = index == 0
        ? 'FakeRealtimeTranscription'
        : 'ScribeRealtimeEngine';

    group('S05-CT-01: $name', () {
      test('S05-CT-01: declares the realtime mode', () {
        expect(subject().engine.mode, TranscriptionMode.realtime);
      });

      test(
        'S05-CT-01: partials arrive first, then one committed segment',
        () async {
          final _Subject under = subject();
          final List<TranscriptEvent> events = <TranscriptEvent>[];
          under.engine
              .start(microphone.stream)
              .listen(events.add, onError: (Object _) {});
          await pumpEventQueue();

          await under.speak();

          expect(events, _script);
          // The semantic order the contract is about: everything before the
          // commit is provisional, and exactly one event closes the segment.
          expect(
            events.takeWhile((TranscriptEvent e) => !e.isCommitted).length,
            events.length - 1,
          );
          expect(events.last.isCommitted, isTrue);
          expect(
            events.where((TranscriptEvent e) => e.isCommitted),
            hasLength(1),
          );
        },
      );

      test(
        'S05-CT-01: each event carries the whole segment, not a delta',
        () async {
          final _Subject under = subject();
          final List<TranscriptEvent> events = <TranscriptEvent>[];
          under.engine
              .start(microphone.stream)
              .listen(events.add, onError: (Object _) {});
          await pumpEventQueue();
          await under.speak();

          // A consumer renders the latest event and never accumulates, so
          // every text must contain the one before it.
          for (int i = 1; i < events.length; i++) {
            expect(
              events[i].text,
              startsWith(events[i - 1].text),
              reason: 'a delta would break every renderer above this port',
            );
          }
        },
      );

      test('S05-CT-01: stop closes the stream and nothing follows', () async {
        final _Subject under = subject();
        final List<TranscriptEvent> events = <TranscriptEvent>[];
        var closed = false;
        under.engine
            .start(microphone.stream)
            .listen(
              events.add,
              onError: (Object _) {},
              onDone: () => closed = true,
            );
        await pumpEventQueue();
        await under.speak();

        final int beforeStop = events.length;
        await under.engine.stop();
        await pumpEventQueue();

        expect(closed, isTrue, reason: 'stop closes the stream');

        // The service is still talking; the port is not listening.
        under.speakLate('mais alguma coisa');
        await pumpEventQueue();
        expect(events, hasLength(beforeStop));
      });

      test('S05-CT-01: stop is safe with no session open', () async {
        await subject().engine.stop();
        await subject().engine.stop();
      });
    });
  }
}
