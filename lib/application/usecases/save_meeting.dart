import '../../domain/entities/meeting.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/meeting_repository.dart';

/// Persists a summarized meeting — the user's explicit "save" action.
///
/// **BR-03 is enforced here and nowhere else on the write path.** The meeting
/// goes to storage through `Meeting.forStorage`, which strips the transcript
/// unless the user opted into keeping it *before* the text was processed. An
/// ephemeral meeting therefore reaches Drift with an empty `rawTranscript`
/// however it got here, and the summary — the part the user asked to keep —
/// is what survives (S03-UT-04).
///
/// The stripping is not the adapter's job on purpose: a rule enforced in the
/// use case is provable without a database, and a second adapter cannot be the
/// place it is forgotten.
class SaveMeeting {
  const SaveMeeting({required this.repository});

  final MeetingRepository repository;

  /// Stores [meeting] and returns what was actually written.
  ///
  /// Returning the stored form rather than the argument is deliberate: the
  /// caller holds the object the database holds, so a screen cannot go on
  /// displaying a transcript the app has committed to forgetting.
  Future<Result<Meeting>> call(Meeting meeting) async {
    if (meeting.summary == null) {
      return const Err<Meeting>(
        ValidationFailure('a meeting is saved once it has a summary'),
      );
    }

    final Meeting stored = meeting.forStorage;
    try {
      await repository.save(stored);
    } on Failure catch (failure) {
      return Err<Meeting>(failure);
    }
    return Ok<Meeting>(stored);
  }
}

/// Forgets a meeting entirely.
///
/// The counterpart to leaving the result screen without saving: that discards
/// an in-memory transcript, this removes one the user had chosen to keep.
class DeleteMeeting {
  const DeleteMeeting({required this.repository});

  final MeetingRepository repository;

  /// Removes the meeting with [id]. Deleting an unknown id succeeds.
  ///
  /// Tasks converted from its action items are **not** removed: they are the
  /// user's work now, and a follow-up does not stop being owed because the
  /// notes were tidied away.
  Future<Result<void>> call(String id) async {
    try {
      await repository.delete(id);
    } on Failure catch (failure) {
      return Err<void>(failure);
    }
    return const Ok<void>(null);
  }
}
