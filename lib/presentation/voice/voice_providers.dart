import 'dart:async';
import 'dart:typed_data';

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
import '../../domain/ports/transcription_engine.dart';
import '../../domain/ports/voice_settings_store.dart';
import '../jira/jira_providers.dart';
import '../meetings/meeting_providers.dart';
import '../tasks/task_providers.dart';
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

/// The user's voice preferences, live.
///
/// A stream rather than a one-shot read: flipping the switch in Settings has
/// to reach the next command, not the next launch.
final StreamProvider<VoiceSettings> voiceSettingsProvider =
    StreamProvider<VoiceSettings>(
      (Ref ref) => ref.watch(voiceSettingsStoreProvider).watch(),
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
    createReminder: ref.watch(createReminderProvider),
    updateJiraStatus: ref.watch(updateJiraStatusProvider),
    addJiraComment: ref.watch(addJiraCommentProvider),
    refreshJiraStatus: ref.watch(refreshJiraStatusProvider),
    // Defaults until the store answers. The default confirms, so a command
    // spoken in the first milliseconds after launch is not treated more
    // leniently than one spoken later.
    settings:
        ref.watch(voiceSettingsProvider).valueOrNull ?? const VoiceSettings(),
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
    this.executed,
    this.failure,
    this.notUnderstood = false,
    this.latency,
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

  /// Set once a command ran.
  final IntentExecuted? executed;

  final Failure? failure;

  /// `true` when the utterance was not understood — a state, not an error.
  final bool notUnderstood;

  /// Committed speech → intent ready, for the diagnostics log
  /// (`sprint-05` validation rules).
  final Duration? latency;

  VoiceSessionState copyWith({
    VoicePhase? phase,
    bool? isActive,
    String? partial,
    String? committed,
    VoiceIntent? intent,
    ConfirmationRequired? confirming,
    SlotMissing? askingFor,
    IntentExecuted? executed,
    Failure? failure,
    bool? notUnderstood,
    Duration? latency,
    bool clearPartial = false,
    bool clearConfirming = false,
    bool clearAsking = false,
    bool clearFailure = false,
  }) => VoiceSessionState(
    phase: phase ?? this.phase,
    isActive: isActive ?? this.isActive,
    partial: clearPartial ? null : partial ?? this.partial,
    committed: committed ?? this.committed,
    intent: intent ?? this.intent,
    confirming: clearConfirming ? null : confirming ?? this.confirming,
    askingFor: clearAsking ? null : askingFor ?? this.askingFor,
    executed: executed ?? this.executed,
    failure: clearFailure ? null : failure ?? this.failure,
    notUnderstood: notUnderstood ?? this.notUnderstood,
    latency: latency ?? this.latency,
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

  /// When the last committed segment arrived, for the latency measurement.
  DateTime? _committedAt;

  @override
  VoiceSessionState build() {
    ref.onDispose(() => unawaited(_events?.cancel()));
    return const VoiceSessionState();
  }

  /// Opens the microphone and the realtime session.
  Future<void> start() async {
    if (state.isActive) return;
    state = const VoiceSessionState(
      isActive: true,
      phase: VoicePhase.connecting,
    );

    final Microphone microphone = ref.read(microphoneProvider);
    final RealtimeTranscription engine = ref.read(
      realtimeTranscriptionProvider,
    );

    final Stream<Uint8List> pcm = microphone.open();
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

    state = state.copyWith(phase: VoicePhase.listening);
  }

  /// Ends the session — the user pressed stop, or the command finished.
  Future<void> stop() async {
    await _events?.cancel();
    _events = null;
    await ref.read(realtimeTranscriptionProvider).stop();
    await ref.read(microphoneProvider).close();
    state = const VoiceSessionState();
  }

  /// The user said yes on the confirmation sheet.
  Future<void> confirm() async {
    final ConfirmationRequired? pending = state.confirming;
    if (pending == null) return;
    state = state.copyWith(clearConfirming: true);
    await _execute(pending.intent, confirmed: true);
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
      state = state.copyWith(partial: event.text);
      return;
    }

    _committedAt = ref.read(clockProvider).now();
    state = state.copyWith(
      committed: event.text,
      phase: VoicePhase.understanding,
      clearPartial: true,
    );
    unawaited(_onCommitted(event.text));
  }

  Future<void> _onCommitted(String utterance) async {
    // The microphone has done its job; closing it now is what makes the pause
    // between speaking and acting a pause rather than a recording.
    await ref.read(microphoneProvider).close();

    await _parseAndRoute(
      utterance,
      context: IntentContext(
        locale: _locale,
        knownIssueKeys: await _knownIssueKeys(),
      ),
    );
  }

  Future<void> _parseAndRoute(
    String utterance, {
    required IntentContext context,
  }) async {
    final Result<VoiceIntent> parsed = await ref
        .read(intentParserProvider)
        .parse(utterance, context: context);

    switch (parsed) {
      case Err<VoiceIntent>(:final Failure failure):
        _onFailure(failure);
        return;
      case Ok<VoiceIntent>(:final VoiceIntent value):
        _recordLatency();
        state = state.copyWith(intent: value);
        await _execute(value);
    }
  }

  Future<void> _execute(VoiceIntent intent, {bool confirmed = false}) async {
    final Result<RouteOutcome> routed = await ref
        .read(intentRouterProvider)
        .route(intent, confirmed: confirmed);

    switch (routed) {
      case Err<RouteOutcome>(:final Failure failure):
        _onFailure(failure);
      case Ok<RouteOutcome>(value: final IntentExecuted executed):
        state = state.copyWith(executed: executed);
      case Ok<RouteOutcome>(value: final ConfirmationRequired pending):
        state = state.copyWith(confirming: pending, phase: VoicePhase.asking);
      case Ok<RouteOutcome>(value: final SlotMissing asking):
        state = state.copyWith(askingFor: asking, phase: VoicePhase.asking);
      case Ok<RouteOutcome>(value: IntentNotUnderstood()):
        state = state.copyWith(notUnderstood: true, phase: VoicePhase.asking);
    }
  }

  void _onFailure(Object error) {
    state = state.copyWith(
      failure: error is Failure ? error : const EngineFailure(),
      phase: VoicePhase.asking,
    );
  }

  /// Records committed-speech → intent-ready, the p95 the sprint measures.
  void _recordLatency() {
    final DateTime? committedAt = _committedAt;
    if (committedAt == null) return;
    _committedAt = null;
    state = state.copyWith(
      latency: ref.read(clockProvider).now().difference(committedAt),
    );
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
