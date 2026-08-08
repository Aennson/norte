import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'norte_database.dart';

/// Opens the on-disk database the app uses.
///
/// The file lives in the platform's application-support directory, so tasks
/// survive a restart on Android, iOS and Windows alike (`sprint-01`
/// Definition of Done).
Future<NorteDatabase> openNorteDatabase() async {
  final Directory directory = await getApplicationSupportDirectory();
  final File file = File(p.join(directory.path, 'norte.sqlite'));
  return NorteDatabase(NativeDatabase.createInBackground(file));
}

/// Opens a throwaway in-memory database.
///
/// Used by the integration tests and by the E2E suite, which boots the real
/// composition root with this in place of the file database
/// (`docs/testing-strategy.md` §4.2).
NorteDatabase openInMemoryNorteDatabase() =>
    NorteDatabase(NativeDatabase.memory());
