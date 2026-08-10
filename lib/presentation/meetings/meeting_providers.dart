import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/usecases/convert_action_item_to_task.dart';
import '../../application/usecases/save_meeting.dart';
import '../../application/usecases/summarize_meeting.dart';
import '../../application/usecases/transcribe_meeting_audio.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_template.dart';
import '../../domain/failures/failure.dart';
import '../../domain/failures/result.dart';
import '../../domain/ports/ai_credential_store.dart';
import '../../domain/ports/audio_recorder.dart';
import '../../domain/ports/audio_store.dart';
import '../../domain/ports/meeting_repository.dart';
import '../../domain/ports/meeting_template_repository.dart';
import '../../domain/ports/transcription_credential_store.dart';
import '../../domain/ports/transcription_engine.dart';
import '../settings/ai_engine_providers.dart';
import '../tasks/task_providers.dart';

/// `aiEngineProvider` moved to `../settings/ai_engine_providers.dart` in
/// Sprint 07 and is re-exported here so that every existing caller keeps
/// working unchanged.
///
/// **It stopped being a port and became a computation.** The composition root
/// used to build one engine and override this with it; §7.3's selection reads
/// the user's preference, which can change while the app is running, so an
/// engine fixed at launch would go on being the one chosen then. What the root
/// overrides now is the pieces — the remote engine and the two CLI builders —
/// and the choice between them is made on every read.
export '../settings/ai_engine_providers.dart' show aiEngineProvider;

final Provider<AiCredentialStore> aiCredentialStoreProvider =
    Provider<AiCredentialStore>(
      (Ref ref) => throw UnimplementedError(
        'aiCredentialStoreProvider must be overridden in the composition root',
      ),
    );

final Provider<MeetingRepository> meetingRepositoryProvider =
    Provider<MeetingRepository>(
      (Ref ref) => throw UnimplementedError(
        'meetingRepositoryProvider must be overridden in the composition root',
      ),
    );

final Provider<MeetingTemplateRepository> meetingTemplateRepositoryProvider =
    Provider<MeetingTemplateRepository>(
      (Ref ref) => throw UnimplementedError(
        'meetingTemplateRepositoryProvider must be overridden in the '
        'composition root',
      ),
    );

final Provider<TranscriptionCredentialStore>
transcriptionCredentialStoreProvider = Provider<TranscriptionCredentialStore>(
  (Ref ref) => throw UnimplementedError(
    'transcriptionCredentialStoreProvider must be overridden in the '
    'composition root',
  ),
);

final Provider<AudioRecorder> audioRecorderProvider = Provider<AudioRecorder>(
  (Ref ref) => throw UnimplementedError(
    'audioRecorderProvider must be overridden in the composition root',
  ),
);

final Provider<AudioStore> audioStoreProvider = Provider<AudioStore>(
  (Ref ref) => throw UnimplementedError(
    'audioStoreProvider must be overridden in the composition root',
  ),
);

final Provider<BatchTranscription> batchTranscriptionProvider =
    Provider<BatchTranscription>(
      (Ref ref) => throw UnimplementedError(
        'batchTranscriptionProvider must be overridden in the composition root',
      ),
    );

/// How long a single recording may run.
///
/// Ninety minutes by default, which covers a long planning session; it is a
/// provider rather than a constant because the sprint requires it to be
/// configurable, and because the right ceiling on a phone with 2 GB free is
/// not the right ceiling on a desktop.
final Provider<Duration> recordingLimitProvider = Provider<Duration>(
  (Ref ref) => const Duration(minutes: 90),
);

/// The three meeting use cases, assembled from the ports above.
final Provider<SummarizeMeeting> summarizeMeetingProvider =
    Provider<SummarizeMeeting>(
      (Ref ref) => SummarizeMeeting(
        engine: ref.watch(aiEngineProvider),
        clock: ref.watch(clockProvider),
        idGenerator: ref.watch(idGeneratorProvider),
      ),
    );

