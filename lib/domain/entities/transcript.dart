/// The text a transcription engine produced from audio
/// (`docs/architecture.md` §9.1).
///
/// A value, not a record of anything: nothing here is persisted. BR-03 governs
/// a transcript produced from a recording exactly as it governs one the user
/// pasted — it reaches storage only when the user asked for it to, and it
/// reaches an engine only after the redactor has run (BR-07). The entity
/// therefore carries no id and no timestamps; it is input to
/// `SummarizeMeeting` and nothing more.
class Transcript {
  const Transcript({required this.text, required this.language});

  /// What was said.
  final String text;

  /// The language the engine reports it was said in, as a BCP-47 code.
  ///
  /// The engine's answer, not the caller's request: Whisper detects the
  /// language when none is given, and a caller that asked for `pt` on audio
  /// that turned out to be English needs to know that rather than be told
  /// what it already asked for.
  final String language;

  @override
  bool operator ==(Object other) =>
      other is Transcript && other.text == text && other.language == language;

  @override
  int get hashCode => Object.hash(text, language);

  @override
  String toString() => 'Transcript($language, ${text.length} chars)';
}
