// Gate G4 — coverage thresholds (docs/project-rules.md §2).
//
// Usage:
//   dart run tool/check_coverage.dart [lcovPath]   (default: coverage/lcov.info)
//
// Thresholds:
//   * domain/ + application/ >= 90% of lines
//   * whole project          >= 80% of lines
//
// The domain+application threshold is skipped while those layers have no
// instrumented lines — Sprint 00 ships the folder structure before the
// entities, and the sprint's Definition of Done waives the gate until then.
//
// Exit code is 0 when every applicable threshold is met, 1 otherwise.

import 'dart:convert';
import 'dart:io';

/// Line counts for a group of source files.
class CoverageTally {
  int found = 0;
  int hit = 0;

  double get percent => found == 0 ? 0 : hit * 100 / found;

  @override
  String toString() => '$hit/$found (${percent.toStringAsFixed(1)}%)';
}

/// Parses an lcov report into per-file `(linesFound, linesHit)` pairs.
Map<String, CoverageTally> parseLcov(String report) {
  final Map<String, CoverageTally> byFile = <String, CoverageTally>{};
  String? current;

  for (final String line in const LineSplitter().convert(report)) {
    if (line.startsWith('SF:')) {
      current = line.substring(3).replaceAll(r'\', '/');
      byFile.putIfAbsent(current, CoverageTally.new);
    } else if (line.startsWith('LF:') && current != null) {
      byFile[current]!.found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:') && current != null) {
      byFile[current]!.hit += int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      current = null;
    }
  }
  return byFile;
}

CoverageTally _sum(Iterable<CoverageTally> tallies) {
  final CoverageTally total = CoverageTally();
  for (final CoverageTally tally in tallies) {
    total.found += tally.found;
    total.hit += tally.hit;
  }
  return total;
}

int runCoverageCheck(String lcovPath, {StringSink? out}) {
  final StringSink sink = out ?? stdout;
  final File report = File(lcovPath);
  if (!report.existsSync()) {
    sink.writeln(
      'check_coverage: $lcovPath not found — run flutter test --coverage',
    );
    return 1;
  }

  final Map<String, CoverageTally> byFile = parseLcov(
    report.readAsStringSync(),
  );
  if (byFile.isEmpty) {
    sink.writeln('check_coverage: $lcovPath has no records');
    return 1;
  }

  bool isCore(String path) =>
      path.contains('lib/domain/') || path.contains('lib/application/');

  final CoverageTally core = _sum(
    byFile.entries
        .where((MapEntry<String, CoverageTally> e) => isCore(e.key))
        .map((MapEntry<String, CoverageTally> e) => e.value),
  );
  final CoverageTally project = _sum(byFile.values);

  sink.writeln('check_coverage:');
  sink.writeln(
    '  domain+application  ${core.found == 0 ? "no instrumented lines yet" : core}',
  );
  sink.writeln('  project             $project');

  var failed = false;

  if (core.found == 0) {
    sink.writeln(
      '  ! domain+application gate skipped — those layers have no code yet '
      '(sprint-00 Definition of Done)',
    );
  } else if (core.percent < 90) {
    sink.writeln(
      '  FAIL domain+application ${core.percent.toStringAsFixed(1)}% < 90%',
    );
    failed = true;
  }

  if (project.percent < 80) {
    sink.writeln('  FAIL project ${project.percent.toStringAsFixed(1)}% < 80%');
    failed = true;
  }

  sink.writeln(failed ? '  gate G4: FAILED' : '  gate G4: OK');
  return failed ? 1 : 0;
}

void main(List<String> args) {
  final String path = args.isEmpty ? 'coverage/lcov.info' : args.first;
  exitCode = runCoverageCheck(path);
}
