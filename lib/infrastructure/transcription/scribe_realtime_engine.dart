import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../domain/failures/failure.dart';
import '../../domain/ports/transcription_credential_store.dart';
import '../../domain/ports/transcription_engine.dart';
import 'realtime_socket.dart';

/// [RealtimeTranscription] over Scribe v2 Realtime
/// (`docs/architecture.md` §9.2, §9.3).
///
/// **Why realtime for a voice command.** The user is holding a button waiting
/// to see their words appear; a batch upload would be cheaper and useless.
/// Routing is fixed per use case (§9.2), so nothing here is user-configurable
/// except the key.
///
/// **The reconnection buffer is the interesting part.** A dropped socket
/// mid-sentence must not lose the sentence, so audio that arrives while the
/// connection is down is held and re-sent once it comes back. Three properties
/// of that buffer are load-bearing:
///
/// * **It is memory, never a file (BR-06).** This class imports no `dart:io`
///   and knows no path. Spilling the buffer to disk would make a dropped
///   Wi-Fi connection the one code path that leaves voice audio on the user's
///   device — the exact thing the rule exists to prevent.
/// * **It is capped at five seconds** (§9.3), by byte count rather than by
///   clock: five seconds of the format this engine requires *is* a byte count,
///   and deriving it from [maxBufferedSeconds] means the cap cannot drift
///   away from the format.
/// * **It drops the oldest audio, not the newest.** Past the cap, what the
///   user said most recently is what they are still expecting to see.
///
/// **BYOK.** The key is read from [TranscriptionCredentialStore] per session
/// and never held in a field (BR-08).
///
/// **Errors.** Every outcome is a [Failure] on the event stream; nothing raw
/// escapes (`docs/project-rules.md` §6). A rejected key is not retried — the
/// second attempt is refused for the same reason as the first.
class ScribeRealtimeEngine implements RealtimeTranscription {
  ScribeRealtimeEngine({
    required this.credentialStore,
    RealtimeSocketConnector? connect,
    this.baseUrl = defaultBaseUrl,
    this.model = defaultModel,
    this.language,
    this.backoff = defaultBackoff,
    this.log,
    Future<void> Function(Duration)? sleep,
  }) : _connect = connect ?? WebSocketRealtimeSocket.connect,
       _sleep = sleep ?? _wait;

  final TranscriptionCredentialStore credentialStore;
  final RealtimeSocketConnector _connect;
  final Future<void> Function(Duration) _sleep;

  /// The service host.
  final String baseUrl;

  /// Model id. Configurable because the user pays for it.
  final String model;

  /// BCP-47 language hint, or `null` to let the service detect it.
  final String? language;

  /// Diagnostics sink for frames this adapter could not read (DEC-026).
  ///
  /// The wire format is the one thing no automated test can verify — every
  /// suite drives a fake socket — so a frame the reader does not recognise is
  /// the single most useful thing the manual pass can be shown. Without it the
  /// ambiguous outcome ("it connects but nothing appears") is silent, and the
  /// Developer has no way to tell a protocol mismatch from a dead microphone.
  ///
  /// **It reports shape, never content**: the frame's `type` and its keys, not
  /// the transcript. Speech does not go in a log (BR-06).
  final void Function(String line)? log;

  /// Waits between reconnection attempts, in order. The list's length is the
  /// number of attempts: when it runs out, the session fails rather than
  /// retrying forever behind a user who has already stopped talking.
  final List<Duration> backoff;

  /// The default host.
  static const String defaultBaseUrl = 'wss://api.elevenlabs.io';

  /// Path of the realtime endpoint.
  static const String endpoint = '/v1/speech-to-text/realtime';

  /// The default model.
  static const String defaultModel = 'scribe_v2_realtime';

  /// Sample rate of the audio this engine accepts.
  static const int sampleRate = 16000;

  /// Bytes per sample: signed 16-bit.
  static const int bytesPerSample = 2;

  /// The ceiling §9.3 sets on the reconnection buffer.
  static const Duration maxBufferedSeconds = Duration(seconds: 5);

  /// [maxBufferedSeconds] in bytes of the format this engine requires.
  static const int maxBufferedBytes =
      sampleRate * bytesPerSample * 5; // 160_000

