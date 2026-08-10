import 'dart:async';
import 'dart:convert';

import '../../domain/entities/intent_context.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/failures/failure.dart';
import '../../domain/ports/ai_engine.dart';
import '../../domain/ports/clock.dart';
import 'intent_codec.dart';
import 'meeting_summary_codec.dart';
import 'process_runner.dart';

/// How one command-line assistant is driven: what to run, and how to read it.
///
/// The two CLI engines in v1.0 differ in about six values and nothing else —
/// both take a prompt, both answer in JSON on stdout, both are Windows-only
/// here. A profile keeps that difference as data, so the watchdog, the parser,
/// the failure translation and the redaction have exactly one implementation
/// and cannot drift apart between engines (which is the whole point of running
/// both through one contract suite, S07-CT-01).
class CliEngineProfile {
  const CliEngineProfile({
    required this.id,
    required this.label,
    required this.executables,
    required this.baseArguments,
    required this.promptFlag,
    required this.modelFlag,
    required this.knownModels,
    this.promptOnStdin = false,
  });

  /// Stable id. Keys the usage counter and the model preference, so it must
  /// not change once shipped.
  final String id;

  /// Human-readable name for Settings and the diagnostics log.
  final String label;

  /// The programs to try, in order, until one starts.
  ///
  /// Resolved through `PATH` rather than pinned to an install location,
  /// because both CLIs update themselves and a hard-coded path would silently
  /// point at a version that has moved.
  ///
  /// **A list, because "the Copilot CLI" is not one install.** The Sprint 07
  /// manual pass was written against the npm package, which lays down a `.ps1`,
  /// a `.cmd` and an extensionless shell script side by side — only the `.cmd`
  /// of which `CreateProcess` can start without a shell, which the runner
  /// deliberately refuses to use. Run on a machine where the same tool had been
  /// installed through WinGet, that name did not exist: WinGet ships a native
  /// `copilot.exe`. One hard-coded name meant the engine worked on the
  /// developer's machine and reported "is it installed?" on a machine where it
  /// plainly was.
  ///
  /// The order is native-executable-first, because a `.cmd` is a shim around
  /// one and starting the shim buys an extra process for nothing.
  ///
  /// Only a failure to *start* advances to the next candidate. A CLI that
  /// starts and then exits non-zero has answered, and trying a second copy of
  /// the same tool would turn one honest failure into two.
  final List<String> executables;

  /// Arguments that are always sent, before the prompt.
  final List<String> baseArguments;

  /// The flag that puts the CLI in non-interactive mode.
  ///
  /// When [promptOnStdin] is `false` the prompt follows it as the flag's value.
  final String promptFlag;

  /// Whether the prompt is written to the child's stdin rather than argv.
  ///
  /// **Not a style choice — it decides how long a meeting can be.** Windows
  /// caps a command line at roughly 32 767 characters, and the operating
  /// system truncates rather than complaining, so an argv-delivered transcript
  /// over the cap would produce a confident summary of half a meeting. A CLI
  /// that reads stdin has no such ceiling, and [CliAiEngine] only enforces
  /// [CliAiEngine.maxPromptChars] against the ones that do not.
  ///
  /// Claude Code accepts stdin (`Input must be provided either through stdin
  /// or as a prompt argument`); Copilot 1.0.78 requires the prompt as the
  /// value of `-p`.
  final bool promptOnStdin;

  /// The flag that pins a model, when the user chose one.
  final String modelFlag;

  /// Models offered in Settings, most capable first.
  ///
  /// A convenience, not a constraint: [CliAiEngine] sends whatever model id the
  /// settings hold, so a model released after this build can still be used by
  /// typing it. The list exists so the common case is a tap rather than
  /// remembering an id.
  final List<String> knownModels;
}

