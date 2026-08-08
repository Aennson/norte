import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Golden files are stored per operating system.
///
/// Flutter rasterises text through the host OS font stack, so the same widget
/// tree produces slightly different pixels on Linux, Windows and macOS — around
/// 1% of them, with the layout unchanged. A single shared `.png` can therefore
/// only ever match on one platform.
///
/// Instead of tolerating a diff (which would contradict S00-GT-01's "pass with
/// no diff") or skipping the tests elsewhere, each platform keeps its own set:
///
/// ```
/// test/presentation/goldens/images/
///   linux/    <- generated on Linux, what CI compares against
///   windows/  <- generated on Windows
///   macos/    <- generated on macOS
/// ```
///
/// Every platform runs every golden test, comparing against its own files, with
/// no tolerance. See DEC-006.
///
/// Call [usePlatformGoldens] from `setUpAll` in any golden test.
void usePlatformGoldens() {
  final GoldenFileComparator current = goldenFileComparator;
  if (current is _PlatformGoldenComparator) return;
  if (current is! LocalFileComparator) return;
  goldenFileComparator = _PlatformGoldenComparator(
    current.basedir.resolve('platform_goldens_anchor_test.dart'),
  );
}

/// Directory name for the running platform, e.g. `linux`, `windows`, `macos`.
String get goldenPlatformDirectory => Platform.operatingSystem;

class _PlatformGoldenComparator extends LocalFileComparator {
  _PlatformGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final Uri key = _platformKey(golden);
    try {
      return await super.compare(imageBytes, key);
    } on TestFailure catch (error) {
      // The most likely cause on a platform whose set has not been generated
      // yet is a missing file — say so, instead of leaving the reader to guess.
      if (error.message?.contains('non-existent') ?? false) {
        throw TestFailure(
          'Golden "$key" does not exist yet.\n'
          'This platform ($goldenPlatformDirectory) has no golden set. '
          'Generate it once with:\n'
          '  flutter test --update-goldens\n'
          'then commit the files under '
          'test/presentation/goldens/images/$goldenPlatformDirectory/.\n'
          'Never regenerate another platform\'s directory.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      super.update(_platformKey(golden), imageBytes);

  /// Rewrites `images/foo.png` into `images/<platform>/foo.png`.
  Uri _platformKey(Uri golden) {
    final String key = golden.path;
    final int separator = key.lastIndexOf('/');
    final String directory = separator == -1
        ? ''
        : key.substring(0, separator + 1);
    final String file = separator == -1 ? key : key.substring(separator + 1);
    return Uri.parse('$directory$goldenPlatformDirectory/$file');
  }
}