  /// Backoff that gives a flaky connection about seven seconds to come back —
  /// long enough to survive a lift or a handover, short enough that the user
  /// is told something is wrong while they still remember speaking.
  static const List<Duration> defaultBackoff = <Duration>[
    Duration(milliseconds: 250),
    Duration(milliseconds: 750),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  StreamController<TranscriptEvent>? _events;
  StreamSubscription<Uint8List>? _audio;
  StreamSubscription<Object?>? _incoming;
  RealtimeSocket? _socket;

  /// Audio captured while the socket was down, oldest first.
  final List<Uint8List> _buffer = <Uint8List>[];
  int _bufferedBytes = 0;

  bool _stopped = false;
  bool _audioEnded = false;

  @override
  TranscriptionMode get mode => TranscriptionMode.realtime;

  /// Bytes currently held for replay. Never more than [maxBufferedBytes].
  int get bufferedBytes => _bufferedBytes;

  @override
  Stream<TranscriptEvent> start(Stream<Uint8List> pcm16k) {
    final StreamController<TranscriptEvent> events =
        StreamController<TranscriptEvent>();
    _events = events;
    _stopped = false;
    _audioEnded = false;
    _buffer.clear();
    _bufferedBytes = 0;

    _audio = pcm16k.listen(
      _onAudio,
      onError: (Object error) => _fail(
        error is Failure
            ? error
            : const RecordingFailure('audio capture stopped'),
      ),
      onDone: _onAudioDone,
    );

    unawaited(_open());
    return events.stream;
  }

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;

    // Ask the service to commit whatever segment is still open before the
    // socket goes: a user who stops talking and lifts their finger has
    // finished a sentence, and dropping it would lose the command.
    _socket?.send(jsonEncode(<String, Object?>{'type': 'flush'}));

    await _teardown();
    final StreamController<TranscriptEvent>? events = _events;
    _events = null;
    if (events != null && !events.isClosed) await events.close();
  }

  // --- connection --------------------------------------------------------

  Uri get _uri => Uri.parse('$baseUrl$endpoint').replace(
    queryParameters: <String, String>{
      'model_id': model,
      'encoding': 'pcm_s16le_16000',
      if (language case final String tag) 'language_code': tag,
    },
  );

  /// Opens the session, retrying per [backoff] while the failure is one a
  /// retry could fix.
  Future<void> _open() async {
    final String? stored = await credentialStore.read();
    if (stored == null || stored.trim().isEmpty) {
      _fail(
        const MissingApiKeyFailure(
          'no transcription API key is configured — add one in Settings',
        ),
      );
      return;
    }
    final String key = stored.trim();

    for (var attempt = 0; !_stopped; attempt++) {
      try {
        final RealtimeSocket socket = await _connect(_uri, key);
        if (_stopped) {
          await socket.close();
          return;
        }
        _socket = socket;
        _incoming = socket.messages.listen(
          _onMessage,
          onError: (Object _) => _onSocketGone(),
          onDone: _onSocketGone,
        );
        _flush();
        return;
      } on AuthFailure catch (failure) {
        // A refused key is refused on the second attempt too. Retrying would
        // spend the user's time to reach the same answer.
        _fail(failure);
        return;
      } on Failure catch (failure) {
        if (attempt >= backoff.length - 1) {
          _fail(failure);
          return;
        }
        await _sleep(backoff[attempt]);
      }
    }
  }

  /// The socket went away. Reconnect unless the caller is done with us.
  void _onSocketGone() {
    if (_stopped || _events == null) return;
    unawaited(_incoming?.cancel());
    _incoming = null;
    _socket = null;

    // Audio arriving from here on lands in the buffer rather than the void,
    // which is what makes the reconnection lossless.
    if (_audioEnded) {
      // Nothing more will arrive to replay; the session is simply over.
      unawaited(stop());
      return;
    }
    unawaited(_open());
  }

  // --- audio -------------------------------------------------------------

  void _onAudio(Uint8List chunk) {
    if (_stopped) return;
    final RealtimeSocket? socket = _socket;
    if (socket != null) {
      socket.send(chunk);
      return;
    }
    _hold(chunk);
  }

