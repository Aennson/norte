import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/transcript.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/transcription_engine.dart';
import 'package:norte/infrastructure/transcription/whisper_batch_engine.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_batch_transcription.dart';
import '../fakes/fake_transcription_credential_store.dart';
import '../support/fake_whisper_server.dart';

/// What a subject needs to supply so the shared cases can run against it.
class _Subject {
  _Subject({
    required this.name,
    required this.build,
    required this.setFailure,
    this.dispose,
  });

  final String name;

  /// Builds the adapter with a file at [existingPath] transcribing to
  /// [answer].
  final Future<BatchTranscription> Function(String existingPath, String answer)
  build;

  /// Programs the subject's next call to fail with a server error.
  final Future<void> Function() setFailure;

  final Future<void> Function()? dispose;
}

/// S04-CT-01 — the [BatchTranscription] contract, run against every
/// implementation.
///
/// **The fake is a subject, not a spectator.** Every use-case, widget and E2E
/// test in this sprint drives `FakeBatchTranscription`; if the fake were more
/// forgiving than `WhisperBatchEngine`, all of them could pass while the app
/// failed. These cases are what stop the two drifting apart.
///
/// `ScribeRealtimeEngine` is a different port and joins its own contract in
/// Sprint 05.
void main() {
  late Directory temp;
  late FakeWhisperServer server;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('norte_s04_ct_');
    server = await FakeWhisperServer.start();
  });

  tearDown(() async {
    await server.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  String realFile(String answer) {
    final String path = p.join(temp.path, 'meeting.m4a');
    File(path).writeAsBytesSync(List<int>.filled(1024, 3));
    return path;
  }

  final List<_Subject> subjects = <_Subject>[
    _Subject(
      name: 'WhisperBatchEngine',
      build: (String path, String answer) async {
        server.text = answer;
        return WhisperBatchEngine(
          dio: Dio(),
          credentialStore: FakeTranscriptionCredentialStore.configured(),
          baseUrl: server.baseUrl,
        );
      },
      setFailure: () async => server.forceStatus = 500,
    ),
    _Subject(
      name: 'FakeBatchTranscription',
      build: (String path, String answer) async => FakeBatchTranscription(
        transcripts: <String, Transcript>{
          path: Transcript(text: answer, language: 'pt'),
        },
      ),
      setFailure: () async {},
    ),
  ];

  for (final _Subject subject in subjects) {
    group('S04-CT-01: ${subject.name}', () {
      test('S04-CT-01: declares the batch mode', () async {
        final BatchTranscription engine = await subject.build(
          realFile('x'),
          'x',
        );

        expect(engine.mode, TranscriptionMode.batch);
      });

      test('S04-CT-01: success returns the transcript text', () async {
        final String path = realFile('bom dia');
        final BatchTranscription engine = await subject.build(path, 'bom dia');

        final Transcript transcript = await engine.transcribeFile(path);

        expect(transcript.text, 'bom dia');
        expect(transcript.language, isNotEmpty);
      });

      test('S04-CT-01: a nonexistent file is a NotFoundFailure', () async {
        final BatchTranscription engine = await subject.build(
          realFile('x'),
          'x',
        );

        // Both subjects must agree on this, and for the same reason: the
        // caller passed a path to something that is not there.
        await expectLater(
          engine.transcribeFile(p.join(temp.path, 'absent.m4a')),
          throwsA(isA<NotFoundFailure>()),
        );
      });

      test('S04-CT-01: a server error is a TranscriptionFailure', () async {
        final String path = realFile('x');
        final BatchTranscription engine = await subject.build(path, 'x');

        await subject.setFailure();
        if (engine is FakeBatchTranscription) {
          engine.failWith = const TranscriptionFailure();
        }

        await expectLater(
          engine.transcribeFile(path),
          throwsA(isA<TranscriptionFailure>()),
        );
      });

      test('S04-CT-01: a failure leaves the audio file alone', () async {
        final String path = realFile('x');
        final BatchTranscription engine = await subject.build(path, 'x');

        await subject.setFailure();
        if (engine is FakeBatchTranscription) {
          engine.failWith = const TranscriptionFailure();
        }

        await expectLater(
          engine.transcribeFile(path),
          throwsA(isA<TranscriptionFailure>()),
        );
        // The whole retry rule rests on this, and it is a property of the
        // port rather than of one adapter.
        expect(File(path).existsSync(), isTrue);
      });

      test('S04-CT-01: progress is a broadcast stream', () async {
        final String path = realFile('x');
        final BatchTranscription engine = await subject.build(path, 'x');

        // Two listeners, because the screen listens while the use case drives
        // and neither owns the stream. A single-subscription stream would
        // throw on the second listen.
        final Stream<double> progress = engine.progress;
        final StreamSubscription<double> a = progress.listen((_) {});
        final StreamSubscription<double> b = progress.listen((_) {});
        addTearDown(() async {
          await a.cancel();
          await b.cancel();
        });

        await engine.transcribeFile(path);
      });
    });
  }
}
