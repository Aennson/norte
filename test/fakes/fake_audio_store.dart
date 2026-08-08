import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/audio_store.dart';

/// In-memory [AudioStore] (`docs/testing-strategy.md` §3).
///
/// The [files] set **is** the temp directory: a path is in it or the file does
/// not exist. That is what lets S04-UT-03 assert "no audio file remains in the
/// directory" as a fact about the store rather than as a hopeful check of a
/// real filesystem the test would then have to clean up.
class FakeAudioStore implements AudioStore {
  FakeAudioStore({Set<String>? files, this.directory = '/tmp/norte_recordings'})
    : files = files ?? <String>{};

  /// Every recording the store is holding.
  final Set<String> files;

  /// Directory new paths are minted in.
  final String directory;

  /// Paths handed to [delete], in call order — including ones that were not
  /// there, because "tried to delete" and "deleted" are different assertions.
  final List<String> deleted = <String>[];

  /// When set, every operation throws it.
  Failure? failWith;

  int _next = 0;

  @override
  Future<String> newRecordingPath() async {
    _throwIfProgrammed();
    _next++;
    return '$directory/meeting_$_next.m4a';
  }

  @override
  Future<bool> exists(String path) async {
    _throwIfProgrammed();
    return files.contains(path);
  }

  @override
  Future<void> delete(String path) async {
    _throwIfProgrammed();
    deleted.add(path);
    // Deleting what is not there is a no-op, as the port requires.
    files.remove(path);
  }

  @override
  Future<List<String>> list() async {
    _throwIfProgrammed();
    return files.toList()..sort();
  }

  /// Records that a recording was written at [path].
  void add(String path) => files.add(path);

  void _throwIfProgrammed() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }
}
