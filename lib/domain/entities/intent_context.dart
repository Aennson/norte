import 'package:freezed_annotation/freezed_annotation.dart';

import 'voice_intent.dart';

part 'intent_context.freezed.dart';

/// What the parser is told about the user's situation alongside the utterance
/// (`docs/architecture.md` §7.1).
///
/// It exists for two jobs, and deliberately for no more than two.
///
/// The first is **the second pass**. When an intent arrives with a slot
/// missing, the app asks for exactly that slot ("Which ticket?") and re-parses
/// the answer. On its own, "PROJ-123" is not a command; carried back with
/// [pendingIntent] and [providedSlots], it completes one. Without this the
/// second pass would have to re-send the original utterance glued to the
/// answer, and a model would be free to reinterpret the whole thing.
///
/// The second is **grounding**. [knownIssueKeys] are the keys the user actually
/// has linked, so a transcript that heard "proj cento e vinte e três" has
/// something to land on, and [locale] tells the model which of the three
/// supported languages it is reading (BR-11).
///
/// Nothing here is sent as part of the cached system prompt — it varies per
/// call, and a varying prefix would cost the cache on every request
/// (`docs/architecture.md` §7.2).
@freezed
abstract class IntentContext with _$IntentContext {
  const factory IntentContext({
    /// BCP-47 tag of the language the utterance is in: `pt-BR`, `en`, or `it`.
    @Default('pt-BR') String locale,

    /// Issue keys the user has linked locally, as grounding for the model.
    ///
    /// A hint, never a restriction: a user may name an issue they have not
    /// linked yet, and the parser must still hear it.
    @Default(<String>[]) List<String> knownIssueKeys,

    /// The intent being completed, when this is the second pass of a
    /// missing-slot exchange.
    IntentType? pendingIntent,

    /// Slots already established in that exchange, which the new answer adds
    /// to rather than replaces.
    @Default(<String, dynamic>{}) Map<String, dynamic> providedSlots,
  }) = _IntentContext;

  const IntentContext._();

  /// `true` when this call is completing an earlier intent rather than
  /// starting a new one.
  bool get isFollowUp => pendingIntent != null;
}
