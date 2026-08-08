import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/transcript.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/infrastructure/transcription/whisper_batch_engine.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_transcription_credential_store.dart';
import '../support/fake_whisper_server.dart';

/// S04-IT-01 — WhisperBatchEngine: correct request.
///
/// Driven through a real loopback socket, so the suite exercises the URL, the
/// authorization header and the multipart body rather than a mock's opinion of
/// them.
void main() {
  late FakeWhisperServer server;
  late Directory temp;
  late String audioPath;

  WhisperBatchEngine engineWith({String? apiKey = 'synthetic-key'}) {
    final WhisperBatchEngine engine = WhisperBatchEngine(
      dio: Dio(),
      credentialStore: FakeTranscriptionCredentialStore(apiKey),
      baseUrl: server.baseUrl,
    );
    addTearDown(engine.dispose);
    return engine;
  }

  setUp(() async {
    server = await FakeWhisperServer.start(text: 'bom dia', language: 'pt');
    temp = await Directory.systemTemp.createTemp('norte_s04_');
    audioPath = p.join(temp.path, 'meeting_1.m4a');
    // A small fixture rather than a real recording: the adapter is being
    // tested on what it does with the bytes, not on what is in them.
    await File(audioPath).writeAsBytes(List<int>.filled(2048, 7));
  });

  tearDown(() async {
    await server.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  group('S04-IT-01: the request', () {
    test('S04-IT-01: POSTs the transcriptions endpoint with the key', () async {
      await engineWith().transcribeFile(audioPath, language: 'pt');

      expect(server.requests, <String>['POST ${WhisperBatchEngine.endpoint}']);
      expect(server.lastAuthorization, 'Bearer synthetic-key');
    });

    test(
      'S04-IT-01: the multipart carries the file and the language',
      () async {
        await engineWith().transcribeFile(audioPath, language: 'pt');

        expect(server.uploadedFilename, 'meeting_1.m4a');
        expect(server.fieldOf('language'), 'pt');
        expect(server.fieldOf('model'), WhisperBatchEngine.defaultModel);
        // `verbose_json` is what carries the detected language back; plain
        // `json` would force the adapter to echo the caller's own request.
        expect(server.fieldOf('response_format'), 'verbose_json');
      },
    );

    test('S04-IT-01: an omitted language is omitted, not guessed', () async {
      await engineWith().transcribeFile(audioPath);

      expect(server.fieldOf('language'), isNull);
      expect(server.uploadedFilename, 'meeting_1.m4a');
    });

    test('S04-IT-01: the answer is parsed into a Transcript', () async {
      final Transcript transcript = await engineWith().transcribeFile(
        audioPath,
      );

      expect(transcript.text, 'bom dia');
      expect(transcript.language, 'pt');
    });

    test(
      'S04-IT-01: the engine detected language wins over the requested one',
      () async {
        server.language = 'en';

        final Transcript transcript = await engineWith().transcribeFile(
          audioPath,
          language: 'pt',
        );

        // The port promises the engine's answer rather than the question. A
        // caller that asked for `pt` on audio that was English needs to know.
        expect(transcript.language, 'en');
      },
    );

    test('S04-IT-01: upload progress is reported', () async {
      final WhisperBatchEngine engine = engineWith();
      final Future<List<double>> reported = engine.progress.toList();

      await engine.transcribeFile(audioPath);
      await engine.dispose();

      final List<double> progress = await reported;
      expect(progress, isNotEmpty);
      expect(progress.every((double p) => p >= 0 && p <= 1), isTrue);
      expect(progress.last, 1.0);
    });
  });

  group('S04-IT-01: failures', () {
    test('S04-IT-01: 401 is an AuthFailure', () async {
      server.forceStatus = 401;

      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('S04-IT-01: 403 is an AuthFailure too', () async {
      server.forceStatus = 403;

      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('S04-IT-01: 5xx is a TranscriptionFailure', () async {
      server.forceStatus = 500;

      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<TranscriptionFailure>()),
      );
    });

    test('S04-IT-01: 503 is a TranscriptionFailure too', () async {
      server.forceStatus = 503;

      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<TranscriptionFailure>()),
      );
    });

    test('S04-IT-01: 429 is a RateLimitFailure', () async {
      server.forceStatus = 429;

      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<RateLimitFailure>()),
      );
    });

    test('S04-IT-01: 413 says the recording is too long', () async {
      server.forceStatus = 413;

      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('S04-IT-01: no key configured is MissingApiKeyFailure, and nothing is '
        'uploaded', () async {
      await expectLater(
        engineWith(apiKey: null).transcribeFile(audioPath),
        throwsA(isA<MissingApiKeyFailure>()),
      );

      // The distinction that matters: a missing key never reaches the
      // network, so it cannot be confused with a rejected one.
      expect(server.requests, isEmpty);
    });

    test(
      'S04-IT-01: a missing file fails before the key is even read',
      () async {
        await expectLater(
          engineWith().transcribeFile(p.join(temp.path, 'nope.m4a')),
          throwsA(isA<NotFoundFailure>()),
        );

        expect(server.requests, isEmpty);
      },
    );

    test('S04-IT-01: a 200 that is not JSON is a TranscriptionFailure, not a '
        'transcript', () async {
      server.answerWithHtml = true;

      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<TranscriptionFailure>()),
      );
    });

    test('S04-IT-01: an empty transcript is a failure, not a short '
        'meeting', () async {
      server.rawAnswer = '{"text": "   ", "language": "pt"}';

      // Passing this on would hand the summarizer an empty string and produce
      // a confident summary of nothing.
      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<TranscriptionFailure>()),
      );
    });

    test('S04-IT-01: the audio file survives every failure', () async {
      server.forceStatus = 500;

      await expectLater(
        engineWith().transcribeFile(audioPath),
        throwsA(isA<TranscriptionFailure>()),
      );

      // The port forbids the engine from deleting the caller's file, and the
      // sprint's retry-without-re-recording rule depends on it.
      expect(File(audioPath).existsSync(), isTrue);
    });

    test('S04-IT-01: an unreachable host is a NetworkFailure', () async {
      final WhisperBatchEngine engine = WhisperBatchEngine(
        dio: Dio(),
        credentialStore: FakeTranscriptionCredentialStore.configured(),
        // Port 1 on loopback: nothing listens, and the connection is refused
        // rather than left hanging.
        baseUrl: 'http://127.0.0.1:1',
      );
      addTearDown(engine.dispose);

      await expectLater(
        engine.transcribeFile(audioPath),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
