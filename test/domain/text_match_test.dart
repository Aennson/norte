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

  // S05b-UT-09 — the three functions tiers 3 and 4 are built from, tested on
  // their own so that a router test failing is unambiguous about which layer
  // is wrong.
  group('S05b-UT-09 TextMatch.squash', () {
    test('drops every rune that is not a letter or a digit', () {
      expect(TextMatch.squash('Hero Brazil-762'), 'herobrazil762');
      expect(TextMatch.squash('HEROBRAZIL-762'), 'herobrazil762');
      expect(TextMatch.squash('Hero-Brazil-762'), 'herobrazil762');
      expect(TextMatch.squash('  hero brazil 762  '), 'herobrazil762');
    });

    test('folds first, so the accents fold handles survive squashing', () {
      expect(TextMatch.squash('Confirmar o orçamento'), 'confirmaroorcamento');
      expect(TextMatch.squash("Attività è già"), 'attivitaegia');
    });

    test('text with nothing to drop squashes to its fold', () {
      expect(TextMatch.squash('ligarparasamara'), 'ligarparasamara');
      expect(TextMatch.squash(''), '');
      expect(TextMatch.squash('---'), '');
    });
  });

  group('S05b-UT-09 TextMatch.digitRuns', () {
    test('a run is consecutive digits, as written', () {
      expect(TextMatch.digitRuns('HEROBRAZIL-762'), <String>{'762'});
      expect(TextMatch.digitRuns('PROJ-12 e PROJ-345'), <String>{'12', '345'});
    });

    test('text with no digits has no runs', () {
      expect(TextMatch.digitRuns('Ligar para Samara'), isEmpty);
      expect(TextMatch.digitRuns(''), isEmpty);
    });

    test('the same run written twice is one run — it is a set', () {
      expect(TextMatch.digitRuns('762 e 762'), <String>{'762'});
    });
  });

  group('S05b-UT-09 TextMatch.similarity', () {
    test('identical input scores 1.0, however it is spelled', () {
      expect(TextMatch.similarity('HEROBRAZIL-762', 'hero brazil 762'), 1.0);
      expect(TextMatch.similarity('Ligar para Samara', 'ligarparasamara'), 1.0);
    });

    test('disjoint input scores 0.0', () {
      expect(TextMatch.similarity('abc', 'xyz'), 0.0);
      expect(TextMatch.similarity('abc', 'wxyz'), 0.0);
      expect(TextMatch.similarity('anything', ''), 0.0);
    });

    test('it is symmetric', () {
      const String a = 'Hero Brasil-762';
      const String b = 'HEROBRAZIL-762';
      expect(TextMatch.similarity(a, b), TextMatch.similarity(b, a));
      expect(
        TextMatch.similarity('Revisar o conector', 'revisar o conetor'),
        TextMatch.similarity('revisar o conetor', 'Revisar o conector'),
      );
    });

    test('the two scores the thresholds were chosen from', () {
      // One character in thirteen, which must clear similarityThreshold.
      expect(
        TextMatch.similarity('HEROBRAZIL-762', 'Hero Brasil-762'),
        closeTo(0.923, 0.001),
      );
      // Two characters in thirteen, which must still clear it — the threshold
      // sits below both on purpose (`docs/sprints/sprint-05b` Parameters).
      expect(
        TextMatch.similarity('HEROBRAZIL-762', 'Hero Brasul-762'),
        closeTo(0.846, 0.001),
      );
      expect(
        TextMatch.similarity('HEROBRAZIL-762', 'Hero Brasil-762'),
        greaterThanOrEqualTo(TextMatch.similarityThreshold),
      );
    });

    test('a transposition costs one edit, not two', () {
      // "Samra" for "Samara" is one slip, and scoring it as two would put it
      // below the threshold that a single misheard letter clears.
      expect(
        TextMatch.similarity('Ligar para Samara', 'Ligar para Samaar'),
        closeTo(1 - 1 / 15, 0.001),
      );
    });
  });
}
