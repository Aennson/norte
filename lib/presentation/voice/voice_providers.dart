import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/usecases/create_reminder.dart';
import '../../application/voice/intent_parser.dart';
import '../../application/voice/intent_router.dart';
import '../../domain/entities/intent_context.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/voice_intent.dart';
import '../../domain/entities/voice_settings.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/microphone.dart';
import '../../domain/ports/reminder_repository.dart';
import '../../domain/ports/transcription_credential_store.dart';
import '../../domain/ports/transcription_engine.dart';
import '../../domain/ports/voice_settings_store.dart';
import '../jira/jira_providers.dart';
import '../meetings/meeting_providers.dart';
import '../tasks/task_providers.dart';
import '../../domain/services/text_match.dart';
import 'audio_level.dart';
import 'speech_filler.dart';
import 'voice_latency_log.dart';
import 'widgets/voice_overlay.dart';

/// The microphone, as a PCM stream. Overridden in the composition root.
final Provider<Microphone> microphoneProvider = Provider<Microphone>(
  (Ref ref) => throw UnimplementedError('wired in main.dart'),
);

/// The realtime transcription engine. Overridden in the composition root.
final Provider<RealtimeTranscription> realtimeTranscriptionProvider =
    Provider<RealtimeTranscription>(
      (Ref ref) => throw UnimplementedError('wired in main.dart'),
    );

/// The **Scribe** key — a different service from Whisper's, under a different
/// slot in the secure store. Overridden in the composition root.
final Provider<TranscriptionCredentialStore> realtimeCredentialStoreProvider =
    Provider<TranscriptionCredentialStore>(
      (Ref ref) => throw UnimplementedError('wired in main.dart'),
    );

/// `true` when a realtime transcription key is configured.
///
/// Invalidated by the settings section after a write, as
/// `transcriptionConfiguredProvider` is.
final FutureProvider<bool> realtimeConfiguredProvider = FutureProvider<bool>((
  Ref ref,
) async {
  final String? key = await ref.watch(realtimeCredentialStoreProvider).read();
  return key != null && key.trim().isNotEmpty;
});

/// Storage for the voice preferences. Overridden in the composition root.
final Provider<VoiceSettingsStore> voiceSettingsStoreProvider =
    Provider<VoiceSettingsStore>(
      (Ref ref) => throw UnimplementedError('wired in main.dart'),
    );

/// Storage for reminders. Overridden in the composition root.
final Provider<ReminderRepository> reminderRepositoryProvider =
    Provider<ReminderRepository>(
      (Ref ref) => throw UnimplementedError('wired in main.dart'),
    );

/// Where the session writes what it decided, for the manual pass.
///
/// The engine and the microphone each got a log when their step turned out to
/// be the one nobody could see. This is the third step — commit, parse,
/// route — and it stayed dark through two rounds of debugging while the
/// Developer and I guessed at which of them had failed.
///
/// **It logs shapes, never speech**: the length of a committed segment, the
/// intent's type and confidence, the outcome's class. A transcript does not go
/// in a log (BR-06).
final Provider<void Function(String)> voiceLogProvider =
    Provider<void Function(String)>(
      (Ref ref) => (String line) {
        debugPrint('[voice] $line');
      },
    );

/// The rolling latency window the sprint's p95 is read from.
///
/// A provider so the manual pass can read it, and so a test can assert that
/// the pipeline measures at all rather than merely claiming to.
final Provider<VoiceLatencyLog> voiceLatencyLogProvider =
    Provider<VoiceLatencyLog>((Ref ref) => VoiceLatencyLog(sink: debugPrint));

/// The user's voice preferences, for the Settings screen to render.
///
/// A read rather than a stream, and invalidated by the screen after a write —
/// the pattern `aiConfiguredProvider` and `transcriptionConfiguredProvider`
/// already use. The **pipeline** does not go through here at all: `IntentRouter`
/// reads the store itself when it needs to know, so no confirmation decision
/// can ever depend on whether a provider had refreshed yet.
final FutureProvider<VoiceSettings> voiceSettingsProvider =
    FutureProvider<VoiceSettings>(
      (Ref ref) => ref.watch(voiceSettingsStoreProvider).read(),
    );

