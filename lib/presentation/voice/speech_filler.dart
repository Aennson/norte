/// Recognises a committed segment that is nothing but hesitation.
///
/// The service is asked for `no_verbatim`, which should drop most of these
/// upstream. This is the belt to that pair of braces, and it earns its place:
/// a segment of pure hesitation that reaches the parser costs an API call, a
/// second or more of the user's time, and an answer of `unknown` that reads on
/// screen as the app failing to understand — when what actually happened is
/// that nothing was said.
///
/// **It only ever rejects a segment that is *entirely* filler.** "eh, cria
/// tarefa" is a command with a stumble in front of it, and dropping it would
/// be far worse than transcribing the stumble.
abstract final class SpeechFiller {
  /// Hesitations in the three supported languages, as a speaker draws them
  /// out: `eeeh`, `hmmm`, `aaah`. Matched after collapsing repeats, so the
  /// list stays short and the lengthening does not have to be enumerated.
  static const Set<String> sounds = <String>{
    // pt-BR
    'e', 'eh', 'ah', 'ahn', 'an', 'hm', 'hum', 'uhm', 'ne', 'ta',
    // en
    'uh', 'um', 'er', 'mm', 'hmm', 'ehm', 'like', 'so',
    // it
    'boh', 'mah', 'cioe', 'ecco',
  };

  /// `true` when [text] is only hesitation and punctuation.
  static bool isOnlyFiller(String text) {
    final List<String> words = _words(text);
    if (words.isEmpty) return true;
    return words.every(sounds.contains);
  }

  /// [text] split into comparable words: lowercased, unaccented, stripped of
  /// punctuation, and with runs of a repeated letter collapsed — so `eeeeh`
  /// and `eh` are the same word, which is the whole point.
  static List<String> _words(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z\s]'), ' ')
      .split(RegExp(r'\s+'))
      .map(_collapse)
      .where((String word) => word.isNotEmpty)
      .toList();

  /// `eeeeh` becomes `eh`, `hmmm` becomes `hm`.
  static String _collapse(String word) {
    final StringBuffer out = StringBuffer();
    String? previous;
    for (final String letter in word.split('')) {
      if (letter != previous) out.write(letter);
      previous = letter;
    }
    return out.toString();
  }
}
