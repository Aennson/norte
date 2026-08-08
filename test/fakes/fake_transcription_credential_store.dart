import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/transcription_credential_store.dart';

/// In-memory [TranscriptionCredentialStore].
///
/// Stands in for the platform secure store, which no test may touch. The key
/// it holds is always synthetic: no real credential appears anywhere in this
/// repository (BR-08).
class FakeTranscriptionCredentialStore implements TranscriptionCredentialStore {
  FakeTranscriptionCredentialStore([this._apiKey]);

  /// A store already holding a usable synthetic key.
  factory FakeTranscriptionCredentialStore.configured([
    String apiKey = 'synthetic-key',
  ]) => FakeTranscriptionCredentialStore(apiKey);

  String? _apiKey;

  /// Number of times [write] has been called.
  int writes = 0;

  /// Number of times [clear] has been called.
  int clears = 0;

  /// When set, every call throws it.
  Failure? failWith;

  @override
  Future<String?> read() async {
    _guard();
    return _apiKey;
  }

  @override
  Future<void> write(String apiKey) async {
    _guard();
    writes++;
    _apiKey = apiKey;
  }

  @override
  Future<void> clear() async {
    _guard();
    clears++;
    _apiKey = null;
  }

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }
}
