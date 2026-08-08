/// Removes Brazilian personal data from text before it leaves the machine.
///
/// **BR-07** — CPF, phone numbers and e-mail addresses are redacted before any
/// external API sees a transcript. The rule may be relaxed only when
/// `AiEngine.capabilities.isLocal == true`, and that decision belongs to
/// `SummarizeMeeting`, not here: this class always redacts, so there is no
/// configuration of it that quietly does nothing.
///
/// **What it is not.** This is a regex pass, not a classifier. It is deliberate
/// about the two ways that can go wrong:
///
/// * *Missing something* is the dangerous direction, so the patterns are
///   generous — an eleven-digit run in a transcript is treated as a CPF even
///   without punctuation.
/// * *Over-matching* is the annoying direction, and the fixtures that
///   surround real data in a meeting transcript are protected explicitly:
///   dates (`2026-08-08`, `08/08/2026`), issue keys (`PROJ-123`) and version
///   numbers (`1.2.3`) survive untouched, because a summary that has lost its
///   ticket references is not a summary of that meeting (S03-UT-01).
///
/// **One ambiguity is real and is not papered over.** A bare eleven-digit
/// number can be a CPF or a mobile number; Brazil gives them the same length.
/// The classifier here is the mobile format — two-digit area code followed by
/// the mandatory `9` — so `11987654321` reads as a phone and `12345678909`
/// reads as a CPF. A CPF whose third digit happens to be `9` will be labelled
/// `[PHONE]`. That is a wrong label on redacted data, never a leak: both
/// patterns are removed, and only the placeholder differs.
class PiiRedactor {
  const PiiRedactor();

  /// Placeholder left where a CPF was.
  static const String cpfMask = '[CPF]';

  /// Placeholder left where a phone number was.
  static const String phoneMask = '[PHONE]';

  /// Placeholder left where an e-mail address was.
  static const String emailMask = '[EMAIL]';

  /// An e-mail address.
  ///
  /// Runs first: an address can contain digit runs in its local part, and
  /// redacting it whole avoids leaving `[CPF]@example.com` behind.
  static final RegExp email = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*\.[A-Za-z]{2,}',
  );

  /// A punctuated CPF: `123.456.789-09`.
  ///
  /// Unambiguous, so it is matched before the phone patterns get a chance.
  static final RegExp formattedCpf = RegExp(
    r'(?<![\dA-Za-z])\d{3}\.\d{3}\.\d{3}-\d{2}(?![\dA-Za-z])',
  );

  /// A phone number in any of the forms a Brazilian writes one.
  ///
  /// Mobile first — the `9` after the area code is mandatory in Brazil and is
  /// what distinguishes eleven bare digits from a CPF. The landline branch
  /// requires punctuation or a country code, so ten unadorned digits (an
  /// order number, a row count) are left alone.
  static final RegExp phone = RegExp(
    r'(?<![\dA-Za-z])'
    r'(?:'
    // Mobile: optional +55, area code with or without parentheses, then the
    // 9 and eight digits, separated however the writer felt like.
    r'(?:\+55[\s.-]?)?(?:\(\d{2}\)|\d{2})[\s.-]?9[\s.-]?\d{4}[\s.-]?\d{4}'
    r'|'
    // Landline: only when punctuated or country-coded.
    r'(?:\+55[\s.-]?)?(?:\(\d{2}\)[\s.-]?|\d{2}[\s.-])\d{4}[\s.-]?\d{4}'
    r')'
    r'(?![\dA-Za-z])',
  );

  /// Eleven bare digits — a CPF that was typed without punctuation.
  ///
  /// Runs after [phone], so anything shaped like a mobile has already gone.
  static final RegExp bareCpf = RegExp(r'(?<![\dA-Za-z])\d{11}(?![\dA-Za-z])');

  /// [text] with every recognised piece of personal data replaced by its
  /// placeholder. The rest of the text — spacing, punctuation, ticket keys,
  /// dates — is returned byte for byte.
  String redact(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(email, emailMask)
        .replaceAll(formattedCpf, cpfMask)
        .replaceAll(phone, phoneMask)
        .replaceAll(bareCpf, cpfMask);
  }

  /// `true` when [text] still contains something [redact] would remove.
  ///
  /// Used by the tests as an independent check on the pass, and by
  /// `SummarizeMeeting` to log *that* a redaction happened without logging
  /// what was redacted (`docs/architecture.md` §10).
  bool containsPii(String text) =>
      email.hasMatch(text) ||
      formattedCpf.hasMatch(text) ||
      phone.hasMatch(text) ||
      bareCpf.hasMatch(text);
}
