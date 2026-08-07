import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_imports.dart';

/// S00-IT-01 — gate G5 must actually fail when the dependency rule is broken.
///
/// Everything runs against a synthetic layer tree in a temporary directory, so
/// the test never touches `lib/` and leaves nothing behind.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('norte_check_imports_');
    for (final String layer in <String>[
      'domain/entities',
      'application/usecases',
      'infrastructure/persistence',
      'presentation/shared/theme',
      'presentation/tasks',
    ]) {
      Directory('${root.path}/$layer').createSync(recursive: true);
    }
    // A clean baseline: legal imports only.
    File('${root.path}/domain/entities/task.dart').writeAsStringSync('''
class Task {
  const Task(this.id);
  final String id;
}
''');
    File(
      '${root.path}/application/usecases/create_task.dart',
    ).writeAsStringSync('''
import '../../domain/entities/task.dart';

Task createTask(String id) => Task(id);
''');
  });

  tearDown(() => root.deleteSync(recursive: true));

  File offendingFile(String relativePath, String contents) {
    final File file = File('${root.path}/$relativePath')
      ..writeAsStringSync(contents);
    return file;
  }

  test('S00-IT-01: the clean tree passes and reports exit code 0', () {
    expect(analyze(root), isEmpty);
    expect(runCheck(root.path, out: StringBuffer()), 0);
  });

  test(
    'S00-IT-01: domain/ importing package:flutter/material.dart is reported, '
    'and removing the file restores a passing run',
    () {
      final File offender = offendingFile(
        'domain/entities/illegal_widget.dart',
        "import 'package:flutter/material.dart';\n\n"
            'class IllegalWidget extends StatelessWidget {}\n',
      );

      final List<Violation> violations = analyze(root);
      expect(violations, hasLength(1));
      expect(violations.single.file, 'domain/entities/illegal_widget.dart');
      expect(violations.single.line, 1);
      expect(violations.single.message, contains('domain/'));
      expect(violations.single.message, contains('package:flutter'));

      final StringBuffer output = StringBuffer();
      expect(
        runCheck(root.path, out: output),
        isNot(0),
        reason: 'G5 must fail the build on a layer violation',
      );
      expect(output.toString(), contains('illegal_widget.dart'));

      offender.deleteSync();

      expect(analyze(root), isEmpty);
      expect(runCheck(root.path, out: StringBuffer()), 0);
    },
  );

  test('S00-IT-01: presentation/ must not reach into infrastructure/', () {
    offendingFile(
      'presentation/tasks/tasks_screen.dart',
      "import '../../infrastructure/persistence/task_dao.dart';\n",
    );

    final List<Violation> violations = analyze(root);
    expect(violations, hasLength(1));
    expect(violations.single.message, contains('presentation/'));
    expect(violations.single.message, contains('infrastructure/'));
  });

  test('S00-IT-01: infrastructure/ must not reach into application/', () {
    offendingFile(
      'infrastructure/persistence/task_dao.dart',
      "import 'package:norte/application/usecases/create_task.dart';\n",
    );

    final List<Violation> violations = analyze(root);
    expect(violations, hasLength(1));
    expect(violations.single.message, contains('infrastructure/'));
    expect(violations.single.message, contains('application/'));
  });

  test('S00-IT-01: application/ must not reach into presentation/', () {
    offendingFile(
      'application/usecases/leaky.dart',
      "import '../../presentation/tasks/tasks_screen.dart';\n",
    );

    final List<Violation> violations = analyze(root);
    expect(violations, hasLength(1));
    expect(violations.single.message, contains('application/'));
    expect(violations.single.message, contains('presentation/'));
  });

  test('S00-IT-01: a literal colour outside the theme folder is reported', () {
    offendingFile(
      'presentation/tasks/colored_card.dart',
      'const background = Color(0xFF1F1E1D);\n',
    );

    final List<Violation> violations = analyze(root);
    expect(violations, hasLength(1));
    expect(violations.single.message, contains('literal color'));
    expect(runCheck(root.path, out: StringBuffer()), isNot(0));
  });

  test(
    'S00-IT-01: the theme folder is the one place colours may be literal',
    () {
      offendingFile(
        'presentation/shared/theme/norte_colors.dart',
        'const bg = Color(0xFF1F1E1D);\n',
      );

      expect(analyze(root), isEmpty);
    },
  );

  test('S00-IT-01: domain/ may still use freezed and Dart core', () {
    offendingFile(
      'domain/entities/legal_entity.dart',
      "import 'dart:convert';\n"
          "import 'package:freezed_annotation/freezed_annotation.dart';\n",
    );

    expect(analyze(root), isEmpty);
  });

  test('S00-IT-01: a missing root is reported instead of silently passing', () {
    final int code = runCheck(
      '${root.path}/does_not_exist',
      out: StringBuffer(),
    );
    expect(code, isNot(0));
  });
}
