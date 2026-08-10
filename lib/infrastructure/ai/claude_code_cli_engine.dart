import '../../domain/ports/clock.dart';
import 'cli_ai_engine.dart';
import 'process_runner.dart';

/// [CliAiEngine] driving the Claude Code CLI (**DEC-038**).
///
/// **This engine is outside the sprint document's scope and inside the
/// Developer's instruction.** `sprint-07`'s "Out" list says "other local
/// engines"; the Developer asked for this one directly, and DEC-038 records the
/// amendment rather than letting it happen quietly. It is cheap precisely
/// because it was asked for after `CopilotCliEngine` was written: the two CLIs
/// take a prompt the same way and answer in JSON, so this file is a profile and
/// nothing else, and it enters S07-CT-01 as a third subject.
///
/// The flags mirror the Copilot ones for the same reasons, in this tool's
/// spelling, and each was verified against the installed CLI rather than
/// assumed:
///
/// * `--print` — non-interactive; answer, then exit.
/// * `--output-format json` — one JSON object carrying the answer in `result`.
/// * `--disallowed-tools Bash Write Edit Read WebFetch WebSearch` — Claude Code
///   is an agent, and Norte wants a completion, not an assistant with access to
///   the working directory. **`--allowed-tools ''` was the first attempt and is
///   wrong**: the flag is variadic, so an empty value swallows the next
///   argument, and the CLI answered
///   `Input must be provided either through stdin or as a prompt argument` —
///   it had eaten the prompt. Naming the tools to deny avoids the ambiguity
///   entirely.
///
/// **The prompt goes over stdin**, which the same error message revealed is
/// supported. That is why this engine has no transcript-length ceiling while
/// the Copilot one does: a meeting long enough to overflow a Windows command
/// line summarizes here and is refused there.
///
/// **Norte holds no Claude Code credential**, exactly as it holds no Copilot
/// one. The CLI is authenticated by whoever installed it, and its subscription
/// is billed to them — which is a different arrangement from `ClaudeApiEngine`,
/// where the user pastes their own API key into Settings and pays per token.
/// Two engines can therefore both be "Claude" and cost the user differently,
/// and the Settings copy says so.
class ClaudeCodeCliEngine extends CliAiEngine {
  ClaudeCodeCliEngine({
    required super.runner,
    required super.clock,
    required super.isWindows,
    super.model,
    super.timeout,
    super.codec,
    super.intentCodec,
    super.log,
  }) : super(profile: claudeCodeProfile);

  /// Convenience for the composition root and the tests.
  factory ClaudeCodeCliEngine.system({
    required Clock clock,
    required bool isWindows,
    String? model,
    void Function(String line)? log,
  }) => ClaudeCodeCliEngine(
    runner: const SystemProcessRunner(),
    clock: clock,
    isWindows: isWindows,
    model: model,
    log: log,
  );

  /// The engine id. Shipped, so it must not change.
  static const String engineId = 'claude-code-cli';

  /// What to run, and how.
  static const CliEngineProfile claudeCodeProfile = CliEngineProfile(
    id: engineId,
    label: 'Claude Code CLI',
    // A native executable, so unlike Copilot there is no shim to choose
    // between and `CreateProcess` can start it directly.
    executable: 'claude',
    baseArguments: <String>[
      '--output-format',
      'json',
      '--disallowed-tools',
      'Bash',
      'Write',
      'Edit',
      'Read',
      'WebFetch',
      'WebSearch',
    ],
    promptFlag: '--print',
    promptOnStdin: true,
    modelFlag: '--model',
    // Aliases rather than dated ids, because the CLI resolves them to whatever
    // the account currently has and a pinned date would go stale in a way the
    // user could not see.
    knownModels: <String>['opus', 'sonnet', 'haiku'],
  );
}
