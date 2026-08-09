import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/services/text_match.dart';

/// S05a-UT-03 and S05a-UT-09 share this comparison — naming a task out loud
/// (`docs/architecture.md` §6.3.1) and searching the list (§4.1) must agree
/// about which tasks match, so the rule is tested once, here.
void main() {
  group('TextMatch.fold', () {
    test('lowercases, trims, and strips the accents the three languages '
        'use', () {
      expect(TextMatch.fold('  Orçamento  '), 'orcamento');
      expect(TextMatch.fold('SAMÁRA'), 'samara');
      expect(TextMatch.fold('Ação Não Está'), 'acao nao esta');
      expect(TextMatch.fold("Attività è già"), 'attivita e gia');
    });

    test('leaves text with nothing to fold byte for byte', () {
      expect(TextMatch.fold('revisar pr'), 'revisar pr');
    });

    test('folds the two ligatures Portuguese and Italian borrow', () {
      expect(TextMatch.fold('cœur'), 'coeur');
      expect(TextMatch.fold('æther'), 'aether');
    });
  });

  group('TextMatch.contains', () {
    test('ignores case and accents in both directions', () {
      expect(TextMatch.contains('Ligar para Samara', 'samára'), isTrue);
      expect(TextMatch.contains('Confirmar o orçamento', 'ORCAMENTO'), isTrue);
    });

    test('a blank needle matches everything — an empty box is not a '
        'filter', () {
      expect(TextMatch.contains('anything', ''), isTrue);
      expect(TextMatch.contains('anything', '   '), isTrue);
    });

    test('an empty haystack matches only a blank needle', () {
      expect(TextMatch.contains('', 'x'), isFalse);
      expect(TextMatch.contains('', ''), isTrue);
    });

    test('it is containment, not equality', () {
      expect(TextMatch.contains('Ligar para Samara de novo', 'samara'), isTrue);
      expect(TextMatch.contains('Samara', 'Ligar para Samara'), isFalse);
    });
  });
}