final Provider<CreateReminder> createReminderProvider =
    Provider<CreateReminder>(
      (Ref ref) => CreateReminder(
        repository: ref.watch(reminderRepositoryProvider),
        clock: ref.watch(clockProvider),
        idGenerator: ref.watch(idGeneratorProvider),
      ),
    );

final Provider<IntentParser> intentParserProvider = Provider<IntentParser>(
  (Ref ref) => IntentParser(engine: ref.watch(aiEngineProvider)),
);

final Provider<IntentRouter> intentRouterProvider = Provider<IntentRouter>(
  (Ref ref) => IntentRouter(
    tasks: ref.watch(taskRepositoryProvider),
    createTask: ref.watch(createTaskProvider),
    updateTask: ref.watch(updateTaskProvider),
    deleteTask: ref.watch(deleteTaskProvider),
    commentTask: ref.watch(commentTaskProvider),
    createReminder: ref.watch(createReminderProvider),
    updateJiraStatus: ref.watch(updateJiraStatusProvider),
    addJiraComment: ref.watch(addJiraCommentProvider),
    refreshJiraStatus: ref.watch(refreshJiraStatusProvider),
    // The store itself: the router reads it when it needs to know, which
    // removes the window in which a stream had not yet emitted.
    settings: ref.watch(voiceSettingsStoreProvider),
  ),
);

/// Where a voice session has got to.
class VoiceSessionState {
  const VoiceSessionState({
    this.phase = VoicePhase.connecting,
    this.isActive = false,
    this.partial,
    this.committed,
    this.intent,
    this.confirming,
    this.askingFor,
    this.choosing,
    this.notFound,
    this.executed,
    this.failure,
    this.notUnderstood = false,
    this.latency,
    this.level = 0,
    this.framesHeard = 0,
  });

  final VoicePhase phase;

  /// `true` between the button press and the session closing.
  final bool isActive;

  /// The provisional transcript. Replaced by each event, never appended.
  final String? partial;

  /// The transcript VAD closed.
  final String? committed;

  /// What the parser made of [committed].
  final VoiceIntent? intent;

  /// Set while the confirmation sheet is up (BR-04).
  final ConfirmationRequired? confirming;

  /// Set while the app is waiting for one missing slot.
  final SlotMissing? askingFor;

  /// Set while the app is waiting for the user to pick between tasks whose
  /// titles all matched what they said (§6.3.1, case 2).
  final TaskAmbiguous? choosing;

  /// Set when a spoken `taskRef` matched no task. Nothing was changed.
  final TaskNotFound? notFound;

  /// Set once a command ran.
  final IntentExecuted? executed;

  final Failure? failure;

  /// `true` when the utterance was not understood — a state, not an error.
  final bool notUnderstood;

  /// The last command's latency, broken down by the service that spent it
  /// (`sprint-05` validation rules).
  final VoiceLatencySample? latency;

  /// Input level in `0.0..1.0`, measured from the PCM actually captured.
  ///
  /// Not an animation. A meter driven by a timer looks identical whether the
  /// microphone works or not, which is an assurance the app cannot honestly
  /// give — and the exact confusion this field exists to end.
  final double level;

  /// Frames of audio captured since the session opened.
  ///
  /// `0` after a second or two of "listening" means the microphone is open and
  /// producing nothing, which is a different problem from a service that is
  /// not answering — and the screen says so rather than leaving both looking
  /// like silence.
  final int framesHeard;

  /// `true` once any audio at all has arrived from the microphone.
  bool get hasHeardAudio => framesHeard > 0;

  VoiceSessionState copyWith({
    VoicePhase? phase,
    bool? isActive,
    String? partial,
    String? committed,
    VoiceIntent? intent,
    ConfirmationRequired? confirming,
    SlotMissing? askingFor,
    TaskAmbiguous? choosing,
    TaskNotFound? notFound,
    IntentExecuted? executed,
    Failure? failure,
    bool? notUnderstood,
    VoiceLatencySample? latency,
    double? level,
    int? framesHeard,
    bool clearPartial = false,
    bool clearConfirming = false,
    bool clearAsking = false,
    bool clearChoosing = false,
    bool clearNotFound = false,
    bool clearFailure = false,
  }) => VoiceSessionState(
    phase: phase ?? this.phase,
    isActive: isActive ?? this.isActive,
    partial: clearPartial ? null : partial ?? this.partial,
    committed: committed ?? this.committed,
    intent: intent ?? this.intent,
    confirming: clearConfirming ? null : confirming ?? this.confirming,
    askingFor: clearAsking ? null : askingFor ?? this.askingFor,
    choosing: clearChoosing ? null : choosing ?? this.choosing,
    notFound: clearNotFound ? null : notFound ?? this.notFound,
    executed: executed ?? this.executed,
    failure: clearFailure ? null : failure ?? this.failure,
    notUnderstood: notUnderstood ?? this.notUnderstood,
    latency: latency ?? this.latency,
    level: level ?? this.level,
    framesHeard: framesHeard ?? this.framesHeard,
  );
}

