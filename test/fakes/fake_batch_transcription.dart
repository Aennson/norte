import 'dart:async';

import 'package:norte/domain/failures/failure.dart';

import 'ports/provisional_ports.dart';

/// Deterministic [BatchTranscription] (`docs/testing-strategy.md` §3).
///
/// Returns a fixed transcript per file path and emits a scripted progress
/// sequence — no file is ever read and no service is ever called.
class FakeBatchTranscription implements BatchTranscription {
  FakeBatchTranscription({
    Map<String, Transcript>? transcripts,
    this.progressSteps = const <double>[0.25, 0.5, 0.75, 1],
  }) : transcripts = transcripts ?? <String, Transcript>{};

  /// file path → transcript.
  final Map<String, Transcript> transcripts;

  /// Values pushed on [progress] during a successful transcription.
  final List<double> progressSteps;

  /// Paths handed to [transcribeFile], in call order.
  final List<String> requestedFiles = <String>[];

  /// When set, [transcribeFile] throws it after emitting no progress.
  Failure? failWith;

  final StreamController<double> _progress =
      StreamController<double>.broadcast();

  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<Transcript> transcribeFile(String path, {String? language}) async {
    requestedFiles.add(path);

    final Failure? failure = failWith;
    if (failure != null) throw failure;

    final Transcript? transcript = transcripts[path];
    if (transcript == null) {
      throw StateError(
        'FakeBatchTranscription has no transcript fixture for: "$path".',
      );
    }

    for (final double step in progressSteps) {
      _progress.add(step);
    }
    return language == null
        ? transcript
        : Transcript(text: transcript.text, language: language);
  }

  /// Closes the progress stream. Call from `addTearDown`.
  Future<void> dispose() => _progress.close();
}
