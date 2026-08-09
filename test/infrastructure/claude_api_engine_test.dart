import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/ai_credential_store.dart';
import 'package:norte/infrastructure/ai/claude_api_engine.dart';
import 'package:norte/infrastructure/ai/intent_codec.dart';

import '../fakes/fake_clock.dart';
import '../support/fake_claude_server.dart';
import '../support/meeting_fixtures.dart';

/// Fake [AiCredentialStore] — the key never comes from anywhere else (BR-08).
class _FakeAiCredentialStore implements AiCredentialStore {
  _FakeAiCredentialStore([this._key]);

  String? _key;

  @override
  Future<String?> read() async => _key;

  @override
  Future<void> write(String apiKey) async => _key = apiKey;

  @override
  Future<void> clear() async => _key = null;
}

/// S03-IT-01 — ClaudeApiEngine: request and caching.
void main() {
  late FakeClaudeServer server;

  ClaudeApiEngine engineWith({String? apiKey = 'synthetic-key'}) =>
      ClaudeApiEngine(
        dio: Dio(),
        credentialStore: _FakeAiCredentialStore(apiKey),
        clock: FakeClock(DateTime.utc(2026, 8, 8, 11)),
        baseUrl: server.baseUrl,
      );

  setUp(() async {
    server = await FakeClaudeServer.start(answer: summaryFixture('retro.json'));
  });

  tearDown(() => server.close());

  group('S03-IT-01: the request', () {
    test(
      'S03-IT-01: POSTs /v1/messages with auth and version headers',
      () async {
        await engineWith().summarize(retroTranscript, retroTemplate);

        expect(server.requests, <String>['POST /v1/messages']);
        expect(server.lastApiKey, 'synthetic-key');
        expect(
          server.headers.last.value('anthropic-version'),
          ClaudeApiEngine.apiVersion,
        );
      },
    );

    test('S03-IT-01: the system prompt is marked with cache_control', () async {
      await engineWith().summarize(retroTranscript, retroTemplate);

      final Map<String, Object?> block =
          server.lastSystemBlocks.single! as Map<String, Object?>;
      expect(block['type'], 'text');
      expect(block['cache_control'], <String, Object?>{'type': 'ephemeral'});
      expect(block['text'], contains(retroTemplate.systemPrompt));
    });

    test(
      'S03-IT-01: the transcript is in the user message, not the system one',
      () async {
        await engineWith().summarize(retroTranscript, retroTemplate);

        final List<Object?> messages =
            server.bodies.last['messages']! as List<Object?>;
        final Map<String, Object?> user =
            messages.single! as Map<String, Object?>;
        expect(user['role'], 'user');
        expect(user['content'], retroTranscript);

        // The whole reason for the split: a system prompt carrying the
        // transcript would change on every meeting and cache nothing.
        final Map<String, Object?> system =
            server.lastSystemBlocks.single! as Map<String, Object?>;
        expect(system['text'], isNot(contains('Ana: the outbox')));
      },
    );

    test(
      'S03-IT-01: the cached prefix is identical across two meetings',
      () async {
        final ClaudeApiEngine engine = engineWith();
        await engine.summarize('first meeting transcript', retroTemplate);
        await engine.summarize('a completely different one', retroTemplate);

        expect(server.bodies, hasLength(2));
        expect(server.bodies[0]['system'], server.bodies[1]['system']);
        expect(
          server.bodies[0]['messages'],
          isNot(server.bodies[1]['messages']),
        );
      },
    );

    test('S03-IT-01: the request streams', () async {
      await engineWith().summarize(retroTranscript, retroTemplate);

      expect(server.bodies.last['stream'], isTrue);
    });
  });

  group('S03-IT-01: the response', () {
    test(
      'S03-IT-01: the streamed answer is parsed into a MeetingSummary',
      () async {
        // The fixture arrives in 24-character chunks, so this also proves the
        // accumulator reassembles them in order.
        final MeetingSummary summary = await engineWith().summarize(
          retroTranscript,
          retroTemplate,
        );

        expect(summary.sections.keys, retroTemplate.sectionTitles);
        expect(summary.sections['What went well'], contains('outbox'));
        expect(summary.actionItems, hasLength(2));
        expect(summary.actionItems.first.description, 'Update the runbook');
        expect(summary.generatedAt, DateTime.utc(2026, 8, 8, 11));
        expect(summary.engineId, ClaudeApiEngine.defaultModel);
      },
    );

    test('S03-IT-01: thinking deltas are not mixed into the summary', () async {
      // The fake always emits one. Concatenating it would make the JSON
      // unparseable, so a green parse is the assertion.
      final MeetingSummary summary = await engineWith().summarize(
        retroTranscript,
        retroTemplate,
      );

      expect(
        summary.sections['What went well'],
        isNot(contains('considering')),
      );
    });
  });

  group('S03-IT-01: failures', () {
    test(
      'no key configured is MissingApiKeyFailure, and nothing is sent',
      () async {
        await expectLater(
          engineWith(apiKey: null).summarize(retroTranscript, retroTemplate),
          throwsA(isA<MissingApiKeyFailure>()),
        );
        expect(server.requests, isEmpty);
      },
    );

    test('a blank key is treated as no key', () async {
      await expectLater(
        engineWith(apiKey: '   ').summarize(retroTranscript, retroTemplate),
        throwsA(isA<MissingApiKeyFailure>()),
      );
    });

    test('401 is AuthFailure', () async {
      server.forceStatus = 401;

      await expectLater(
        engineWith().summarize(retroTranscript, retroTemplate),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('429 is RateLimitFailure carrying Retry-After', () async {
      server
        ..forceStatus = 429
        ..retryAfter = '30';

      await expectLater(
        engineWith().summarize(retroTranscript, retroTemplate),
        throwsA(
          isA<RateLimitFailure>().having(
            (RateLimitFailure f) => f.retryAfter,
            'retryAfter',
            const Duration(seconds: 30),
          ),
        ),
      );
    });

    test(
      'an error event mid-stream is a failure, not a short summary',
      () async {
        // The dangerous case: HTTP 200, some text, then the API gives up. A
        // reader that stopped at the last delta would return half a retro and
        // call it done.
        server
          ..streamErrorType = 'overloaded_error'
          ..errorAfterChunks = 1;

        await expectLater(
          engineWith().summarize(retroTranscript, retroTemplate),
          throwsA(isA<RateLimitFailure>()),
        );
      },
    );

    test('a 200 that is not an event stream is AiResponseFailure', () async {
      server.answerWithoutSse = true;

      await expectLater(
        engineWith().summarize(retroTranscript, retroTemplate),
        throwsA(isA<AiResponseFailure>()),
      );
    });

    test('an unparseable answer is AiResponseFailure', () async {
      server.answer = summaryFixture('malformed.txt');

      await expectLater(
        engineWith().summarize(retroTranscript, retroTemplate),
        throwsA(isA<AiResponseFailure>()),
      );
    });

    test(
      'an unreachable host is NetworkFailure, never a DioException',
      () async {
        final ClaudeApiEngine engine = ClaudeApiEngine(
          dio: Dio(),
          credentialStore: _FakeAiCredentialStore('synthetic-key'),
          clock: FakeClock(DateTime.utc(2026)),
          // Port 1 on loopback: nothing listens there.
          baseUrl: 'http://127.0.0.1:1',
        );

        await expectLater(
          engine.summarize(retroTranscript, retroTemplate),
          throwsA(isA<NetworkFailure>()),
        );
      },
    );

    test(
      'parseIntent caches the prompt and sends the context uncached',
      () async {
        server.answer =
            '{"intent":"updateJira","slots":{"issueKey":"PROJ-123",'
            '"transition":"Done"},"confidence":0.92}';

        final VoiceIntent intent = await engineWith().parseIntent(
          'muda o PROJ-123 pra concluído',
          const IntentContext(knownIssueKeys: <String>['PROJ-123']),
        );

        expect(intent.type, IntentType.updateJira);
        expect(intent.slots['issueKey'], 'PROJ-123');
        expect(intent.confidence, 0.92);

        // The cached half is the codec's constant prompt, and nothing about
        // this particular command may be in it — a varying prefix costs the
        // cache on every voice command the user ever speaks.
        final Map<String, Object?> block =
            server.lastSystemBlocks.single! as Map<String, Object?>;
        expect(block['text'], const IntentCodec().systemPrompt);
        expect(block['cache_control'], <String, Object?>{'type': 'ephemeral'});
        // The prompt does contain `PROJ-123` — as the slot example. What it
        // must never contain is this call: the utterance, or the keys this
        // particular user happens to have linked.
        expect(
          block['text'].toString(),
          isNot(contains('muda o PROJ-123 pra concluído')),
        );

        // The situational half rides in the user message, after the breakpoint.
        final List<Object?> messages =
            server.bodies.last['messages']! as List<Object?>;
        final String content =
            (messages.single! as Map<String, Object?>)['content']! as String;
        expect(content, contains('muda o PROJ-123 pra concluído'));
        expect(content, contains('PROJ-123'));
      },
    );
  });
}