/// Drives one voice command from the button press to the outcome
/// (`docs/architecture.md` §6.1).
///
/// **The committed transcript is the trigger, not the partials.** Partials are
/// shown and thrown away; only a committed segment is parsed, and only a
/// parsed intent is routed. Acting on a partial would mean acting on a
/// sentence the user had not finished saying.
///
/// **Nothing here holds audio.** The PCM stream goes from the microphone into
/// the engine and is never copied, buffered or written by this class (BR-06).
class VoiceSession extends Notifier<VoiceSessionState> {
  StreamSubscription<TranscriptEvent>? _events;
  StreamSubscription<bool>? _connection;

  /// When the last committed segment arrived, for the latency measurement.
  DateTime? _committedAt;

  /// When the most recent partial of the segment being spoken arrived.
  ///
  /// The only anchor this side of the socket has for "the user had finished
  /// speaking", and therefore the only way to charge Scribe's silence window
  /// to Scribe rather than to Claude. Snapshotted and cleared the moment a
  /// commit arrives — the session listens continuously, so partials of the
  /// *next* utterance start landing while this one is still being parsed, and
  /// reading it at record time would measure the wrong sentence.
  DateTime? _lastPartialAt;

  /// The last partial of the segment currently in flight, taken at commit.
  DateTime? _heardAt;

  /// `true` while a segment is being parsed or routed.
  ///
  /// The session listens continuously and executes commands as they are
  /// spoken, so segments keep arriving while an earlier one is still in
  /// flight. This is what stops the second half of one sentence being read as
  /// a second command — VAD segments on silence, and a pause mid-sentence
  /// used to execute twice.
  bool _busy = false;

  /// `true` once the container is gone, so an in-flight [stop] does not try to
  /// read providers that no longer exist.
  ///
  /// The pipeline is asynchronous and the user can close the app in the middle
  /// of it; without this, quitting mid-command throws from inside a `Future`
  /// nobody is awaiting.
  bool _disposed = false;

  @override
  VoiceSessionState build() {
    ref.onDispose(() {
      _disposed = true;
      unawaited(_events?.cancel());
      unawaited(_connection?.cancel());
    });
    return const VoiceSessionState();
  }

  /// Opens the microphone and the realtime session.
  Future<void> start() async {
    if (state.isActive) return;
    state = const VoiceSessionState(
      isActive: true,
      phase: VoicePhase.connecting,
    );
    _busy = false;
    _committedAt = null;
    _lastPartialAt = null;
    _heardAt = null;

    // Warm the intent cache while the socket dials and the user draws breath.
    // The first command of a session used to write the cache rather than read
    // it — 7406 ms against ~2900 ms warm — which put the worst request the app
    // makes on the command the user judges the feature by. Unawaited on
    // purpose: nothing here waits for it, and it cannot fail loudly.
    unawaited(ref.read(intentParserProvider).primeCache());

    final Microphone microphone = ref.read(microphoneProvider);
    final RealtimeTranscription engine = ref.read(
      realtimeTranscriptionProvider,
    );

    // The audio is tapped on its way past, never held: a frame goes in, a
    // level comes out, and the bytes carry on to the engine untouched (BR-06).
    final Stream<Uint8List> pcm = microphone.open().map(_measure);

    // The socket decides when "listening" becomes true. Saying it from the
    // button press would be claiming to hear someone while still dialling.
    _connection = engine.isConnected.listen(_onConnectionChanged);

    _events = engine
        .start(pcm)
        .listen(
          _onEvent,
          onError: _onFailure,
          onDone: () {
            if (state.isActive && state.phase == VoicePhase.listening) {
              state = state.copyWith(phase: VoicePhase.understanding);
            }
          },
        );
  }

