import '../../domain/ports/clock.dart';
import 'cli_ai_engine.dart';
import 'process_runner.dart';

/// [CliAiEngine] driving the GitHub Copilot CLI (`docs/architecture.md` §7.2).
///
/// **Everything specific to Copilot is in [profile]**; the behaviour — the
/// watchdog, the parsing, the failure translation, the stderr redaction — is
/// the shared one, and S07-CT-01 runs the same contract over this engine and
/// the Claude Code one so the two cannot quietly diverge.
///
/// The flags were read off `copilot --help` on 1.0.78 and each is load-bearing:
///
/// * `--allow-all-tools` — the CLI refuses non-interactive mode without it. It
///   sounds alarming and is narrowed by what follows.
/// * `--deny-tool shell` / `--deny-tool write` — Copilot is an *agent*, not a
///   text completion service: left alone it will run commands and edit files in
///   whatever directory it was started from. Norte wants an answer to a prompt,
///   so the two tools that touch the machine are denied. Without these lines,
///   asking it to summarize a meeting gives it a licence to modify the user's
///   repository.
/// * `--no-custom-instructions` — it otherwise reads `AGENTS.md` and the
///   project skills from the working directory. A summary that changed shape
///   depending on which folder Norte happened to launch from would be an
///   excellent bug to spend a day on.
/// * `--disable-builtin-mcps` — stops it connecting to the GitHub MCP server,
///   which is a network round-trip and a set of tools this app has no use for.
/// * `--output-format json` — JSONL on stdout, which is what the parser reads.
/// * `--no-color` — otherwise the payload arrives wrapped in ANSI escapes.
/// * `--log-level none` — keeps the CLI's own logging out of stderr, so what
///   remains there is a real complaint worth logging.
/// * `--no-auto-update` — a CLI that decides to download a new version mid
///   request is a 30-second timeout with a confusing cause.
class CopilotCliEngine extends CliAiEngine {
  CopilotCliEngine({
    required super.runner,
    required super.clock,
    required super.isWindows,
    super.model,
    super.timeout,
    super.codec,
    super.intentCodec,
    super.log,
  }) : super(profile: copilotProfile);

  /// Convenience for the composition root and the tests.
  factory CopilotCliEngine.system({
    required Clock clock,
    required bool isWindows,
    String? model,
    void Function(String line)? log,
  }) => CopilotCliEngine(
    runner: const SystemProcessRunner(),
    clock: clock,
    isWindows: isWindows,
    model: model,
    log: log,
  );

  /// The engine id. Shipped, so it must not change.
  static const String engineId = 'copilot-cli';

  /// What to run, and how.
  static const CliEngineProfile copilotProfile = CliEngineProfile(
    id: engineId,
    label: 'GitHub Copilot CLI',
    // `copilot.cmd` rather than `copilot`: npm installs a `.ps1`, a `.cmd` and
    // an extensionless shell script side by side, and only the `.cmd` is
    // something `CreateProcess` can start on Windows without a shell — which
    // the runner deliberately refuses to use.
    executable: 'copilot.cmd',
    baseArguments: <String>[
      '--allow-all-tools',
      '--deny-tool',
      'shell',
      '--deny-tool',
      'write',
      '--no-custom-instructions',
      '--disable-builtin-mcps',
      '--output-format',
      'json',
      '--no-color',
      '--log-level',
      'none',
      '--no-auto-update',
    ],
    promptFlag: '-p',
    modelFlag: '--model',
    // Read from the CLI's own routing on the Sprint 07 manual pass. `auto` is
    // absent on purpose: leaving the model unset *is* auto, and offering both
    // would give the same behaviour two names.
    knownModels: <String>['claude-haiku-4.5', 'gpt-5-mini'],
  );
}
