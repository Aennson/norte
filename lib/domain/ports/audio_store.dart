/// Where meeting audio lives while it is being transcribed, and nowhere else.
///
/// **This port exists to make one rule enforceable in one place**
/// (`sprint-04` validation rules): a meeting recording is temporary. It is
/// written to the app's temp directory, it is deleted once transcription
/// succeeds or once the user discards it, and it never reaches the documents
/// directory where the database and the user's own files live.
///
/// Splitting it from `AudioRecorder` is deliberate. The recorder captures; the
/// store owns the lifecycle. A use case that must delete a file after a
/// successful transcription should not have to hold a microphone to do it, and
/// the adapter that decides *which directory* is the one the rule is about.
///
/// **Contract**
/// * [newRecordingPath] returns a path inside the temp directory that no
///   existing recording occupies. It creates the directory if needed but does
///   **not** create the file.
/// * [delete] on a path that does not exist is a **no-op, not an error** — the
///   cleanup paths call it after failures where the file may already be gone,
///   and a store that threw would turn tidying up into a second failure.
/// * [list] returns every recording the store is holding, which is what lets a
///   test assert the directory is empty and what lets a later sprint sweep up
///   files a crash left behind.
/// * Failures surface as `StorageFailure`.
abstract interface class AudioStore {
  /// A fresh path in the temp directory for a recording about to start.
  Future<String> newRecordingPath();

  /// Whether a recording exists at [path].
  Future<bool> exists(String path);

  /// Deletes the recording at [path]. Silent when there is nothing there.
  Future<void> delete(String path);

  /// Every recording currently held.
  Future<List<String>> list();
}