  /// One frame of PCM, measured and passed on unchanged.
  ///
  /// **Nothing in here may break the pipeline.** It sits in a `map` on the
  /// microphone stream, so anything it throws becomes a stream error and ends
  /// the session — which is exactly what happened when the level maths met a
  /// frame at an odd byte offset: one frame captured, session dead, and a
  /// microphone left recording for nobody.
  ///
  /// The measurement is a diagnostic. A diagnostic that can kill the thing it
  /// is measuring is worse than none, so the frame goes through whatever
  /// happens here.
  Uint8List _measure(Uint8List frame) {
    try {
      if (!_disposed && state.isActive) {
        state = state.copyWith(
          level: AudioLevel.smooth(state.level, AudioLevel.of(frame)),
          framesHeard: state.framesHeard + 1,
        );
      }
    } catch (_) {
      // A meter that cannot read this frame is a flat meter for 100ms, not a
      // lost command.
    }
    return frame;
  }

  void _onConnectionChanged(bool connected) {
    if (_disposed || !state.isActive) return;
    // Only the two phases the connection owns. A session that has committed
    // speech and is parsing it must not be dragged back to "listening"
    // because the socket happened to reconnect.
    if (state.phase == VoicePhase.connecting && connected) {
      state = state.copyWith(phase: VoicePhase.listening);
    } else if (state.phase == VoicePhase.listening && !connected) {
      state = state.copyWith(phase: VoicePhase.connecting, level: 0);
    }
  }

  /// Ends the session — the user pressed stop, or the command finished.
  Future<void> stop() async {
    await _events?.cancel();
    _events = null;
    await _connection?.cancel();
    _connection = null;
    if (_disposed) return;
    await ref.read(realtimeTranscriptionProvider).stop();
    await ref.read(microphoneProvider).close();
    if (_disposed) return;
    state = const VoiceSessionState();
  }

  /// The user said yes on the confirmation sheet.
  Future<void> confirm() async {
    final ConfirmationRequired? pending = state.confirming;
    if (pending == null) return;
    state = state.copyWith(clearConfirming: true);
    // The id the sheet was about, not the phrase it came from. Re-resolving
    // would ask the list a second question, and a task created between the
    // sheet appearing and the user tapping yes could change the answer.
    await _execute(pending.intent, confirmed: true, taskId: pending.task?.id);
  }

  /// The user said no. Nothing ran, so there is nothing to undo.
  Future<void> cancel() => stop();

  /// Answers the app's question about a missing slot.
  ///
  /// The answer is re-parsed **with the earlier intent as context**, so
  /// "PROJ-123" completes the transition rather than being read as a new
  /// command (S05-UT-05).
  Future<void> answerSlot(String answer) async {
    final SlotMissing? asking = state.askingFor;
    if (asking == null) return;

    state = state.copyWith(phase: VoicePhase.understanding, clearAsking: true);

    await _parseAndRoute(
      answer,
      context: IntentContext(
        locale: _locale,
        knownIssueKeys: await _knownIssueKeys(),
        pendingIntent: asking.intent.type,
        providedSlots: asking.intent.slots,
      ),
    );
  }

  // --- the pipeline -------------------------------------------------------

