import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'domain/ports/clock.dart';
import 'infrastructure/ai/claude_api_engine.dart';
import 'infrastructure/ai/secure_ai_credential_store.dart';
import 'infrastructure/jira/jira_rest_adapter.dart';
import 'infrastructure/jira/outbox_dispatcher.dart';
import 'infrastructure/jira/secure_jira_credential_store.dart';
import 'infrastructure/persistence/drift_meeting_repository.dart';
import 'infrastructure/persistence/drift_meeting_template_repository.dart';
import 'infrastructure/persistence/drift_outbox_repository.dart';
import 'infrastructure/persistence/drift_reminder_repository.dart';
import 'infrastructure/persistence/drift_task_repository.dart';
import 'infrastructure/persistence/drift_voice_settings_store.dart';
import 'infrastructure/persistence/norte_database.dart';
import 'infrastructure/persistence/norte_database_factory.dart';
import 'infrastructure/platform/record_audio_recorder.dart';
import 'infrastructure/platform/record_pcm_microphone.dart';
import 'infrastructure/platform/temp_audio_store.dart';
import 'infrastructure/transcription/scribe_realtime_engine.dart';
import 'infrastructure/transcription/secure_transcription_credential_store.dart';
import 'infrastructure/transcription/whisper_batch_engine.dart';
import 'jira_background_sync.dart';
import 'presentation/app/norte_app.dart';
import 'presentation/jira/jira_providers.dart';
import 'presentation/meetings/meeting_providers.dart';
import 'presentation/tasks/task_providers.dart';
import 'presentation/reminders/reminder_providers.dart';
import 'presentation/voice/voice_providers.dart';

/// Composition root.
///
/// The only place allowed to wire `infrastructure/` adapters into the
/// providers the rest of the app consumes (`docs/project-rules.md` §3) — which
/// is why `presentation/` can declare `taskRepositoryProvider` and
/// `jiraGatewayProvider` without ever importing Drift or dio.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final NorteDatabase database = await openNorteDatabase();
  final DriftTaskRepository tasks = DriftTaskRepository(database);
  final DriftOutboxRepository outbox = DriftOutboxRepository(database);
  final SecureJiraCredentialStore credentials = SecureJiraCredentialStore(
    const FlutterSecureStorage(),
  );
  final JiraRestAdapter jira = JiraRestAdapter(
    dio: Dio(),
    credentialStore: credentials,
    // Diagnostics for the Jira connection, which is the one part of the app
    // that depends on a site nobody here controls. Safe by construction:
    // bodies are never written and every line is swept for credentials
    // (BR-08, `RedactingLogInterceptor`). Run the app from a terminal to
    // read it.
    log: (String line) => debugPrint('[jira] $line'),
  );
  final DriftMeetingRepository meetings = DriftMeetingRepository(database);
  final DriftMeetingTemplateRepository templates =
      DriftMeetingTemplateRepository(database);
  // Safe on every launch: it inserts only ids that are absent, so it neither
  // duplicates a template nor overwrites one the user has edited.
  await templates.seedDefaults();

  final SecureAiCredentialStore aiCredentials = SecureAiCredentialStore(
    const FlutterSecureStorage(),
  );
  final ClaudeApiEngine ai = ClaudeApiEngine(
    dio: Dio(),
    credentialStore: aiCredentials,
    clock: const SystemClock(),
    // A 4xx here is this app's bug, and the response says which. Run from a
    // terminal to read it.
    log: (String line) => debugPrint('[ai] $line'),
  );

  // Two stores, two slots. Batch is Whisper and realtime is Scribe: different
  // services, different credentials, and a user may hold one and not the
  // other.
  final SecureTranscriptionCredentialStore whisperCredentials =
      const SecureTranscriptionCredentialStore.whisper(FlutterSecureStorage());
  final SecureTranscriptionCredentialStore scribeCredentials =
      const SecureTranscriptionCredentialStore.scribe(FlutterSecureStorage());
  final WhisperBatchEngine whisper = WhisperBatchEngine(
    dio: Dio(),
    credentialStore: whisperCredentials,
  );
  final TempAudioStore audio = TempAudioStore();
  final RecordAudioRecorder recorder = RecordAudioRecorder(
    clock: const SystemClock(),
  );

  // The voice pipeline. The microphone is a separate adapter from the meeting
  // recorder and knows no path at all, which is what makes BR-06 structural
  // rather than a rule someone has to remember.
  final RecordPcmMicrophone microphone = RecordPcmMicrophone(
    // Says what the platform said when capture will not start. Run the app
    // from a terminal to read it.
    log: (String line) => debugPrint('[mic] $line'),
  );
  final ScribeRealtimeEngine scribe = ScribeRealtimeEngine(
    credentialStore: scribeCredentials,
    // Diagnostics for the one part of the pipeline no test can exercise: the
    // service's actual wire format (DEC-026). Safe by construction — it
    // reports the *shape* of a frame it could not read, never its text.
    log: (String line) => debugPrint('[voice] $line'),
  );
  final DriftReminderRepository reminders = DriftReminderRepository(database);
  final DriftVoiceSettingsStore voiceSettings = DriftVoiceSettingsStore(
    database,
  );

  final OutboxDispatcher dispatcher = OutboxDispatcher(
    outbox: outbox,
    gateway: jira,
    tasks: tasks,
    clock: const SystemClock(),
  );

  // Mobile keeps syncing while the app is closed; desktop relies on the
  // in-app timer started below (`docs/architecture.md` §12).
  await registerJiraBackgroundSync();

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      taskRepositoryProvider.overrideWithValue(tasks),
      outboxRepositoryProvider.overrideWithValue(outbox),
      jiraGatewayProvider.overrideWithValue(jira),
      jiraCredentialStoreProvider.overrideWithValue(credentials),
      outboxDispatchProvider.overrideWithValue(dispatcher.dispatch),
      outboxRetryProvider.overrideWithValue(dispatcher.retry),
      meetingRepositoryProvider.overrideWithValue(meetings),
      meetingTemplateRepositoryProvider.overrideWithValue(templates),
      aiCredentialStoreProvider.overrideWithValue(aiCredentials),
      aiEngineProvider.overrideWithValue(ai),
      transcriptionCredentialStoreProvider.overrideWithValue(
        whisperCredentials,
      ),
      batchTranscriptionProvider.overrideWithValue(whisper),
      audioStoreProvider.overrideWithValue(audio),
      audioRecorderProvider.overrideWithValue(recorder),
      microphoneProvider.overrideWithValue(microphone),
      realtimeTranscriptionProvider.overrideWithValue(scribe),
      realtimeCredentialStoreProvider.overrideWithValue(scribeCredentials),
      reminderRepositoryProvider.overrideWithValue(reminders),
      voiceSettingsStoreProvider.overrideWithValue(voiceSettings),
    ],
  );
  container.read(jiraSyncControllerProvider).start();

  runApp(
    UncontrolledProviderScope(container: container, child: const NorteApp()),
  );
}
