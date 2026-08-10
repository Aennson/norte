import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A child process, reduced to what a CLI engine actually needs.
///
/// **This seam exists so the watchdog can be tested.** S07-UT-03 requires a
/// process that never answers and a controlled clock; `dart:io`'s `Process`
/// offers neither, and a test that spawned a real hanging executable would be
/// slow, platform-specific, and would leave something behind when it failed —
/// which is the exact defect the test is written to catch.
abstract interface class RunningProcess {
  /// Lines the child wrote to stdout, decoded as UTF-8 and split.
  Stream<String> get stdoutLines;

  /// Lines the child wrote to stderr, decoded as UTF-8 and split.
  Stream<String> get stderrLines;

  /// Completes with the exit code once the child has ended.
  Future<int> get exitCode;

  /// Ends the child.
  ///
  /// Must be safe to call on a process that has already exited — the watchdog
  /// and the normal path race by construction, and a kill that threw on an
  /// already-dead child would turn a completed request into a crash.
  ///
  /// Returns `true` when a signal was delivered.
  bool kill();
}

/// Starts child processes.
///
/// Named as a port even though it lives in infrastructure: the domain has no
/// business knowing that an engine is a process, so this abstraction stays on
/// the side of the boundary that does.
abstract interface class ProcessRunner {
  /// Starts [executable] with [arguments].
  ///
  /// [environment] is **merged into** the parent environment by the
  /// implementation, not substituted for it: a CLI launched with only the
  /// variables this app names would lose `PATH`, `SystemRoot` and everything
  /// else it needs to run on Windows.
  ///
  /// [stdin] is written to the child and the pipe is then closed. Closing is
  /// not optional: a CLI reading its prompt from stdin waits for end-of-input
  /// before it starts, so a runner that wrote the text and left the pipe open
  /// would hang every request until the watchdog killed it.
  Future<RunningProcess> start(
    String executable,
    List<String> arguments, {
    Map<String, String> environment,
    String? stdin,
  });
}

/// [ProcessRunner] over `dart:io`.
class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<RunningProcess> start(
    String executable,
    List<String> arguments, {
    Map<String, String> environment = const <String, String>{},
    String? stdin,
  }) async {
    final Process process = await Process.start(
      executable,
      arguments,
      environment: environment,
      // **Never `runInShell: true`.** A shell would re-parse the arguments this
      // app passed as a list, which on Windows means a prompt containing `&`
      // or `|` becomes a command. This matters most for the engine that has to
      // deliver its prompt through argv.
      runInShell: false,
    );

    if (stdin != null) {
      process.stdin.write(stdin);
      // Awaited so a write that fails — a child that died before reading —
      // surfaces here rather than as an unhandled error on the IO thread.
      // The child ending early is a normal race, not a crash, so a broken
      // pipe is swallowed: the exit code is what the caller judges by.
      await process.stdin.flush().catchError((_) {});
      await process.stdin.close().catchError((_) {});
    }

    return _IoProcess(process);
  }
}

class _IoProcess implements RunningProcess {
  _IoProcess(this._process)
    : stdoutLines = _lines(_process.stdout),
      stderrLines = _lines(_process.stderr);

  final Process _process;

  @override
  final Stream<String> stdoutLines;

  @override
  final Stream<String> stderrLines;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  bool kill() => _process.kill(ProcessSignal.sigkill);

  /// Decodes one pipe into lines.
  ///
  /// `allowMalformed` because this is a third party's stdout: a CLI that prints
  /// a stray byte must not take the whole answer down with a `FormatException`
  /// thrown from inside a stream the caller cannot see.
  ///
  /// Broadcast because two things listen — the parser and, on failure, the
  /// diagnostics — and a single-subscription stream would make the second
  /// listener an error rather than a log line.
  static Stream<String> _lines(Stream<List<int>> pipe) => pipe
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter())
      .asBroadcastStream();
}
