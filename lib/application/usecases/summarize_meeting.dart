import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/ai_engine.dart';
import '../../domain/ports/clock.dart';
import '../../domain/ports/id_generator.dart';
import '../../domain/services/pii_redactor.dart';

/// Turns a pasted transcript into a reviewed [MeetingSummary]
/// (`docs/architecture.md` §5.2).
///
/// **BR-07 lives here, not in the adapters.** The redactor runs before the
/// engine sees a single character, and it runs whenever
/// `engine.capabilities.isLocal == false` — which is every remote engine that
/// exists or will exist. Putting the rule in the use case means an adapter
/// written in a later sprint inherits it rather than having to remember it
/// (S03-UT-02).
///
/// **BR-03 lives here too, by omission.** This use case persists nothing. It
/// returns a [Meeting] held in memory; only `SaveMeeting` writes, and only
/// what retention allows. A summarize that failed therefore cannot have left
/// anything behind (S03-UT-06 scenario B).
class SummarizeMeeting {
  const SummarizeMeeting({
    required this.engine,
    required this.clock,
    required this.idGenerator,
    this.redactor = const PiiRedactor(),
  });

  final AiEngine engine;
  final Clock clock;
  final IdGenerator idGenerator;
  final PiiRedactor redactor;

  /// How many times the engine is asked in total when its answer cannot be
  /// read.
  ///
  /// Two: one retry, as the sprint's error policy requires. A model that
  /// returned prose instead of a summary usually returns a summary when asked
  /// again, and a model that is going to keep doing it will not be talked
  /// round by a third attempt — it will just spend the user's money and their
  /// patience (S03-UT-06).
  static const int maxAttempts = 2;

  /// Summarizes [transcript] under [template].
  ///
  /// Returns an unsaved [Meeting] carrying the summary. [retention] is
  /// recorded on it so that whatever saves it later cannot get BR-03 wrong;
  /// the choice is the user's and is made **before** processing, which is the
  /// only point at which it is an informed one.
  Future<Result<Meeting>> call({
    required String transcript,
    required MeetingTemplate template,
    required String title,
    RetentionPolicy retention = RetentionPolicy.ephemeral,
  }) async {
    final String trimmed = transcript.trim();
    if (trimmed.isEmpty) {
      return const Err<Meeting>(
        ValidationFailure('paste a transcript first', 'transcript'),
      );
    }

    // The screen pre-fills this from the template's localized name, so a blank
    // one means the user cleared it. Naming the meeting here instead would put
    // an English literal into stored data on a pt-BR device (BR-11).
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return const Err<Meeting>(
        ValidationFailure('the meeting needs a title', 'title'),
      );
    }

    // BR-07. A local engine keeps the machine's data on the machine, which is
    // the one condition under which the rule permits the raw text through.
    final String prepared = engine.capabilities.isLocal
        ? trimmed
        : redactor.redact(trimmed);

    Failure? lastFailure;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final MeetingSummary summary = await engine.summarize(
          prepared,
          template,
        );
        return Ok<Meeting>(
          Meeting(
            id: idGenerator.newId(),
            title: trimmedTitle,
            createdAt: clock.now().toUtc(),
            type: template.type,
            rawTranscript: trimmed,
            summary: summary,
            retention: retention,
          ),
        );
      } on AiResponseFailure catch (failure) {
        // The only failure worth repeating: the request was fine and the
        // answer was not. A rejected key or an exhausted quota will be
        // rejected and exhausted a second time too.
        lastFailure = failure;
      } on Failure catch (failure) {
        return Err<Meeting>(failure);
      }
    }

    return Err<Meeting>(lastFailure ?? const AiResponseFailure());
  }
}
