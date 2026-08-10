import 'dart:convert';

/// What the two CLI engines actually print, as fixtures.
///
/// **Single-sourced on purpose.** The unit suite (S07-UT-04) and the contract
/// suite (S07-CT-01) both need to speak each CLI's output shape, and two copies
/// of an envelope would drift the first time one tool changed its JSON — with
/// the suite that was not updated still passing, which is the worst possible
/// outcome for a fixture whose job is to be true.
///
/// The noise constants are **real output from the Sprint 07 manual probe**, not
/// invented. `sprint-07`'s handoff §6 records why that matters: the first
/// version of the adapter read a one-line answer perfectly and lost the same
/// answer the moment a banner was printed above it, and only a fixture written
/// from what the CLI prints — rather than from what the parser expected — could
/// have caught it.

/// One Copilot JSONL line carrying an assistant answer.
String copilotAnswer(String payload) => jsonEncode(<String, Object?>{
  'type': 'assistant.message',
  'data': <String, Object?>{'content': payload},
});

/// Claude Code's single result object.
///
/// `jsonEncode`, not interpolation: the answer is a JSON *string* that itself
/// holds JSON, and interpolating would nest it as an object — which the codec
/// cannot read and which no real CLI produces.
String claudeCodeAnswer(String payload) => jsonEncode(<String, Object?>{
  'type': 'result',
  'subtype': 'success',
  'is_error': false,
  'result': payload,
});

/// The bookkeeping Copilot really emits around an answer.
const List<String> copilotNoise = <String>[
  '{"type":"session.mcp_server_status_changed","data":{"status":"connected"}}',
  '{"type":"assistant.turn_start","data":{"turnId":"0"}}',
];

/// The trailer Copilot writes after the answer.
const String copilotResult = '{"type":"result","exitCode":0,"usage":{}}';

/// What either CLI prints on a day it has an update to advertise.
///
/// Not JSON at all, and not a failure. An adapter that treated the first
/// unexpected line as fatal would break on the day the tool shipped a release.
const String updateBanner = 'A new release of the CLI is available.';

/// What a CLI writes to stderr when nobody has signed it in.
///
/// The wording is illustrative; the **exit code is the contract**. Neither CLI
/// offers a machine-readable "unauthenticated" signal, which is exactly why
/// S07-CT-01 records a divergence rather than pretending `AuthFailure` can be
/// recovered from a subprocess.
const String notSignedInStderr = 'error: not signed in. Run the login command.';