/// [AiEngine] over a command-line assistant run as a subprocess
/// (`docs/architecture.md` §7.2).
///
/// **`isLocal` is `false`, and that is not an oversight** — see DEC-037. The
/// architecture document said `true` on the grounds that a local subprocess
/// keeps data on the machine; the CLI was then installed and run, and it
/// answered with a server-chosen model and a billed request. The process is
/// local; the inference is not. BR-07's redactor relaxation is conditioned on
/// the second, so it does not apply here and the redactor stays enforced.
///
/// **Norte holds no credential for these engines.** Both CLIs authenticate
/// themselves — `copilot login`, `claude` — and keep their token in the
/// platform credential store under their own name. Nothing is read from
/// Norte's secure storage, nothing is put in argv, and nothing is added to the
/// child's environment. The sprint's rule that secrets must never reach argv is
/// satisfied by there being no secret in this class to leak.
///
/// **The watchdog is the reason this class is careful.** A CLI that hangs is
/// not an unusual case: it is what happens when the tool decides to prompt for
/// a login on a machine where the session expired. The deadline is enforced by
/// the caller's clock, the child is killed, and the kill is awaited — a
/// timeout that returns while the process is still running would leak one child
/// per failed request.
class CliAiEngine implements AiEngine {
  CliAiEngine({
    required this.runner,
    required this.profile,
    required this.clock,
    required this.isWindows,
    this.model,
    this.timeout = defaultTimeout,
    this.codec = const MeetingSummaryCodec(),
    this.intentCodec = const IntentCodec(),
    this.log,
  });

  final ProcessRunner runner;
  final CliEngineProfile profile;
  final Clock clock;

  /// Whether this is running on the platform the CLI exists for.
  ///
  /// Injected rather than read from `Platform.isWindows`, because the sprint
  /// forbids platform code outside the composition root and the adapter — and
  /// because S07-UT-05 has to be able to ask this adapter what it would say on
  /// Android without running on Android.
  final bool isWindows;

  /// The model id the user pinned, or `null` to let the CLI route.
  final String? model;

  /// How long the child gets before the watchdog ends it.
  final Duration timeout;

  final MeetingSummaryCodec codec;
  final IntentCodec intentCodec;

  /// Diagnostics sink. Receives what the CLI wrote to stderr, redacted.
  final void Function(String line)? log;

  /// The deadline §7.2 specifies.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Ceiling on one prompt, in characters, for engines that take it in argv.
  ///
  /// **A real operating-system limit, not a policy.** Windows caps a command
  /// line at roughly 32 767 characters and truncates silently rather than
  /// refusing, which would turn a long meeting into a confident summary of the
  /// first half with nothing about it looking wrong. It is refused here
  /// instead, with the same failure the remote engine raises for a transcript
  /// the API rejects as too long.
  ///
  /// Well under the true cap because the prompt is not the whole command line:
  /// the flags, the executable path and the environment block share the budget.
  ///
  /// Engines with `promptOnStdin` are not subject to it and have no ceiling
  /// here at all.
  static const int maxPromptChars = 24000;

  /// Whether this engine can run where it finds itself (§7.2).
  ///
  /// Android and iOS have no subprocess to start, so the adapter reports itself
  /// unavailable and Settings hides the option (S07-UT-05) rather than offering
  /// a choice that would fail on first use.
  bool get unavailable => !isWindows;

  @override
  AiCapabilities get capabilities => const AiCapabilities(
    // DEC-037. The subprocess is local; the inference is not.
    isLocal: false,
    // The CLI answers in one batch. The sprint's "Out" allows this explicitly.
    supportsStreaming: false,
    // Whatever the CLI caches, it caches for itself and reports nothing this
    // app could act on.
    supportsPromptCache: false,
    maxTokens: 0,
  );

  @override
  Future<MeetingSummary> summarize(
    String transcript,
    MeetingTemplate template,
  ) async {
    // **The CLI has no system/user split.** `AiEngine` documents that split as
    // what makes prompt caching possible, and this transport simply has no
    // affordance for it — there is one prompt. The codec's system prompt is
    // sent first and the transcript after a delimiter, which preserves the
    // ordering the prompt was written for; what is lost is the caching, and
    // `capabilities.supportsPromptCache` already says so.
    // **The output contract is spelled out, because this transport cannot
    // attach a schema.** `ClaudeApiEngine` sends `MeetingSummaryCodec.schemaFor`
    // as `output_config.format` and the model has no choice; there is one
    // prompt here and no such affordance. Without this line the real Copilot
    // CLI answered the Sprint 07 manual pass in Markdown headings — a good
    // answer to the prompt it was given, and unreadable to the codec.
    final String raw = await _run(
      _joinPrompt(
        '${codec.systemPromptFor(template)}\n\n'
        '${codec.outputContractFor(template)}',
        transcript,
      ),
    );

    return codec.parse(
      raw,
      template,
      generatedAt: clock.now().toUtc(),
      engineId: _engineId,
    );
  }

