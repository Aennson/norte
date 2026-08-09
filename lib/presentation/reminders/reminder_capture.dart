import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/intent_context.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/microphone.dart';
import '../../domain/ports/transcription_engine.dart';
import '../voice/voice_providers.dart';
import 'reminder_providers.dart';

/// How long push-to-talk will listen before it stops on its own
/// (`sprint-06` scope: "push-to-talk ≤15s").
const Duration reminderCaptureLimit = Duration(seconds: 15);

/// Where a push-to-talk capture has got to.
class ReminderCaptureState {
  const ReminderCaptureState({
    this.isCapturing = false,
    this.secondsLeft = 15,
    this.partial,
    this.limitReached = false,
    this.created,
    this.failure,
    this.askingForTime = false,
  });

  /// `true` between the press and the capture ending.
  final bool isCapturing;

  /// Seconds remaining before the limit cuts it off. Counts 15 → 0.
  final int secondsLeft;

  /// The provisional transcript, shown and thrown away.
  final String? partial;

  /// `true` when the limit ended the capture rather than the user.
  final bool limitReached;

  /// The reminder the last capture produced.
  final Reminder? created;

  final Failure? failure;

  /// `true` when the utterance named no time and the app is asking for one
  /// (S06-E2E-02). Nothing has been persisted while this is set.
  final bool askingForTime;

  ReminderCaptureState copyWith({
    bool? isCapturing,
    int? secondsLeft,
    String? partial,
    bool? limitReached,
    Reminder? created,
    Failure? failure,
    bool? askingForTime,
    bool clearPartial = false,
    bool clearFailure = false,
    bool clearCreated = false,
  }) => ReminderCaptureState(
    isCapturing: isCapturing ?? this.isCapturing,
    secondsLeft: secondsLeft ?? this.secondsLeft,
    partial: clearPartial ? null : partial ?? this.partial,
    limitReached: limitReached ?? this.limitReached,
    created: clearCreated ? null : created ?? this.created,
    failure: clearFailure ? null : failure ?? this.failure,
    askingForTime: askingForTime ?? this.askingForTime,
  );
}

/// Drives one push-to-talk reminder capture (`docs/architecture.md` §8).
///
/// **Push-to-talk, not the continuous session.** `VoiceSession` stays open
/// until the user closes it because a command is one of many; a reminder is a
/// single short sentence, and a microphone left open on the reminders screen
/// would be recording a person who has finished speaking. The 15-second limit
/// is the same reasoning made explicit.
///
/// **Nothing here holds audio** (BR-06). The PCM frames go from the microphone
/// into the engine and are never copied, buffered or written; the partial
/// transcripts are replaced as they arrive and discarded when the capture ends.
///
/// **The missing-time question does not persist anything.** An utterance with
/// no `triggerAt` leaves [ReminderCaptureState.askingForTime] set and the
/// reminder unbuilt — S06-E2E-02 asserts the database is still empty at that
/// point, because a reminder saved without a time is one that never fires.
class ReminderCapture extends Notifier<ReminderCaptureState> {
  StreamSubscription<TranscriptEvent>? _events;
  Timer? _limit;
  Timer? _tick;

  /// The intent that was understood but left `triggerAt` empty, held while the
  /// app asks for it.
  VoiceIntent? _awaitingTime;

  bool _disposed = false;

  @override
  ReminderCaptureState build() {
    ref.onDispose(() {
      _disposed = true;
      _limit?.cancel();
      _tick?.cancel();
      unawaited(_events?.cancel());
    });
    return const ReminderCaptureState();
  }