  void _onEvent(TranscriptEvent event) {
    if (!event.isCommitted) {
      // The clock is read here and nowhere else for this stage: an empty
      // partial is the service clearing its buffer, not a word heard, and
      // anchoring on it would charge Scribe's silence window to itself twice.
      if (event.text.trim().isNotEmpty) {
        _lastPartialAt = ref.read(clockProvider).now();
      }
      state = state.copyWith(partial: event.text);
      return;
    }

    // Whatever this commit turns out to be — an utterance, a filler, or a
    // segment dropped below — it consumes the partials that preceded it. The
    // anchor is taken and cleared here so that a dropped commit cannot leave a
    // stale one behind to inflate the next measurement.
    final DateTime? heardAt = _lastPartialAt;
    _lastPartialAt = null;

    // An empty commit is the service closing a segment, not an utterance.
    // Parsing it started a race the real segment could lose — and did: the
    // empty one returned `unknown` in three milliseconds while the real one
    // was still in flight, and overwrote it.
    if (event.text.trim().isEmpty) {
      _log('committed segment: empty — not an utterance');
      return;
    }

    // Hesitation is not a command. Parsing it costs an API call, a second of
    // the user's time, and an `unknown` that reads on screen as the app
    // failing to understand — when nothing was said.
    if (SpeechFiller.isOnlyFiller(event.text)) {
      _log('committed segment: filler only — ignored');
      state = state.copyWith(clearPartial: true);
      return;
    }

    // A confirmation is on screen and a mutation is one tap away. Anything
    // said now is the user reading, not a new command.
    if (state.confirming != null) {
      _log('committed segment ignored — a confirmation is waiting');
      return;
    }

    // VAD segments on silence, so one sentence can arrive in pieces. Without
    // this, a pause mid-sentence executed the command twice.
    if (_busy) {
      _log(
        'committed segment: ${event.text.length} chars — ignored, the '
        'previous one is still in flight',
      );
      return;
    }
    _busy = true;

    _committedAt = ref.read(clockProvider).now();
    _heardAt = heardAt;
    _log('committed segment: ${event.text.length} chars');
    state = state.copyWith(
      committed: event.text,
      phase: VoicePhase.understanding,
      level: 0,
      clearPartial: true,
    );
    unawaited(_onCommitted(event.text));
  }

