import '../../domain/entities/intent_context.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/ai_engine.dart';

/// Turns committed speech into a [VoiceIntent] (`docs/architecture.md` §6.1).
///
/// A thin layer over [AiEngine.parseIntent], and thin on purpose: the schema
/// and the prompt belong to the shared codec in `infrastructure/`, so every
/// adapter answers the same shape. What lives here is the one decision the
/// application layer owns — **what an unreadable answer means**.
///
/// It means `IntentType.unknown`, and nothing else. Not a crash, not a
/// half-filled intent, and above all not an action: the UI asks the user to
/// rephrase (`sprint-05` validation rules). Confidence comes back as `0.0`,
/// so even a caller that ignored the type could not slip the result past BR-04.
///
/// **A transport failure is not an unknown intent.** No network, a rejected
/// key, a rate limit — those come back as [Err], because "I could not ask"
/// and "I asked and understood nothing" send the user to different places, and
/// only one of them is Settings. Collapsing the two would have the app
/// blaming the user's phrasing for its own missing API key.
class IntentParser {
  const IntentParser({required this.engine});

  final AiEngine engine;

  /// Parses [utterance], optionally within [context].
  Future<Result<VoiceIntent>> parse(
    String utterance, {
    IntentContext context = const IntentContext(),
  }) async {
    final String spoken = utterance.trim();
    if (spoken.isEmpty) {
      // Nothing was said. Asking the engine would spend a request to be told
      // so, and the answer is already known.
      return const Ok<VoiceIntent>(VoiceIntent(type: IntentType.unknown));
    }

    try {
      final VoiceIntent intent = await engine.parseIntent(spoken, context);
      return Ok<VoiceIntent>(intent);
    } on AiResponseFailure {
      return const Ok<VoiceIntent>(VoiceIntent(type: IntentType.unknown));
    } on Failure catch (failure) {
      return Err<VoiceIntent>(failure);
    }
  }
}