  /// Opens the microphone and starts the countdown.
  Future<void> start() async {
    if (state.isCapturing) return;
    _awaitingTime = null;
    state = const ReminderCaptureState(isCapturing: true);

    final Microphone microphone = ref.read(microphoneProvider);
    final RealtimeTranscription engine = ref.read(
      realtimeTranscriptionProvider,
    );

    try {
      final Stream<Uint8List> pcm = microphone.open();
      _events = engine.start(pcm).listen(_onEvent, onError: _onFailure);
    } on Failure catch (failure) {
      _onFailure(failure);
      return;
    }

    _tick = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_disposed || !state.isCapturing) return;
      state = state.copyWith(secondsLeft: (state.secondsLeft - 1).clamp(0, 15));
    });
    // Stopping *itself* rather than merely reporting the limit: a microphone
    // that stayed open after the countdown hit zero would be a countdown that
    // meant nothing.
    _limit = Timer(reminderCaptureLimit, () {
      if (_disposed || !state.isCapturing) return;
      state = state.copyWith(limitReached: true);
      unawaited(stop());
    });
  }

  /// Closes the microphone and the session. Idempotent.
  Future<void> stop() async {
    _limit?.cancel();
    _tick?.cancel();
    _limit = null;
    _tick = null;
    await _events?.cancel();
    _events = null;
    if (_disposed) return;
    await ref.read(realtimeTranscriptionProvider).stop();
    await ref.read(microphoneProvider).close();
    if (_disposed) return;
    state = state.copyWith(isCapturing: false, clearPartial: true);
  }

  /// Creates a reminder from text the user typed — the fallback for a place
  /// with no microphone, or a person who would rather not talk to their
  /// laptop.
  Future<void> createManually({
    required String text,
    required String triggerAt,
  }) async {
    _awaitingTime = null;
    state = state.copyWith(
      askingForTime: false,
      clearFailure: true,
      clearCreated: true,
    );
    await _create(text: text, triggerAt: triggerAt);
  }

  /// Answers the app's "for when?" with a spoken or typed time.
  ///
  /// The answer completes the slot the earlier utterance left empty; the text
  /// is the one already understood, so answering the question cannot change
  /// what the reminder says.
  Future<void> answerTime(String triggerAt) async {
    final VoiceIntent? pending = _awaitingTime;
    if (pending == null) return;
    _awaitingTime = null;
    state = state.copyWith(askingForTime: false);
    await _create(text: pending.slotText('text') ?? '', triggerAt: triggerAt);
  }

  /// Discards the last outcome, so the screen stops showing it.
  void acknowledge() => state = state.copyWith(
    clearCreated: true,
    clearFailure: true,
    limitReached: false,
  );

  void _onEvent(TranscriptEvent event) {
    if (_disposed) return;
    if (!event.isCommitted) {
      state = state.copyWith(partial: event.text);
      return;
    }
    if (event.text.trim().isEmpty) return;
    unawaited(_onCommitted(event.text));
  }

  Future<void> _onCommitted(String utterance) async {
    // One sentence is the whole capture, so the microphone closes here rather
    // than waiting for the limit — the user has said their piece.
    await stop();
    if (_disposed) return;

    final Result<VoiceIntent> parsed = await ref
        .read(intentParserProvider)
        .parse(
          utterance,
          context: IntentContext(
            locale: ref.read(voiceLocaleProvider),
            // The screen the user is on *is* context. Without it "responder o
            // e-mail às nove" on the reminders screen is as likely to be read
            // as a task as a reminder.
            pendingIntent: IntentType.createReminder,
          ),
        );

    switch (parsed) {
      case Err<VoiceIntent>(:final Failure failure):
        _onFailure(failure);
      case Ok<VoiceIntent>(:final VoiceIntent value):
        final String? text = value.slotText('text');
        if (text == null || text.trim().isEmpty) {
          _onFailure(const ValidationFailure('nothing to be reminded of'));
          return;
        }
        final String? triggerAt = value.slotText('triggerAt');
        if (triggerAt == null || triggerAt.trim().isEmpty) {
          // Nothing is persisted here. The app asks, and the answer is what
          // completes the reminder (S06-E2E-02).
          _awaitingTime = value;
          state = state.copyWith(askingForTime: true);
          return;
        }
        await _create(text: text, triggerAt: triggerAt);
    }
  }

  Future<void> _create({
    required String text,
    required String triggerAt,
  }) async {
    final Result<Reminder> created = await ref.read(
      createVoiceReminderProvider,
    )(text: text, triggerAt: triggerAt);
    if (_disposed) return;

    switch (created) {
      case Ok<Reminder>(:final Reminder value):
        state = state.copyWith(created: value, clearFailure: true);
      case Err<Reminder>(:final Failure failure):
        _onFailure(failure);
    }
  }

  void _onFailure(Object error) {
    if (_disposed) return;
    state = state.copyWith(
      failure: error is Failure ? error : const EngineFailure(),
      isCapturing: false,
    );
  }
}

final NotifierProvider<ReminderCapture, ReminderCaptureState>
reminderCaptureProvider =
    NotifierProvider<ReminderCapture, ReminderCaptureState>(
      ReminderCapture.new,
    );
