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

  /// Language hint as a **BCP-47 tag** — `pt-BR`, `en`, `it` — or `null` to
  /// let the service detect it.
  ///
  /// The app speaks BCP-47 everywhere (BR-11, `IntentContext.locale`), and the
  /// service speaks ISO-639-3. [_iso639_3] does the conversion, and this is
  /// where it belongs: an adapter exists to keep a service's vocabulary out of
  /// the rest of the app.
  ///
  /// It matters more than it looks. The first draft passed the tag straight
  /// through, and the service does not merely ignore what it cannot read — it
  /// answers `invalid_request` and closes with 1008, so **every session would
  /// have died on the handshake** the moment a language was configured.
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

  final StreamController<bool> _connected = StreamController<bool>.broadcast();
  bool _isConnected = false;

  /// Frames of audio handed to the socket since the session opened.
  ///
  /// Diagnostic only. It is a count, not a copy — nothing here retains audio
  /// (BR-06).
  int _framesSent = 0;

  @override
  TranscriptionMode get mode => TranscriptionMode.realtime;

  @override
  Stream<bool> get isConnected async* {
    yield _isConnected;
    yield* _connected.stream;
  }

  void _setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    if (!_connected.isClosed) _connected.add(value);
    log?.call(value ? 'socket open' : 'socket closed');
  }

  /// Bytes currently held for replay. Never more than [maxBufferedBytes].
  int get bufferedBytes => _bufferedBytes;

  @override
  Stream<TranscriptEvent> start(Stream<Uint8List> pcm16k) {
    final StreamController<TranscriptEvent> events =
        StreamController<TranscriptEvent>();
    _events = events;
    _stopped = false;
    _audioEnded = false;
    _framesSent = 0;
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

    // No control frame on the way out. The first draft sent
    // `{"type":"flush"}` here — a message this protocol does not have. The
    // service answers `input_error: Message must be a valid protocol message`
    // and drops the connection (DEC-026). Commits are VAD-driven server-side,
    // which is what `vad_commit_strategy` in the session config means, so
    // closing the socket is the whole of the goodbye.
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
      if (_iso639_3(language) case final String code) 'language_code': code,
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
        _setConnected(true);
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
    _setConnected(false);
    if (_stopped || _events == null) return;
    log?.call('socket dropped after $_framesSent audio frames — reconnecting');
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
      if (_framesSent == 0) {
        log?.call('first audio frame sent (${chunk.length} bytes)');
      }
      _framesSent++;
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
    // The microphone closed — the user let go of the button. Nothing is sent:
    // there is no commit message in this protocol, and the one the first draft
    // invented got the session dropped. VAD closes the segment from the
    // silence that follows, which is what `min_silence_duration_ms` in the
    // session config is for.
    _audioEnded = true;
  }

  // --- messages ----------------------------------------------------------

  /// Reads one service frame.
  ///
  /// **The shapes here are observed, not assumed** — they come from a live
  /// session against the service (DEC-026, settled). The discriminator is
  /// `message_type`, *not* `type`, which is what the first draft read and why
  /// it would have understood nothing at all:
  ///
  /// ```json
  /// {"message_type": "session_started", "session_id": "...", "config": {}}
  /// {"message_type": "input_error",     "error": "Unexpected message type: x"}
  /// {"message_type": "invalid_request", "error": "Invalid language code..."}
  /// ```
  ///
  /// Errors carry a **flat `error` string**, not a nested object with a typed
  /// code — the first draft read `error.type` and would have found nothing.
  ///
  /// Transcript frames are still read tolerantly (`partial`/`final`/
  /// `committed` in the name, `is_final`, `text`/`transcript`), because the
  /// live session never produced one: a synthetic tone is not speech, and this
  /// account's key cannot reach TTS to make any. That single unknown is what
  /// the manual pass settles, and [log] is what it will read.
  void _onMessage(Object? frame) {
    final Object? decoded = switch (frame) {
      final String text => _tryDecode(text),
      final List<int> bytes => _tryDecode(
        utf8.decode(bytes, allowMalformed: true),
      ),
      _ => null,
    };
    if (decoded is! Map<String, Object?>) return;

    // `type` stays as a fallback rather than being dropped: it costs one `??`
    // and means a rename in either direction still reads.
    final String type = switch (decoded['message_type'] ?? decoded['type']) {
      final String value => value,
      _ => '',
    };

    if (type.contains('error') || type == 'invalid_request') {
      _fail(_failureFor(type, decoded['error']));
      return;
    }

    // Session bookkeeping, not speech. Named, so it is not reported as an
    // unrecognised frame on every single session.
    if (type == 'session_started' || type == 'session_ended') return;

    final String? text = switch (decoded['text'] ?? decoded['transcript']) {
      final String value => value,
      _ => null,
    };
    if (text == null) {
      log?.call(
        'unrecognised frame: message_type="$type", '
        'keys=${decoded.keys.toList()} — no `text` or `transcript` field',
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

  /// Maps a service error frame onto a [Failure].
  ///
  /// The service sends a human sentence, not a typed code, so the mapping
  /// reads the sentence. That is less elegant than matching on a code and it
  /// is what is actually on the wire; the code the first draft matched on was
  /// the more elegant fiction.
  Failure _failureFor(String type, Object? error) {
    final String message = switch (error) {
      final String text => text,
      _ => 'the transcription service refused the session',
    };
    final String lower = message.toLowerCase();

    if (lower.contains('permission') ||
        lower.contains('unauthorized') ||
        lower.contains('api key')) {
      return const AuthFailure(
        'the transcription service rejected the API key',
      );
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return const RateLimitFailure(
        'the transcription service is rate limiting',
      );
    }
    // `input_error` and `invalid_request` mean this app sent something wrong,
    // not that the user said something wrong. Surfacing it as a validation
    // failure would point them at their own speech.
    return TranscriptionFailure(
      'the transcription service refused the session ($type)',
    );
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
    _setConnected(false);
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

  /// [tag] as the ISO-639-3 code the service accepts, or `null` when there is
  /// no tag or none this app supports.
  ///
  /// Only the three languages BR-11 names are mapped. An unmapped tag returns
  /// `null`, so the service **detects** the language — a better outcome than
  /// sending a code it will reject and close the session over. Guessing at a
  /// fourth language's code would be inventing support the app does not have.
  static String? _iso639_3(String? tag) =>
      switch (tag?.split(RegExp('[-_]')).first.toLowerCase()) {
        'pt' => 'por',
        'en' => 'eng',
        'it' => 'ita',
        _ => null,
      };

  static Future<void> _wait(Duration duration) =>
      Future<void>.delayed(duration);
}
