import 'dart:math' as math;

/// Case- and accent-insensitive substring matching.
///
/// Two features need exactly the same comparison and must not drift apart:
/// naming a task out loud (`docs/architecture.md` §6.3.1) and searching the
/// list (§4.1). A user who says "orcamento" means the task called "orçamento",
/// and a search box that disagreed with the voice command about which tasks
/// match would be two features with two opinions about the same string.
///
/// **Not a collator.** This folds the Latin-1 diacritics Portuguese and Italian
/// actually use, plus the two ligatures those languages borrow; it knows
/// nothing about Turkish dotless i or Greek final sigma. That is the honest
/// scope of the three languages the app supports (BR-11), and a wrong fold
/// outside them would be worse than no fold at all.
class TextMatch {
  const TextMatch._();

  /// `true` when [haystack] contains [needle], ignoring case and accents.
  ///
  /// A blank [needle] matches everything — an empty search box is not a filter
  /// (`TaskQuery.isUnfiltered` depends on this being the same answer).
  static bool contains(String haystack, String needle) {
    final String wanted = fold(needle);
    if (wanted.isEmpty) return true;
    return fold(haystack).contains(wanted);
  }

  /// [text] lowercased with its diacritics removed, trimmed.
  ///
  /// Exposed because the ambiguity rule of §6.3.1 has to count matches, and a
  /// caller that folded differently would count differently.
  static String fold(String text) {
    final StringBuffer folded = StringBuffer();
    for (final int rune in text.trim().toLowerCase().runes) {
      folded.write(_folded[rune] ?? String.fromCharCode(rune));
    }
    return folded.toString();
  }

  /// [text] folded, then stripped of every rune that is not a letter or a
  /// digit.
  ///
  /// Tier 3 of §6.3.1. People spell identifiers out loud with spaces a tracker
  /// does not write: `HEROBRAZIL-762` heard as "Hero Brazil-762" is not a
  /// mishearing, and both sides squash to `herobrazil762`. Because the answer
  /// is exact, no threshold is consulted and no scoring function can get it
  /// wrong.
  static String squash(String text) =>
      fold(text).replaceAll(_nonAlphanumeric, '');

  /// Every run of consecutive digits in [text], as written.
  ///
  /// **Digits are never approximate** (DEC-035). `herobrazil762` and
  /// `herobrazil763` differ by one character and score identically against
  /// `herobrasil762` under any edit-distance metric — one is the same chamado
  /// spelled differently and the other is a different chamado, and nothing in
  /// the score tells them apart. The caller compares these sets and excludes a
  /// candidate outright rather than trusting a number.
  static Set<String> digitRuns(String text) => <String>{
    for (final RegExpMatch run in _digitRun.allMatches(text)) run[0]!,
  };

  /// How alike [a] and [b] are, from `0.0` to `1.0`.
  ///
  /// Normalised Damerau–Levenshtein over [squash]: one minus the edit distance
  /// over the longer of the two lengths, so the same number of mistakes counts
  /// for more in a short reference than a long one. Transpositions cost one
  /// edit because "Samra" for "Samara" is one slip of a speaker or a
  /// transcriber, not two.
  ///
  /// Symmetric, `1.0` for identical input, `0.0` for input with nothing in
  /// common. Compared against [similarityThreshold] by the caller — this
  /// function has no opinion about what is close enough.
  static double similarity(String a, String b) {
    final String left = squash(a);
    final String right = squash(b);
    if (left == right) return 1.0;
    if (left.isEmpty || right.isEmpty) return 0.0;
    final int longest = math.max(left.length, right.length);
    final double score = 1.0 - _distance(left, right) / longest;
    return score < 0.0 ? 0.0 : score;
  }

  /// The score at or above which two spellings may be the same task.
  ///
  /// `herobrasil762` against `herobrazil762` scores 0.923; a two-character
  /// difference in a thirteen-character reference scores 0.846. A change here
  /// is a change to behaviour and needs S05b-UT-04 updated with it.
  static const double similarityThreshold = 0.82;

  /// How far the best approximate match must clear the runner-up.
  ///
  /// Below this gap the app asks instead of picking. A tie is a question.
  static const double similarityMargin = 0.08;

  /// The shortest reference, in squashed characters, that may be approximated.
  ///
  /// "PR" is not an approximation of anything, and a two-letter reference run
  /// through an edit-distance metric matches half the list.
  static const int minApproximateLength = 4;

  /// Damerau–Levenshtein (optimal string alignment) between two squashed
  /// strings.
  ///
  /// Two rolling rows plus the one before them, because the full matrix is
  /// `title × reference` allocations per candidate per command and the
  /// recurrence never looks further back than that.
  static int _distance(String a, String b) {
    final List<int> units = a.codeUnits;
    final List<int> other = b.codeUnits;
    List<int> beforePrevious = List<int>.filled(other.length + 1, 0);
    List<int> previous = List<int>.generate(other.length + 1, (int i) => i);
    List<int> current = List<int>.filled(other.length + 1, 0);

    for (int i = 1; i <= units.length; i++) {
      current[0] = i;
      for (int j = 1; j <= other.length; j++) {
        final int cost = units[i - 1] == other[j - 1] ? 0 : 1;
        int best = math.min(
          current[j - 1] + 1, // an insertion
          math.min(previous[j] + 1, previous[j - 1] + cost), // deletion, swap
        );
        if (i > 1 &&
            j > 1 &&
            units[i - 1] == other[j - 2] &&
            units[i - 2] == other[j - 1]) {
          best = math.min(best, beforePrevious[j - 2] + 1); // a transposition
        }
        current[j] = best;
      }
      final List<int> recycled = beforePrevious;
      beforePrevious = previous;
      previous = current;
      current = recycled;
    }
    return previous[other.length];
  }

  static final RegExp _nonAlphanumeric = RegExp(
    r'[^\p{L}\p{N}]',
    unicode: true,
  );
  static final RegExp _digitRun = RegExp(r'\d+');

  /// Lowercase accented rune → its unaccented spelling.
  ///
  /// A map rather than a normalisation pass because Dart's core library has no
  /// Unicode NFD, and pulling a package in for eight vowels would be a
  /// dependency the architecture never agreed to (§2.1).
  static const Map<int, String> _folded = <int, String>{
    0xE0: 'a', // à
    0xE1: 'a', // á
    0xE2: 'a', // â
    0xE3: 'a', // ã
    0xE4: 'a', // ä
    0xE5: 'a', // å
    0xE6: 'ae', // æ
    0xE7: 'c', // ç
    0xE8: 'e', // è
    0xE9: 'e', // é
    0xEA: 'e', // ê
    0xEB: 'e', // ë
    0xEC: 'i', // ì
    0xED: 'i', // í
    0xEE: 'i', // î
    0xEF: 'i', // ï
    0xF1: 'n', // ñ
    0xF2: 'o', // ò
    0xF3: 'o', // ó
    0xF4: 'o', // ô
    0xF5: 'o', // õ
    0xF6: 'o', // ö
    0xF8: 'o', // ø
    0xF9: 'u', // ù
    0xFA: 'u', // ú
    0xFB: 'u', // û
    0xFC: 'u', // ü
    0xFD: 'y', // ý
    0xFF: 'y', // ÿ
    0x153: 'oe', // œ
  };
}