/// Sprint 04's use case, holding Sprint 03's rather than repeating it.
final Provider<TranscribeMeetingAudio> transcribeMeetingAudioProvider =
    Provider<TranscribeMeetingAudio>(
      (Ref ref) => TranscribeMeetingAudio(
        engine: ref.watch(batchTranscriptionProvider),
        store: ref.watch(audioStoreProvider),
        summarize: ref.watch(summarizeMeetingProvider),
      ),
    );

final Provider<SaveMeeting> saveMeetingProvider = Provider<SaveMeeting>(
  (Ref ref) => SaveMeeting(repository: ref.watch(meetingRepositoryProvider)),
);

final Provider<DeleteMeeting> deleteMeetingProvider = Provider<DeleteMeeting>(
  (Ref ref) => DeleteMeeting(repository: ref.watch(meetingRepositoryProvider)),
);

final Provider<ConvertActionItemToTask> convertActionItemProvider =
    Provider<ConvertActionItemToTask>(
      (Ref ref) => ConvertActionItemToTask(
        tasks: ref.watch(taskRepositoryProvider),
        meetings: ref.watch(meetingRepositoryProvider),
        clock: ref.watch(clockProvider),
        idGenerator: ref.watch(idGeneratorProvider),
      ),
    );

/// The saved meetings, straight from Drift's `watch` — the list redraws on
/// every mutation and never polls (`sprint-01` validation rules).
final StreamProvider<List<Meeting>> meetingListProvider =
    StreamProvider<List<Meeting>>(
      (Ref ref) => ref.watch(meetingRepositoryProvider).watchAll(),
    );

/// The templates the user can summarize under.
final StreamProvider<List<MeetingTemplate>> meetingTemplateListProvider =
    StreamProvider<List<MeetingTemplate>>(
      (Ref ref) => ref.watch(meetingTemplateRepositoryProvider).watchAll(),
    );

/// `true` when a Claude API key is configured.
///
/// A `FutureProvider` rather than a cached bool so that saving a key in
/// Settings updates the meetings screen without a restart. Note what it does
/// **not** expose: the key itself never leaves the store (BR-08).
final FutureProvider<bool> aiConfiguredProvider = FutureProvider<bool>(
  (Ref ref) async => await ref.watch(aiCredentialStoreProvider).read() != null,
);

/// `true` when a transcription key is configured. Separate from
/// [aiConfiguredProvider] because the two keys are separate: recording works
/// without a Claude key right up to the summarizing stage, and pasting works
/// without a Whisper key entirely.
final FutureProvider<bool> transcriptionConfiguredProvider =
    FutureProvider<bool>(
      (Ref ref) async =>
          await ref.watch(transcriptionCredentialStoreProvider).read() != null,
    );

/// What the composer screen is doing right now.
enum MeetingComposerStatus { editing, processing, failed, summarized }

/// State of the "paste a transcript and summarize it" flow.
class MeetingComposerState {
  const MeetingComposerState({
    this.status = MeetingComposerStatus.editing,
    this.template,
    this.retention = RetentionPolicy.ephemeral,
    this.meeting,
    this.failure,
  });

  final MeetingComposerStatus status;

  /// The template the user picked. `null` until the list loads.
  final MeetingTemplate? template;

  /// **The user's BR-03 choice, made before processing.** It travels with the
  /// meeting from here so that whatever saves it later cannot get it wrong.
  final RetentionPolicy retention;

  /// The summarized meeting, held **in memory only**. Leaving the result
  /// screen without saving discards it, transcript and all (BR-03).
  final Meeting? meeting;

  /// Why the last attempt failed, for the retry affordance.
  final Failure? failure;

