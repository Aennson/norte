import 'dart:async';

import 'package:norte/domain/failures/failure.dart';

import 'ports/provisional_ports.dart';

/// A call recorded by [FakeAiEngine].
class AiCall {
  const AiCall({required this.method, required this.input});

  /// `summarize` or `parseIntent`.
  final String method;

  /// The transcript or utterance the engine received.
  final String input;

  @override
  String toString() => '$method($input)';
}

/// Deterministic [AiEngine] driven by a fixture map
/// (`docs/testing-strategy.md` §3).
///
/// Same input, same output — no randomness and no network. Unknown input is a
/// test bug, not a silent empty answer, so it raises [StateError].
class FakeAiEngine implements AiEngine {
  FakeAiEngine({
    Map<String, String>? summaries,
    Map<String, String>? intents,
    this.capabilities = const AiCapabilities(
      isLocal: false,
      supportsStreaming: true,
      supportsPromptCache: true,
      maxTokens: 8192,
    ),
  }) : summaries = summaries ?? <String, String>{},
       intents = intents ?? <String, String>{};

  /// transcript → summary text.
  final Map<String, String> summaries;

  /// utterance → intent JSON.
  final Map<String, String> intents;

  @override
  final AiCapabilities capabilities;

  /// Every call received, in order.
  final List<AiCall> calls = <AiCall>[];

  /// When set, every call throws it instead of answering.
  Failure? failWith;

  /// Artificial delay applied before answering. Drive it with
  /// `fakeAsync`/`FakeClock`; the default is zero so tests stay fast.
  Duration latency = Duration.zero;

  /// When `true`, calls never complete — used to exercise timeout handling.
  bool hang = false;

  @override
  Future<String> summarize(String transcript, String systemPrompt) =>
      _respond('summarize', transcript, summaries);

  @override
  Future<String> parseIntent(String utterance) =>
      _respond('parseIntent', utterance, intents);

  Future<String> _respond(
    String method,
    String input,
    Map<String, String> fixtures,
  ) async {
    calls.add(AiCall(method: method, input: input));

    if (hang) return Completer<String>().future;
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final Failure? failure = failWith;
    if (failure != null) throw failure;

    final String? response = fixtures[input];
    if (response == null) {
      throw StateError(
        'FakeAiEngine has no $method fixture for: "$input". '
        'Add it to the fixture map instead of relying on a default.',
      );
    }
    return response;
  }

  /// Inputs seen by [method], in call order.
  List<String> inputsFor(String method) => calls
      .where((AiCall call) => call.method == method)
      .map((AiCall call) => call.input)
      .toList();

  /// Forgets every recorded interaction.
  void reset() {
    calls.clear();
    failWith = null;
    latency = Duration.zero;
    hang = false;
  }
}
