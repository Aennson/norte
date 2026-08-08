import 'dart:async';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/entities/transcript.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/audio_store.dart';
import '../../domain/ports/transcription_engine.dart';
import 'summarize_meeting.dart';

/// Where a recording-to-summary run has got to.
///
/// Four stages rather than a spinner, because they fail differently and take
/// wildly different amounts of time: uploading is the user's network,
/// transcribing is minutes on a long meeting, summarizing is the AI engine.
/// A user watching a ninety-minute upload needs to know it is the upload.
enum TranscriptionStage { uploading, transcribing, summarizing, done }

/// Turns a finished recording into a summarized [Meeting]
/// (`docs/architecture.md` §5.1).
///
/// **It duplicates nothing from Sprint 03.** The transcript this produces goes
/// into the same [SummarizeMeeting] the pasted-transcript flow uses, so BR-03
/// and BR-07 are obeyed here because they are obeyed there — the redactor runs
/// before the engine and this use case persists nothing (S04-UT-01). A second
/// summarization path would have been a second place for those rules to be
/// got wrong.
///
/// **The audio outlives a failure.** Deletion happens on exactly two events:
/// a successful run, and the user discarding. Anything else leaves the file
/// where it is, which is what makes "try again" mean *try again* rather than
/// *say it all again* (S04-UT-02, S04-UT-03).
class TranscribeMeetingAudio {
  const TranscribeMeetingAudio({
    required this.engine,
    required this.store,
    required this.summarize,
  });

  final BatchTranscription engine;
  final AudioStore store;

  /// Sprint 03's use case, held rather than reimplemented.
  final SummarizeMeeting summarize;

  /// Transcribes the recording at [audioPath] and summarizes it under
  /// [template].
  ///
  /// [onStage] is called as the run moves through [TranscriptionStage]; the
  /// screen renders from it. [language] is a hint for the engine, and
  /// [retention] is the user's BR-03 choice, made before recording started.
  Future<Result<Meeting>> call({
    required String audioPath,
    required MeetingTemplate template,
    required String title,
    String? language,
    RetentionPolicy retention = RetentionPolicy.ephemeral,
    void Function(TranscriptionStage stage)? onStage,
  }) async {
    // Uploading and transcribing are one call to the engine — the upload is
    // what the progress stream measures, and the service starts work when the
    // last byte lands. Announcing both is honest about a boundary the caller
    // can see on the progress bar even though it cannot be awaited separately.
    onStage?.call(TranscriptionStage.uploading);

    final Transcript transcript;
    try {
      onStage?.call(TranscriptionStage.transcribing);
      transcript = await engine.transcribeFile(audioPath, language: language);
    } on Failure catch (failure) {
      // The file stays. This is the whole rule.
      return Err<Meeting>(failure);
    }

    onStage?.call(TranscriptionStage.summarizing);
    final Result<Meeting> result = await summarize(
      transcript: transcript.text,
      template: template,
      title: title,
      retention: retention,
    );

    // A summarize that failed also keeps the audio: the transcription was the
    // expensive half and re-running it to recover from an AI hiccup would
    // charge the user twice for one meeting.
    if (result case Err<Meeting>()) return result;

    await _discardQuietly(audioPath);
    onStage?.call(TranscriptionStage.done);
    return result;
  }

  /// Deletes the recording the user chose not to transcribe.
  ///
  /// Same deletion as the successful path, reached from the other direction,
  /// so there is one implementation of "the audio is gone" rather than two
  /// that can drift (S04-UT-03).
  Future<void> discard(String audioPath) => _discardQuietly(audioPath);

  /// Deletes without letting a storage error mask the outcome that matters.
  ///
  /// A summary the user is about to read must not be turned into an error
  /// because the temp file could not be unlinked — the file is in a directory
  /// the platform clears anyway, and the summary is the thing they asked for.
  Future<void> _discardQuietly(String audioPath) async {
    try {
      await store.delete(audioPath);
    } on Failure {
      // Deliberately swallowed; see above.
    }
  }
}
