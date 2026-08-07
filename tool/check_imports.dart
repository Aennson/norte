// Gate G5 — layer dependency rule + literal-color rule.
//
// Usage:
//   dart run tool/check_imports.dart [rootDir]   (default: lib)
//
// Rules enforced (docs/project-rules.md §3 and docs/design-system.md §7):
//
//   presentation ──> application ──> domain <── infrastructure
//
//   * domain/         imports nothing outside domain/ (Dart core + freezed only).
//   * application/    imports only domain/ (and itself).
//   * infrastructure/ imports domain/ (and itself); never presentation/ or application/.
//   * presentation/   imports application/ and domain/ (and itself); never infrastructure/.
//   * main.dart is the composition root and may import every layer.
//   * `Color(0x...)` literals are forbidden outside presentation/shared/theme/.
//
// Exit code is 0 when there is no violation, 1 otherwise.

import 'dart:io';

/// Packages `domain/` is allowed to depend on: Dart core plus the immutability
/// toolchain listed in docs/architecture.md §2.1 (freezed + json_serializable).
const Set<String> domainAllowedPackages = <String>{
  'freezed_annotation',
  'json_annotation',
  'meta',
};

/// A single rule breach found by [analyze].
class Violation {
  const Violation({
    required this.file,
    required this.line,
    required this.message,
  });

  final String file;
  final int line;
  final String message;

  @override
  String toString() => '$file:$line: $message';
}

/// Layers recognised by the checker, in the order they are matched.
enum Layer { domain, application, infrastructure, presentation, root }

Layer? _layerOf(String relativePath) {
  final segments = relativePath.split('/');
  if (segments.length < 2) return Layer.root;
  return switch (segments.first) {
    'domain' => Layer.domain,
    'application' => Layer.application,
    'infrastructure' => Layer.infrastructure,
    'presentation' => Layer.presentation,
    _ => Layer.root,
  };
}

/// Layers each layer is forbidden to reach.
const Map<Layer, Set<Layer>> _forbidden = <Layer, Set<Layer>>{
  Layer.domain: <Layer>{
    Layer.application,
    Layer.infrastructure,
    Layer.presentation,
  },
  Layer.application: <Layer>{Layer.infrastructure, Layer.presentation},
  Layer.infrastructure: <Layer>{Layer.application, Layer.presentation},
  Layer.presentation: <Layer>{Layer.infrastructure},
  Layer.root: <Layer>{},
};

final RegExp _importPattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
);
final RegExp _colorLiteralPattern = RegExp(r'\bColor\(\s*0x');

/// Resolves the layer targeted by [uri] as seen from [fromRelativePath].
Layer? _targetLayer(String uri, String fromRelativePath) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:norte/')) {
    return _layerOf(uri.substring('package:norte/'.length));
  }
  if (uri.startsWith('package:')) return null;
  // Relative import: resolve against the importing file's directory.
  final baseSegments = fromRelativePath.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '.' || segment.isEmpty) continue;
    if (segment == '..') {
      if (baseSegments.isNotEmpty) baseSegments.removeLast();
      continue;
    }
    baseSegments.add(segment);
  }
  return _layerOf(baseSegments.join('/'));
}

String? _packageNameOf(String uri) {
  if (!uri.startsWith('package:')) return null;
  final rest = uri.substring('package:'.length);
  final slash = rest.indexOf('/');
  return slash == -1 ? rest : rest.substring(0, slash);
}

/// Analyses every `.dart` file under [root] and returns the violations found.
///
/// [root] is the directory that plays the role of `lib/` — the checker treats
/// its immediate children (`domain/`, `application/`, ...) as the layers.
List<Violation> analyze(Directory root) {
  if (!root.existsSync()) {
    return <Violation>[
      Violation(file: root.path, line: 0, message: 'directory does not exist'),
    ];
  }

  final violations = <Violation>[];
  final rootPath = root.path.replaceAll(r'\', '/');

  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final normalized = file.path.replaceAll(r'\', '/');
    final relative = normalized.startsWith('$rootPath/')
        ? normalized.substring(rootPath.length + 1)
        : normalized;
    final layer = _layerOf(relative) ?? Layer.root;
    final forbidden = _forbidden[layer] ?? const <Layer>{};
    final isThemeFile = relative.startsWith('presentation/shared/theme/');

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      if (!isThemeFile && _colorLiteralPattern.hasMatch(line)) {
        violations.add(
          Violation(
            file: relative,
            line: lineNumber,
            message:
                'literal color outside presentation/shared/theme/ '
                '(use the NorteColors theme extension)',
          ),
        );
      }

      final match = _importPattern.firstMatch(line);
      if (match == null) continue;
      final uri = match.group(1)!;

      if (layer == Layer.domain) {
        final package = _packageNameOf(uri);
        if (package != null &&
            package != 'norte' &&
            !domainAllowedPackages.contains(package)) {
          violations.add(
            Violation(
              file: relative,
              line: lineNumber,
              message:
                  "domain/ must not import 'package:$package' "
                  '(allowed: Dart core, ${domainAllowedPackages.join(', ')})',
            ),
          );
          continue;
        }
      }

      final target = _targetLayer(uri, relative);
      if (target != null && forbidden.contains(target)) {
        violations.add(
          Violation(
            file: relative,
            line: lineNumber,
            message:
                '${layer.name}/ must not import ${target.name}/ '
                "(offending import: '$uri')",
          ),
        );
      }
    }
  }

  return violations;
}

/// Runs the check over [rootPath] and returns the process exit code.
int runCheck(String rootPath, {StringSink? out}) {
  final sink = out ?? stdout;
  final violations = analyze(Directory(rootPath));
  if (violations.isEmpty) {
    sink.writeln(
      'check_imports: OK — no layer or color violations in $rootPath',
    );
    return 0;
  }
  sink.writeln('check_imports: ${violations.length} violation(s) in $rootPath');
  for (final violation in violations) {
    sink.writeln('  $violation');
  }
  return 1;
}

void main(List<String> args) {
  final root = args.isEmpty ? 'lib' : args.first;
  exitCode = runCheck(root);
}
