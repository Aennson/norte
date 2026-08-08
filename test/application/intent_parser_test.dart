import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/voice/intent_parser.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fakes.dart';

/// S05-UT-01 and S05-UT-02 — the intent parser.
void main() {
  const String utterance = 'muda o PROJ-123 pra concluído';

  IntentParser parserFor(String response) => IntentParser(
    engine: FakeAiEngine(intents: <String, String>{utterance: response}),
  );

  VoiceIntent intentOf(Result<VoiceIntent> result) {
    expect(result, isA<Ok<VoiceIntent>>(), reason: 'the parse must not fail');
    return result.valueOrNull!;
  }

  group('S05-UT-01: valid JSON', () {
    test(
      'S05-UT-01: a well-formed answer becomes the intent it names',
      () async {
        final IntentParser parser = parserFor(
          '{"intent":"updateJira","slots":{"issueKey":"PROJ-123",'
          '"transition":"Done"},"confidence":0.92}',
        );

        final VoiceIntent intent = intentOf(await parser.parse(utterance));

        expect(intent.type, IntentType.updateJira);
        expect(intent.slots, <String, dynamic>{
          'issueKey': 'PROJ-123',
          'transition': 'Done',
        });
        expect(intent.confidence, 0.92);
        expect(intent.isComplete, isTrue);
      },
    );

    test(
      'S05-UT-01: a fenced answer and one behind prose read the same',
      () async {
        // Both are shapes a model actually emits, and neither is the user's
        // fault — refusing them would send someone back to repeat a command
        // the app understood perfectly well.
        for (final String response in <String>[
          '```json\n{"intent":"updateJira","slots":{"issueKey":"PROJ-123",'
              '"transition":"Done"},"confidence":0.92}\n```',
          'Entendi o pedido. Segue o JSON:\n'
              '{"intent":"updateJira","slots":{"issueKey":"PROJ-123",'
              '"transition":"Done"},"confidence":0.92}',
        ]) {
          final VoiceIntent intent = intentOf(
            await parserFor(response).parse(utterance),
          );
          expect(intent.type, IntentType.updateJira);
          expect(intent.slots['issueKey'], 'PROJ-123');
          expect(intent.confidence, 0.92);
        }
      },
    );
  });

  group('S05-UT-02: invalid JSON becomes unknown', () {
    test('S05-UT-02: prose, JSON without an intent, and an intent outside the '
        'enum all become unknown at confidence 0', () async {
      const List<String> responses = <String>[
        'Desculpe, não identifiquei nenhum comando nessa frase.',
        '{"slots":{"issueKey":"PROJ-123"},"confidence":0.9}',
        '{"intent":"deleteEverything","slots":{},"confidence":0.99}',
      ];

      for (final String response in responses) {
        final Result<VoiceIntent> result = await parserFor(
          response,
        ).parse(utterance);

        // "No exception escapes" is the assertion: the parse completed.
        final VoiceIntent intent = intentOf(result);
        expect(intent.type, IntentType.unknown, reason: response);
        expect(intent.confidence, 0.0, reason: response);
        expect(intent.slots, isEmpty, reason: response);
        expect(intent.canRunUnconfirmed, isTrue);
        expect(
          intent.type.isMutating,
          isFalse,
          reason: 'an unknown intent may never become a mutating action',
        );
      }
    });

    test('S05-UT-02: an unknown intent is stripped of any slots it came '
        'with', () async {
      // A model that shrugs and still fills in an issue key must not leave
      // something the router could mistake for an action.
      final VoiceIntent intent = intentOf(
        await parserFor(
          '{"intent":"unknown","slots":{"issueKey":"PROJ-123"},'
          '"confidence":0.4}',
        ).parse(utterance),
      );

      expect(intent.type, IntentType.unknown);
      expect(intent.slots, isEmpty);
      expect(intent.confidence, 0.0);
    });

    test(
      'S05-UT-02: a missing confidence reads as 0, not as certainty',
      () async {
        final VoiceIntent intent = intentOf(
          await parserFor(
            '{"intent":"updateJira","slots":{"issueKey":"PROJ-123",'
            '"transition":"Done"}}',
          ).parse(utterance),
        );

        expect(intent.confidence, 0.0);
        expect(
          intent.canRunUnconfirmed,
          isFalse,
          reason: 'BR-04: an unstated confidence must not let a mutation pass',
        );
      },
    );
  });

  group('transport failures stay failures', () {
    test('a network failure is an Err, not an unknown intent', () async {
      final FakeAiEngine engine = FakeAiEngine()
        ..failWith = const NetworkFailure('cannot reach Claude');

      final Result<VoiceIntent> result = await IntentParser(
        engine: engine,
      ).parse(utterance);

      expect(result, isA<Err<VoiceIntent>>());
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('a missing key is an Err — the user goes to Settings, not to '
        'rephrasing', () async {
      final FakeAiEngine engine = FakeAiEngine()
        ..failWith = const MissingApiKeyFailure();

      final Result<VoiceIntent> result = await IntentParser(
        engine: engine,
      ).parse(utterance);

      expect(result.failureOrNull, isA<MissingApiKeyFailure>());
    });
  });

  group('the context reaches the engine', () {
    test('an empty utterance is unknown without spending a request', () async {
      final FakeAiEngine engine = FakeAiEngine();

      final VoiceIntent intent = intentOf(
        await IntentParser(engine: engine).parse('   '),
      );

      expect(intent.type, IntentType.unknown);
      expect(engine.intentCalls, isEmpty);
    });

    test('the follow-up context travels with the call', () async {
      final FakeAiEngine engine = FakeAiEngine()
        ..alwaysParseAs(
          '{"intent":"updateJira","slots":{"issueKey":"PROJ-123"},'
          '"confidence":0.9}',
        );

      const IntentContext context = IntentContext(
        locale: 'it',
        pendingIntent: IntentType.updateJira,
        providedSlots: <String, dynamic>{'transition': 'Done'},
      );
      final VoiceIntent intent = intentOf(
        await IntentParser(engine: engine).parse('PROJ-123', context: context),
      );

      expect(engine.intentCalls.single.context, context);
      // The established slot survives an answer that only carried the new one.
      expect(intent.slots, <String, dynamic>{
        'transition': 'Done',
        'issueKey': 'PROJ-123',
      });
      expect(intent.isComplete, isTrue);
    });
  });
}
