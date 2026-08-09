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