  Future<void> _onCommitted(String utterance) async {
    // **The microphone stays open.** The session listens until the user stops
    // it and acts on commands as they are spoken; closing after each one made
    // every command a separate press of the button.
    try {
      // A segment spoken while a question is on screen **is the answer**. Read
      // as a fresh command it would be nonsense — "PROJ-123" on its own names
      // no action — and the user would be told to rephrase the very thing the
      // app asked them for (S05-UT-05).
      if (state.askingFor != null) {
        await answerSlot(utterance);
        return;
      }

      // Same reasoning for the "which of these two?" question: "de novo" is
      // not a command, it is the answer to what the app just asked.
      if (state.choosing != null) {
        await chooseTask(utterance);
        return;
      }

      await _parseAndRoute(
        utterance,
        context: IntentContext(
          locale: _locale,
          knownIssueKeys: await _knownIssueKeys(),
        ),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> _parseAndRoute(
    String utterance, {
    required IntentContext context,
  }) async {
    // The two readings that bracket Claude. Everything between the commit and
    // the first of them — the known-issue-key read that grounds the prompt —
    // is ours, and is charged to us.
    final DateTime requestedAt = ref.read(clockProvider).now();
    final Result<VoiceIntent> parsed = await ref
        .read(intentParserProvider)
        .parse(utterance, context: context);
    final DateTime answeredAt = ref.read(clockProvider).now();

    switch (parsed) {
      case Err<VoiceIntent>(:final Failure failure):
        _log('parse failed — ${failure.runtimeType}: ${failure.message}');
        _onFailure(failure);
        return;
      case Ok<VoiceIntent>(:final VoiceIntent value):
        _recordLatency(requestedAt: requestedAt, answeredAt: answeredAt);
        _log(
          'parsed ${value.type.name} at ${value.confidence.toStringAsFixed(2)}'
          ', slots ${value.slots.keys.toList()}',
        );
        state = state.copyWith(intent: value);
        await _execute(value);
    }
  }

  Future<void> _execute(
    VoiceIntent intent, {
    bool confirmed = false,
    String? taskId,
  }) async {
    final Result<RouteOutcome> routed = await ref
        .read(intentRouterProvider)
        .route(intent, confirmed: confirmed, taskId: taskId);

    switch (routed) {
      case Err<RouteOutcome>(:final Failure failure):
        _onFailure(failure);
      case Ok<RouteOutcome>(value: final IntentExecuted executed):
        state = state.copyWith(executed: executed);
      case Ok<RouteOutcome>(value: final ConfirmationRequired pending):
        state = state.copyWith(confirming: pending, phase: VoicePhase.asking);
      case Ok<RouteOutcome>(value: final SlotMissing asking):
        state = state.copyWith(askingFor: asking, phase: VoicePhase.asking);
      case Ok<RouteOutcome>(value: final TaskAmbiguous ambiguous):
        state = state.copyWith(choosing: ambiguous, phase: VoicePhase.asking);
      case Ok<RouteOutcome>(value: final TaskNotFound missing):
        // Not a failure. The pipeline worked perfectly and the answer is that
        // there is no such task — which is information, not an error, and the
        // session stays open so the user can simply say another name.
        state = state.copyWith(notFound: missing, phase: VoicePhase.asking);
      case Ok<RouteOutcome>(value: IntentNotUnderstood()):
        state = state.copyWith(notUnderstood: true, phase: VoicePhase.asking);
    }
  }

  /// Answers a [TaskAmbiguous] by naming one of the candidates out loud.
  ///
  /// The spoken answer is matched against the candidates **only** — never
  /// against the whole list — so a reply that fits none of them re-asks rather
  /// than acting on some fourth task the user never mentioned. And it is
  /// matched here rather than sent back to the model: the choice is between
  /// rows the app is holding, which is a comparison, not an interpretation.
  Future<void> chooseTask(String answer) async {
    final TaskAmbiguous? choosing = state.choosing;
    if (choosing == null) return;

    final List<Task> matches = <Task>[
      for (final Task task in choosing.candidates)
        if (TextMatch.contains(task.title, answer)) task,
    ];
    // An answer that fits two of them has not chosen. The question stands.
    if (matches.length != 1) return;

    state = state.copyWith(
      clearChoosing: true,
      phase: VoicePhase.understanding,
    );
    await _execute(choosing.intent, taskId: matches.single.id);
  }

  void _log(String line) {
    if (_disposed) return;
    ref.read(voiceLogProvider)(line);
  }

  void _onFailure(Object error) {
    final Failure failure = error is Failure ? error : const EngineFailure();
    // A failed *command* is not a failed session. If the microphone is still
    // open the user can simply say it again, which is what they asked for:
    // keep everything until the command goes through. Only a failure that
    // takes the pipeline down stops the session.
    final bool fatal =
        !state.isActive ||
        failure is MissingApiKeyFailure ||
        failure is AuthFailure ||
        failure is MicrophonePermissionFailure ||
        failure is RecordingFailure;

    state = state.copyWith(
      failure: failure,
      phase: fatal ? VoicePhase.failed : VoicePhase.listening,
      level: fatal ? 0 : null,
    );
  }

  /// Records one command's latency, split across the three parties that spent
  /// it: Scribe, us, and Claude.
  ///
  /// Sprint 05 recorded commit → intent-ready as one number and the report had
  /// to say "3973 ms" without being able to say whose. Three fields, three
  /// answerable questions.
  void _recordLatency({
    required DateTime requestedAt,
    required DateTime answeredAt,
  }) {
    final DateTime? committedAt = _committedAt;
    if (committedAt == null) return;
    final DateTime? heardAt = _heardAt;
    _committedAt = null;
    _heardAt = null;

    final VoiceLatencySample sample = VoiceLatencySample(
      transcription: heardAt == null ? null : committedAt.difference(heardAt),
      grounding: requestedAt.difference(committedAt),
      parse: answeredAt.difference(requestedAt),
    );
    ref.read(voiceLatencyLogProvider).record(sample);
    state = state.copyWith(latency: sample);
  }

  /// The issue keys the user has actually linked, as grounding for the parser.
  Future<List<String>> _knownIssueKeys() async {
    final List<Task> tasks = await ref.read(taskRepositoryProvider).listAll();
    return <String>[
      for (final Task task in tasks)
        if (task.jiraLink case final link?) link.issueKey,
    ];
  }

  /// The app's locale, which is the language the user is speaking (BR-11).
  String get _locale => ref.read(voiceLocaleProvider);
}

/// BCP-47 tag of the language voice commands are expected in.
///
/// Overridden by the widget layer with the resolved app locale. It is a
/// provider rather than a `BuildContext` lookup because the session lives
/// outside the widget tree, and a pipeline that read the locale from a context
/// would be a pipeline that could not run without one.
final Provider<String> voiceLocaleProvider = Provider<String>(
  (Ref ref) => 'pt-BR',
);

final NotifierProvider<VoiceSession, VoiceSessionState> voiceSessionProvider =
    NotifierProvider<VoiceSession, VoiceSessionState>(VoiceSession.new);
