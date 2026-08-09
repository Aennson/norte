import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/transcription_engine.dart';
import 'package:norte/infrastructure/transcription/realtime_socket.dart';
import 'package:norte/infrastructure/transcription/scribe_realtime_engine.dart';

import '../fakes/fake_transcription_credential_store.dart';
import '../support/fake_realtime_server.dart';

/// `WebSocketRealtimeSocket` against a real socket.
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4, as
/// the regression test for the second Sprint 05 wiring defect: the API key was
/// accepted as an argument and never sent, because
/// `WebSocketChannel.connect` carries no headers. Every engine test drives
/// `FakeRealtimeSocket`, so the one class that would have sent the credential
/// had **no coverage at all** and the mistake was invisible.
///
/// A fake transport is the right tool for reproducing an outage. It is the
/// wrong tool for asking whether a credential leaves the machine, and this
/// suite is the answer to that question.
void main() {
  late FakeRealtimeServer server;

  setUp(() async => server = await FakeRealtimeServer.start());
  tearDown(() => server.close());

  group('the handshake', () {
    test('presents the API key in the xi-api-key header', () async {
      final RealtimeSocket socket = await WebSocketRealtimeSocket.connect(
        Uri.parse(server.baseUrl),
        'synthetic-key',
      );
      addTearDown(socket.close);

      expect(
        server.headerOf(WebSocketRealtimeSocket.apiKeyHeader),
        'synthetic-key',
      );
    });

    test('the key is never in the URL', () async {
      final RealtimeSocket socket = await WebSocketRealtimeSocket.connect(
        Uri.parse('${server.baseUrl}?model_id=scribe_v2_realtime'),
        'synthetic-key',
      );
      addTearDown(socket.close);

      // A URL reaches proxy logs, crash reports and shell history; a header
      // does not. A credential in a query string cannot be taken back (BR-08).
      expect(server.queries.single.values, isNot(contains('synthetic-key')));
      expect(server.queries.single['model_id'], 'scribe_v2_realtime');
    });

    test('a refused key is AuthFailure, not a network problem', () async {
      server.refuseWith = 401;

      await expectLater(
        WebSocketRealtimeSocket.connect(Uri.parse(server.baseUrl), 'wrong-key'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('a forbidden key is AuthFailure too', () async {
      server.refuseWith = 403;

      await expectLater(
        WebSocketRealtimeSocket.connect(Uri.parse(server.baseUrl), 'no-scope'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('an unreachable host is NetworkFailure', () async {
      // Port 1 on loopback: nothing listens there.
      await expectLater(
        WebSocketRealtimeSocket.connect(
          Uri.parse('ws://127.0.0.1:1'),
          'synthetic-key',
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('nothing but a Failure escapes', () async {
      server.refuseWith = 500;

      try {
        await WebSocketRealtimeSocket.connect(
          Uri.parse(server.baseUrl),
          'synthetic-key',
        );
        fail('expected a Failure');
      } on Failure {
        // The contract (`docs/project-rules.md` §6).
      } catch (error) {
        fail('a ${error.runtimeType} escaped: $error');
      }
    });
  });

  group('the engine over a real socket', () {
    test('sends the key, the audio and reads a transcript back', () async {
      // The whole adapter against a real transport, once: the key on the
      // handshake, PCM on the wire, a transcript coming back.
      final ScribeRealtimeEngine engine = ScribeRealtimeEngine(
        credentialStore: FakeTranscriptionCredentialStore('synthetic-key'),
        baseUrl: server.baseUrl,
        // The fake server upgrades any path; the engine's own endpoint and
        // query are exercised by the query assertion above.
        sleep: (Duration _) async {},
      );
      addTearDown(engine.stop);

      final List<TranscriptEvent> events = <TranscriptEvent>[];
      final Stream<Uint8List> pcm = Stream<Uint8List>.value(
        Uint8List.fromList(<int>[1, 2, 3, 4]),
      );
      engine.start(pcm).listen(events.add, onError: (Object _) {});

      // A real socket, so the test has to wait for real I/O rather than pump
      // a queue.
      await _until(() => server.sockets.isNotEmpty);
      expect(
        server.headerOf(WebSocketRealtimeSocket.apiKeyHeader),
        'synthetic-key',
      );

      await _until(() => server.received.isNotEmpty);
      expect(server.received.first, <int>[1, 2, 3, 4]);

      server.emitCommitted('muda o PROJ-123 pra concluído');
      await _until(() => events.isNotEmpty);

      expect(events.single.isCommitted, isTrue);
      expect(events.single.text, 'muda o PROJ-123 pra concluído');
    });
  });
}

/// Polls [condition] until it holds, or fails the test after two seconds.
Future<void> _until(bool Function() condition) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition never held');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