  /// Holds [chunk] for replay, dropping the oldest audio past the cap.
  void _hold(Uint8List chunk) {
    _buffer.add(chunk);
    _bufferedBytes += chunk.length;

    while (_bufferedBytes > maxBufferedBytes && _buffer.isNotEmpty) {
      final Uint8List oldest = _buffer.first;
      final int excess = _bufferedBytes - maxBufferedBytes;
      if (oldest.length <= excess) {
        _buffer.removeAt(0);
        _bufferedBytes -= oldest.length;
      } else {
        // Trim within the chunk rather than dropping it whole: the cap is
        // five seconds of speech, not "five seconds rounded down to whatever
        // the platform's frame size happens to be".
        _buffer[0] = Uint8List.sublistView(oldest, excess);
        _bufferedBytes -= excess;
      }
    }
  }

  /// Re-sends everything held, oldest first, and forgets it.
  void _flush() {
    final RealtimeSocket? socket = _socket;
    if (socket == null) return;
    for (final Uint8List chunk in _buffer) {
      socket.send(chunk);
    }
    _buffer.clear();
    _bufferedBytes = 0;
  }

  void _onAudioDone() {
    _audioEnded = true;
    // The microphone closed — the user let go of the button. Let the service
    // commit the open segment; `stop` follows from the caller.
    _socket?.send(jsonEncode(<String, Object?>{'type': 'flush'}));
  }

  // --- messages ----------------------------------------------------------

  /// Reads one service frame.
  ///
  /// The wire shape is the service's, and the adapter is deliberately
  /// tolerant about which of its spellings it gets: `partial`/`final`,
  /// `is_final`, `text`/`transcript`. An adapter that insisted on one exact
  /// spelling would turn a harmless protocol revision into a silent loss of
  /// every command (`docs/architecture.md` §15 — "Copilot CLI changing
  /// interface/output", the same risk in a different coat).
  void _onMessage(Object? frame) {
    final Object? decoded = switch (frame) {
      final String text => _tryDecode(text),
      final List<int> bytes => _tryDecode(
        utf8.decode(bytes, allowMalformed: true),
      ),
      _ => null,
    };
    if (decoded is! Map<String, Object?>) return;

    final String type = switch (decoded['type']) {
      final String value => value,
      _ => '',
    };

    if (type == 'error') {
      _fail(_failureFor(decoded['error']));
      return;
    }

    final String? text = switch (decoded['text'] ?? decoded['transcript']) {
      final String value => value,
      _ => null,
    };
    if (text == null) {
      log?.call(
        'unrecognised frame: type="$type", keys=${decoded.keys.toList()} — '
        'no `text` or `transcript` field (DEC-026)',
      );
      return;
    }

    final bool committed =
        type.contains('final') ||
        type.contains('committed') ||
        decoded['is_final'] == true;

    _emit(TranscriptEvent(text: text, isCommitted: committed));
  }

  Object? _tryDecode(String payload) {
    try {
      return jsonDecode(payload);
    } on FormatException {
      return null;
    }
  }

  Failure _failureFor(Object? error) {
    final String? code = error is Map<String, Object?>
        ? error['type'] as String?
        : null;
    return switch (code) {
      'authentication_error' => const AuthFailure(
        'the transcription service rejected the API key',
      ),
      'rate_limit_error' => const RateLimitFailure(
        'the transcription service is rate limiting',
      ),
      _ => const TranscriptionFailure(
        'the transcription service ended the session',
      ),
    };
  }

  // --- plumbing ----------------------------------------------------------

  void _emit(TranscriptEvent event) {
    final StreamController<TranscriptEvent>? events = _events;
    if (events == null || events.isClosed) return;
    events.add(event);
  }

  void _fail(Failure failure) {
    final StreamController<TranscriptEvent>? events = _events;
    if (events == null || events.isClosed) return;
    events.addError(failure);
    unawaited(stop());
  }

  Future<void> _teardown() async {
    await _audio?.cancel();
    _audio = null;
    await _incoming?.cancel();
    _incoming = null;
    final RealtimeSocket? socket = _socket;
    _socket = null;
    await socket?.close();
    // The buffer holds speech. It goes when the session goes (BR-06).
    _buffer.clear();
    _bufferedBytes = 0;
  }

  static Future<void> _wait(Duration duration) =>
      Future<void>.delayed(duration);
}