  @override
  Future<VoiceIntent> parseIntent(
    String utterance,
    IntentContext context,
  ) async {
    final String raw = await _run(
      _joinPrompt(
        intentCodec.systemPrompt,
        intentCodec.userMessageFor(utterance, context),
      ),
    );
    return intentCodec.parse(raw, context: context);
  }

  @override
  Future<void> primeCache() async {
    // Nothing to warm. The port documents this exact case: an engine that
    // caches nothing satisfies the contract by doing nothing, and spending a
    // billed request to warm a cache that does not exist would be worse than
    // doing nothing.
  }

  /// The id recorded on summaries and against the usage counter.
  String get _engineId => model == null ? profile.id : '${profile.id}:$model';

  /// One prompt, as the CLI will receive it.
  ///
  /// The delimiter is spelled out rather than implied by a blank line, because
  /// a transcript containing blank lines is the normal case and the model has
  /// to be able to tell where the instructions stop.
  String _joinPrompt(String system, String user) =>
      '$system\n\n--- INPUT ---\n$user';

  /// Runs the CLI once and returns the answer text.
  Future<String> _run(String prompt) async {
    if (unavailable) {
      throw AiProcessFailure('${profile.label} is only available on Windows');
    }
    if (!profile.promptOnStdin && prompt.length > maxPromptChars) {
      throw const ValidationFailure(
        'the transcript is too long for the command-line engine',
        'transcript',
      );
    }

    final List<String> arguments = <String>[
      ...profile.baseArguments,
      if (model case final String pinned) ...<String>[
        profile.modelFlag,
        pinned,
      ],
      profile.promptFlag,
      if (!profile.promptOnStdin) prompt,
    ];

    // Each candidate in turn. The loop exists because one tool can be
    // installed under more than one name (see [CliEngineProfile.executables]),
    // and the only way to find out which one this machine has is to try.
    RunningProcess? process;
    for (final String executable in profile.executables) {
      try {
        process = await runner.start(
          executable,
          arguments,
          environment: const <String, String>{},
          stdin: profile.promptOnStdin ? prompt : null,
        );
        break;
      } catch (error) {
        // The commonest failure by far, and the one worth naming: the CLI is
        // not installed under this name. It is also how the sprint's manual
        // fallback test is performed — rename the executable and every
        // candidate fails, and this is the path that runs.
        log?.call(
          '[${profile.id}] $executable could not start — ${error.runtimeType}',
        );
      }
    }

    if (process == null) {
      throw AiProcessFailure(
        '${profile.label} could not be started — is it installed?',
      );
    }

    return _collect(process);
  }