  MeetingComposerState copyWith({
    MeetingComposerStatus? status,
    MeetingTemplate? template,
    RetentionPolicy? retention,
    Meeting? meeting,
    Failure? failure,
    bool clearFailure = false,
    bool clearMeeting = false,
  }) => MeetingComposerState(
    status: status ?? this.status,
    template: template ?? this.template,
    retention: retention ?? this.retention,
    meeting: clearMeeting ? null : meeting ?? this.meeting,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

/// Drives the new-meeting → summary → convert flow.
///
/// **The transcript is not held here.** It lives in the screen's
/// `TextEditingController` and is passed in on [summarize]; the summarized
/// `Meeting` carries it onward in memory. Nothing writes it anywhere until
/// [save] runs, and `SaveMeeting` strips it unless the user opted in (BR-03).
class MeetingComposer extends Notifier<MeetingComposerState> {
  @override
  MeetingComposerState build() => const MeetingComposerState();

  /// Chooses the template, and with it the meeting type.
  void selectTemplate(MeetingTemplate template) {
    state = state.copyWith(template: template);
  }

  /// Records the user's retention choice — offered **before** processing,
  /// which is the only point at which it is an informed one (BR-03).
  void setRetention(RetentionPolicy retention) {
    state = state.copyWith(retention: retention);
  }

  /// Takes over a meeting summarized by another flow.
  ///
  /// Sprint 04's recording flow ends here, which is the point: from this call
  /// onward there is one summary screen, one save path and one BR-03 gate, no
  /// matter whether the transcript was pasted or spoken. A second result
  /// screen would have been a second place for `SaveMeeting`'s retention rule
  /// to be got wrong.
  void adopt(Meeting meeting) {
    state = state.copyWith(
      status: MeetingComposerStatus.summarized,
      meeting: meeting,
      clearFailure: true,
    );
  }

  /// Clears everything, including any in-memory transcript.
  ///
  /// Called when the user leaves the result screen without saving. This *is*
  /// the discard in "leaving the screen discards it".
  void reset() {
    state = const MeetingComposerState();
  }

  /// Summarizes [transcript] under the selected template.
  Future<void> summarize({
    required String transcript,
    required String title,
  }) async {
    final MeetingTemplate? template = state.template;
    if (template == null) return;

    state = state.copyWith(
      status: MeetingComposerStatus.processing,
      clearFailure: true,
    );

    final Result<Meeting> result = await ref.read(summarizeMeetingProvider)(
      transcript: transcript,
      template: template,
      title: title,
      retention: state.retention,
    );

    state = switch (result) {
      Ok<Meeting>(:final Meeting value) => state.copyWith(
        status: MeetingComposerStatus.summarized,
        meeting: value,
        clearFailure: true,
      ),
      Err<Meeting>(:final Failure failure) => state.copyWith(
        status: MeetingComposerStatus.failed,
        failure: failure,
      ),
    };
  }

  /// Persists the summary the user is looking at.
  Future<Failure?> save() async {
    final Meeting? meeting = state.meeting;
    if (meeting == null) return null;

    final Result<Meeting> result = await ref.read(saveMeetingProvider)(meeting);
    return switch (result) {
      // The stored form comes back — so the screen stops showing a transcript
      // the app has just committed to forgetting.
      Ok<Meeting>(:final Meeting value) => () {
        state = state.copyWith(meeting: value);
        return null;
      }(),
      Err<Meeting>(:final Failure failure) => failure,
    };
  }

  /// Converts one action item into a task.
  Future<Failure?> convert(String itemId) async {
    final Meeting? meeting = state.meeting;
    if (meeting == null) return null;

    final Result<ActionItemConversion> result = await ref.read(
      convertActionItemProvider,
    )(meeting: meeting, itemId: itemId);

    return switch (result) {
      Ok<ActionItemConversion>(:final ActionItemConversion value) => () {
        state = state.copyWith(meeting: value.meeting);
        return null;
      }(),
      Err<ActionItemConversion>(:final Failure failure) => failure,
    };
  }
}

final NotifierProvider<MeetingComposer, MeetingComposerState>
meetingComposerProvider =
    NotifierProvider<MeetingComposer, MeetingComposerState>(
      MeetingComposer.new,
    );
