import 'dart:async';

import 'package:norte/infrastructure/ai/process_runner.dart';

/// A child process that answers exactly what a test told it to
/// (`docs/testing-strategy.md` §3).
///
/// **It can also answer nothing at all**, which is the case S07-UT-03 exists
/// for: [neverExits] leaves [exitCode] hanging forever, so the only thing that
/// can end the request is the watchdog. A real hung executable would test the
/// same thing and would also be slow, platform-specific, and capable of
/// outliving the test run.
class FakeProcess implements RunningProcess {
  FakeProcess({
    List<String> stdout = const <String>[],
    List<String> stderr = const <String>[],
    int exit = 0,
    this.neverExits = false,
  }) : _stdout = stdout,
       _stderr = stderr,
       _exit = exit;

  final List<String> _stdout;
  final List<String> _stderr;
  final int _exit;

  /// When `true`, [exitCode] never completes on its own.
  final bool neverExits;

  /// Whether [kill] was called. S07-UT-03 asserts this, because a timeout that
  /// returned without killing the child would leak one process per failure and
  /// look identical to a correct one from the caller's side.
  bool killed = false;

  final Completer<int> _exitCode = Completer<int>();

  @override
  Stream<String> get stdoutLines => Stream<String>.fromIterable(_stdout);

  @override
  Stream<String> get stderrLines => Stream<String>.fromIterable(_stderr);

  @override
  Future<int> get exitCode {
    if (neverExits) return _exitCode.future;
    return Future<int>.value(_exit);
  }

  @override
  bool kill() {
    killed = true;
    // A real kill makes the process end, and the adapter is entitled to await
    // the exit code afterwards. A fake that stayed hung after being killed
    // would deadlock the test rather than exercise the code.
    if (!_exitCode.isCompleted) _exitCode.complete(-1);
    return true;
  }
}

/// [ProcessRunner] that hands out [FakeProcess]es and records how it was called.
class FakeProcessRunner implements ProcessRunner {
  FakeProcessRunner(this._next);

  /// Builds the process for one invocation. A function rather than a value so
  /// a test can answer differently on the second call — which is what the
  /// fallback chain's retry needs.
  final FakeProcess Function(int invocation) _next;

  /// Convenience: the same process shape on every call.
  factory FakeProcessRunner.always(FakeProcess Function() build) =>
      FakeProcessRunner((int _) => build());

  /// Convenience: fails to start at all, as a missing executable does.
  factory FakeProcessRunner.missing() =>
      FakeProcessRunner((int _) => throw const ProcessException());

  /// Every invocation, in order.
  final List<ProcessInvocation> invocations = <ProcessInvocation>[];

  /// The processes handed out, in order.
  final List<FakeProcess> started = <FakeProcess>[];

  @override
  Future<RunningProcess> start(
    String executable,
    List<String> arguments, {
    Map<String, String> environment = const <String, String>{},
    String? stdin,
  }) async {
    invocations.add(
      ProcessInvocation(
        executable: executable,
        arguments: arguments,
        environment: environment,
        stdin: stdin,
      ),
    );
    final FakeProcess process = _next(invocations.length);
    started.add(process);
    return process;
  }
}

/// One recorded call to [FakeProcessRunner.start].
class ProcessInvocation {
  const ProcessInvocation({
    required this.executable,
    required this.arguments,
    required this.environment,
    required this.stdin,
  });

  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final String? stdin;

  /// The prompt as the CLI received it, however it was delivered.
  ///
  /// The sprint's rule is that secrets never reach argv, so a test asserting
  /// what was sent has to be able to look in both places without caring which
  /// engine it is looking at.
  String get prompt => stdin ?? arguments.last;
}

/// Thrown by [FakeProcessRunner.missing] to stand for an executable that is
/// not there — the shape `Process.start` fails in, and the shape the sprint's
/// manual fallback test produces by renaming the CLI.
class ProcessException implements Exception {
  const ProcessException();
}
