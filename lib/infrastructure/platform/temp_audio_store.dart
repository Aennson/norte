import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/failures/failure.dart';
import '../../domain/ports/audio_store.dart';

/// [AudioStore] over the platform's temp directory.
///
/// **This class is where "meeting audio is temporary" is true or false**
/// (`sprint-04` validation rules). It resolves exactly one directory —
/// `getTemporaryDirectory()/norte_recordings` — and every path it hands out is
/// inside it. `getApplicationDocumentsDirectory`, where Drift keeps the
/// database and where the operating system's backup agents look, is not
/// referenced anywhere in this file, which is the strongest form the rule can
/// take: not a check that can be forgotten, but an address that was never
/// written down.
///
/// The directory matters for a second reason. A recording that outlived a
/// crash is still on disk, and [list] is what lets it be found; the platform
/// clears temp directories under pressure, so worst case it goes away by
/// itself rather than accumulating meetings the user believes were discarded.
class TempAudioStore implements AudioStore {
  TempAudioStore({Future<Directory> Function()? temporaryDirectory})
    : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  /// Injected so the tests can point the store at a directory they own; in the
  /// app it is always `path_provider`'s.
  final Future<Directory> Function() _temporaryDirectory;

  /// Subdirectory recordings live in, so that [list] can never return a
  /// temporary file some other part of the system left lying around.
  static const String directoryName = 'norte_recordings';

  /// Container format. AAC in an MP4 container: accepted by the Whisper API,
  /// hardware-encoded on both mobile platforms, and small enough that a
  /// ninety-minute meeting is a few tens of megabytes rather than a gigabyte
  /// of WAV.
  static const String fileExtension = 'm4a';

  @override
  Future<String> newRecordingPath() async {
    final Directory dir = await _directory();
    // The clock is not injected here on purpose: this is a filename, not a
    // domain timestamp, and nothing reads it back. Uniqueness is what it owes
    // the caller, and the microsecond stamp plus the existence check below
    // give it that even for two recordings started in the same millisecond.
    final int stamp = DateTime.now().microsecondsSinceEpoch;
    String candidate = p.join(dir.path, 'meeting_$stamp.$fileExtension');
    int suffix = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(dir.path, 'meeting_${stamp}_$suffix.$fileExtension');
      suffix++;
    }
    return candidate;
  }

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<void> delete(String path) async {
    try {
      final File file = File(path);
      // Deleting what is already gone is the ordinary case after a failure,
      // not an error: the contract says so, because every cleanup path calls
      // this and a store that threw would turn tidying up into a second
      // failure the user has to be told about.
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      throw const StorageFailure('the recording could not be deleted');
    }
  }

  @override
  Future<List<String>> list() async {
    try {
      final Directory dir = await _directory();
      final List<String> paths = <String>[
        for (final FileSystemEntity entity in dir.listSync())
          if (entity is File && p.extension(entity.path) == '.$fileExtension')
            entity.path,
      ];
      paths.sort();
      return paths;
    } on FileSystemException {
      throw const StorageFailure('the recordings could not be listed');
    }
  }

  Future<Directory> _directory() async {
    try {
      final Directory dir = Directory(
        p.join((await _temporaryDirectory()).path, directoryName),
      );
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } on FileSystemException {
      throw const StorageFailure('the recordings directory is unavailable');
    }
  }
}