  /// Reads the child under the deadline, killing it if it overruns.
  Future<String> _collect(RunningProcess process) async {
    final List<String> out = <String>[];
    final StringBuffer err = StringBuffer();

    // Subscribed before anything is awaited. A pipe nobody is reading fills its
    // buffer and blocks the child, which would present as a hang the watchdog
    // then blames on the CLI.
    final StreamSubscription<String> errSub = process.stderrLines.listen(
      (String line) => err.writeln(line),
      onError: (_) {},
    );
    final StreamSubscription<String> outSub = process.stdoutLines.listen(
      out.add,
      onError: (_) {},
    );

    // **Both pipes are drained to their end, not just awaited alongside the
    // exit code.** A process that exits quickly completes `exitCode` while
    // stdout still has lines in flight, and cancelling the subscription then
    // discards them — which produced an adapter that read a one-line answer
    // correctly and lost the same answer the moment the CLI printed a banner
    // above it. The bug survived every single-line fixture and was caught by
    // the first one with noise in it (S07-UT-04).
    final Future<void> drained = Future.wait(<Future<void>>[
      outSub.asFuture<void>().catchError((_) {}),
      errSub.asFuture<void>().catchError((_) {}),
    ]);

    bool timedOut = false;
    try {
      await Future.wait(<Future<void>>[process.exitCode, drained]).timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          process.kill();
          // The value is never used — `timedOut` decides the outcome — but the
          // future has to complete for the cleanup below to run.
          return <void>[];
        },
      );
    } finally {
      await outSub.cancel();
      await errSub.cancel();
    }

    _reportStderr(err.toString());

    if (timedOut) {
      throw AiTimeoutFailure(
        '${profile.label} did not answer within '
        '${timeout.inSeconds}s and was stopped',
      );
    }

    final int code = await process.exitCode;
    if (code != 0) {
      throw AiProcessFailure('${profile.label} exited with code $code', code);
    }

    final String? answer = _extractAnswer(out);
    if (answer == null || answer.trim().isEmpty) {
      throw AiProcessFailure('${profile.label} produced no answer');
    }
    return answer;
  }

  /// Pulls the assistant's text out of the CLI's JSON output.
  ///
  /// **Both shapes, because the two CLIs disagree.** Copilot writes JSONL — one
  /// object per line, most of them session bookkeeping — and Claude Code writes
  /// a single object. Rather than a parser per engine, every line is tried as
  /// JSON and the whole output is tried as JSON, and any object carrying an
  /// answer is taken; the **last** one wins, because a session that spoke more
  /// than once ends with its conclusion.
  ///
  /// Anything unparseable is skipped rather than fatal. That is what makes the
  /// "noise before and after the payload" case of S07-UT-04 pass: a CLI that
  /// prints an update notice, a warning, or a progress line above its JSON is
  /// behaving normally, and an adapter that treated the first unexpected line
  /// as an error would break on the day either tool added a banner.
  String? _extractAnswer(List<String> lines) {
    String? answer;

    void consider(Object? decoded) {
      final String? found = _answerIn(decoded);
      if (found != null && found.trim().isNotEmpty) answer = found;
    }

    for (final String line in lines) {
      consider(_tryDecode(line));
    }
    if (answer == null) {
      // Claude Code's `--output-format json` is one object, possibly across
      // several lines, so the line-by-line pass above finds nothing in it.
      consider(_tryDecode(lines.join('\n')));
    }
    return answer;
  }

  /// The answer text inside one decoded JSON value, if it holds one.
  String? _answerIn(Object? decoded) {
    if (decoded is! Map<String, Object?>) return null;

    // Claude Code: `{"type":"result","subtype":"success","result":"…"}`.
    if (decoded['result'] case final String result) return result;

    // Copilot: `{"type":"assistant.message","data":{"content":"…"}}`.
    if (decoded['type'] == 'assistant.message') {
      if (decoded['data'] case final Map<String, Object?> data) {
        if (data['content'] case final String content) return content;
      }
    }

    // A bare `{"content":"…"}`, which is what a CLI writing plain JSON rather
    // than an event log would produce.
    if (decoded['content'] case final String content) return content;

    return null;
  }

  Object? _tryDecode(String payload) {
    final String trimmed = payload.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } on FormatException {
      return null;
    }
  }

  /// Logs what the CLI complained about, with anything secret-shaped removed.
  ///
  /// **stderr is a third party's output and is treated as untrusted.** It is
  /// the one place a token could plausibly appear — a CLI echoing the
  /// environment it was given, an auth error quoting the credential it
  /// rejected — and `docs/architecture.md` §10 forbids a log line carrying one.
  /// It is redacted here rather than at the sink, because this is the only
  /// place that knows the text came from outside the app.
  void _reportStderr(String text) {
    if (log == null) return;
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    log!.call('[${profile.id}] stderr: ${_redact(trimmed)}');
  }

  /// Replaces anything shaped like a credential with a marker.
  static String _redact(String text) {
    return text
        .replaceAll(_tokenPattern, '<redacted>')
        // `replaceAllMapped`, not `replaceAll`: a `$1` in a Dart replacement
        // string is the literal characters, not the captured group, so the
        // simpler call would have replaced the variable's *name* as well as
        // its value and made the log useless for saying which one leaked.
        .replaceAllMapped(
          _assignmentPattern,
          (Match m) => '${m.group(1)}=<redacted>',
        );
  }

  /// Token shapes both tools actually emit: `gho_`/`ghp_`/`ghu_`/`ghs_`/
  /// `github_pat_` for GitHub, `sk-ant-` for Anthropic.
  static final RegExp _tokenPattern = RegExp(
    r'\b(?:gh[opsu]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{20,}|sk-ant-[A-Za-z0-9\-_]{16,})',
  );

  /// `SOMETHING_TOKEN=value`, whatever the value looks like.
  static final RegExp _assignmentPattern = RegExp(
    r'(\w*(?:TOKEN|KEY|SECRET|PASSWORD)\w*)\s*=\s*\S+',
    caseSensitive: false,
  );
}
