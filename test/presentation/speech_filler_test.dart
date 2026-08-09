import 'package:flutter_test/flutter_test.dart';
import 'package:norte/presentation/voice/speech_filler.dart';

/// Hesitation is not a command (`sprint-05`, reported by the Developer).
///
/// Not a documented sprint case — added under `docs/project-rules.md` §5.4.
/// The asymmetry is the whole design: dropping a segment that is *only*
/// hesitation costs nothing, and dropping one that merely *starts* with
/// hesitation loses a command the user did give.
void main() {
  group('rejected — nothing was said', () {
    test('drawn-out hesitations in the three languages', () {
      for (final String sound in <String>[
        'eeeeh',
        'ahn',
        'aaaah',
        'hmmm',
        'uhm',
        'eh...',
        'Hmm, hmm',
        'uh um',
        'boh',
      ]) {
        expect(SpeechFiller.isOnlyFiller(sound), isTrue, reason: sound);
      }
    });

    test('punctuation and whitespace alone', () {
      expect(SpeechFiller.isOnlyFiller('...'), isTrue);
      expect(SpeechFiller.isOnlyFiller('   '), isTrue);
    });
  });

  group('kept — a command with a stumble in front of it', () {
    test('hesitation before a real command is not filler', () {
      // The case that matters. Dropping this would lose a command the user
      // gave, to save an API call on a word they did not mean.
      for (final String spoken in <String>[
        'eh, cria tarefa revisar o PR',
        'hmm muda o PROJ-123 pra concluído',
        'aaah como tá o PROJ-99?',
      ]) {
        expect(SpeechFiller.isOnlyFiller(spoken), isFalse, reason: spoken);
      }
    });

    test('a short real word is not mistaken for hesitation', () {
      for (final String spoken in <String>['sim', 'não', 'ok', 'PROJ-123']) {
        expect(SpeechFiller.isOnlyFiller(spoken), isFalse, reason: spoken);
      }
    });
  });
}
