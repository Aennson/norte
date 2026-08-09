// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Norte';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navMeetings => 'Meetings';

  @override
  String get navReminders => 'Reminders';

  @override
  String get navSettings => 'Settings';

  @override
  String get voiceCommandLabel => 'Voice command';

  @override
  String get tasksEmptyMessage => 'No tasks yet.';

  @override
  String get meetingsEmptyMessage => 'No meetings yet.';

  @override
  String get remindersEmptyMessage => 'No reminders yet.';

  @override
  String get settingsEmptyMessage => 'No settings available yet.';

  @override
  String get statusTodo => 'To do';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusDone => 'Done';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionClear => 'Clear';

  @override
  String get tasksNewTask => 'New task';

  @override
  String get tasksEditTask => 'Edit task';

  @override
  String get tasksLoadingLabel => 'Loading tasks';

  @override
  String get tasksErrorMessage => 'Your tasks could not be loaded.';

  @override
  String get tasksFilteredEmptyMessage => 'No task matches this filter.';

  @override
  String get tasksFilterAll => 'All';

  @override
  String get tasksSearchHint => 'Search title and description';

  @override
  String get tasksSearchClear => 'Clear search';

  @override
  String tasksSearchEmptyMessage(String term) {
    return 'Nothing matches “$term”.';
  }

  @override
  String get taskFieldTitle => 'Title';

  @override
  String get taskFieldTitleHint => 'What needs doing?';

  @override
  String get taskFieldTitleRequired => 'A title is required.';

  @override
  String get taskFieldDescription => 'Description';

  @override
  String get taskFieldStatus => 'Status';

  @override
  String get taskFieldPriority => 'Priority';

  @override
  String get taskFieldDueDate => 'Due date';

  @override
  String get taskFieldDueDateEmpty => 'No due date';

  @override
  String get taskFieldTags => 'Tags';

  @override
  String get taskFieldTagsHint => 'Comma separated';

  @override
  String taskDueLabel(String date) {
    return 'Due $date';
  }

  @override
  String get taskMarkDone => 'Mark as done';

  @override
  String get taskMarkNotDone => 'Reopen task';

  @override
  String get taskDeleteTitle => 'Delete task?';

  @override
  String taskDeleteMessage(String title) {
    return '“$title” will be removed permanently. This cannot be undone.';
  }

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortByPriority => 'Priority';

  @override
  String get sortByDueDate => 'Due date';

  @override
  String get jiraSectionTitle => 'Jira';

  @override
  String get jiraSectionDescription =>
      'Link tasks to issues on a Jira Cloud or Server/Data Center site. Your token is kept in the device\'s secure storage and never leaves it.';

  @override
  String get jiraFieldSiteUrl => 'Site URL';

  @override
  String get jiraFieldSiteUrlHint => 'https://your-team.atlassian.net';

  @override
  String get jiraFieldEmail => 'Account e-mail';

  @override
  String get jiraFieldApiToken => 'API token';

  @override
  String get jiraConnectAction => 'Connect';

  @override
  String get jiraDisconnectAction => 'Disconnect';

  @override
  String jiraConnectedAs(String email) {
    return 'Connected as $email';
  }

  @override
  String get jiraNotConnected => 'Not connected.';

  @override
  String get jiraCredentialsIncomplete =>
      'Fill in the site, the e-mail and the token.';

  @override
  String get jiraLinkAction => 'Link to Jira';

  @override
  String get jiraLinkTitle => 'Link a Jira issue';

  @override
  String get jiraFieldIssueKey => 'Issue key';

  @override
  String get jiraFieldIssueKeyHint => 'PROJ-123';

  @override
  String get jiraUnlinkAction => 'Remove Jira link';

  @override
  String get jiraRefreshAction => 'Refresh from Jira';

  @override
  String get jiraCommentAction => 'Comment on Jira';

  @override
  String get jiraCommentTitle => 'Add a comment';

  @override
  String get jiraFieldComment => 'Comment';

  @override
  String get jiraPushStatusAction => 'Send status to Jira';

  @override
  String get jiraCreateIssueAction => 'Create Jira issue';

  @override
  String get jiraCreateIssueTitle => 'Create an issue from this task';

  @override
  String get jiraFieldProjectKey => 'Project key';

  @override
  String get jiraFieldProjectKeyHint => 'PROJ';

  @override
  String get jiraQueuedMessage =>
      'Queued — it will reach Jira as soon as there is a connection.';

  @override
  String jiraErrorIssueNotFound(String issueKey) {
    return 'This site has no issue $issueKey.';
  }

  @override
  String get jiraErrorOffline => 'Linking an issue requires a connection.';

  @override
  String get jiraErrorAuth =>
      'Jira rejected the credentials. Check them in Settings.';

  @override
  String get jiraErrorRateLimited =>
      'Jira is throttling requests. Try again shortly.';

  @override
  String get jiraErrorGeneric => 'Jira could not be reached.';

  @override
  String get jiraNotConfiguredMessage =>
      'Connect a Jira site in Settings first.';

  @override
  String jiraSyncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String jiraSyncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes could not be sent',
      one: '1 change could not be sent',
    );
    return '$_temp0';
  }

  @override
  String get jiraSyncRetryAction => 'Retry';

  @override
  String jiraLastSyncedLabel(String date) {
    return 'Synced $date';
  }

  @override
  String get jiraNeverSyncedLabel => 'Never synced';

  @override
  String get jiraDivergenceTitle => 'Jira disagrees with the local status';

  @override
  String jiraDivergenceMessage(String local, String issueKey, String remote) {
    return 'Here this task is “$local”; on $issueKey it is “$remote”. Nothing changes until you choose.';
  }

  @override
  String get jiraDivergenceKeepLocal => 'Keep local';

  @override
  String get jiraDivergenceAdoptRemote => 'Adopt from Jira';

  @override
  String get jiraFieldDeployment => 'Jira type';

  @override
  String get jiraDeploymentCloud => 'Cloud';

  @override
  String get jiraDeploymentDataCenter => 'Server / Data Center';

  @override
  String get jiraFieldApiTokenDataCenter => 'Personal access token';

  @override
  String get jiraErrorNotRestApi =>
      'That URL answered, but not as the Jira REST API — check the site address, and whether the site is behind single sign-on.';

  @override
  String get meetingsNewMeeting => 'New meeting';

  @override
  String get meetingsLoadingLabel => 'Loading meetings';

  @override
  String get meetingsErrorMessage => 'Could not load your meetings.';

  @override
  String meetingsActionItemSummary(int total, int converted) {
    return '$converted of $total action items converted';
  }

  @override
  String get meetingsTranscriptKept => 'Transcript kept';

  @override
  String get meetingsTranscriptDiscarded => 'Transcript discarded';

  @override
  String get meetingTypeDaily => 'Daily';

  @override
  String get meetingTypeRetro => 'Retro';

  @override
  String get meetingTypePlanning => 'Planning';

  @override
  String get meetingTypeOneOnOne => '1:1';

  @override
  String get meetingTypeCustom => 'Custom';

  @override
  String get newMeetingTitle => 'New meeting';

  @override
  String get newMeetingTitleField => 'Title';

  @override
  String get newMeetingTitleRequired => 'Give the meeting a title.';

  @override
  String get newMeetingTypeLabel => 'Meeting type';

  @override
  String get newMeetingTranscriptField => 'Transcript';

  @override
  String get newMeetingTranscriptHint =>
      'Paste the transcript from Teams, Meet, or anywhere else.';

  @override
  String get newMeetingTranscriptRequired => 'Paste a transcript first.';

  @override
  String get newMeetingSaveTranscript => 'Save the transcript too';

  @override
  String get newMeetingSaveTranscriptOn =>
      'The full text will be stored alongside the summary.';

  @override
  String get newMeetingSaveTranscriptOff =>
      'Only the summary is kept. The text is discarded when you leave.';

  @override
  String get newMeetingProcess => 'Summarize';

  @override
  String get newMeetingProcessing => 'Summarizing…';

  @override
  String get newMeetingNoTemplates =>
      'No templates. Restore the defaults in Settings.';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryGone => 'That summary is no longer in memory.';

  @override
  String get summaryEmptySection => 'Not covered in this meeting.';

  @override
  String get summaryActionItems => 'Follow-ups';

  @override
  String get summaryConvert => 'Make a task';

  @override
  String get summaryConverted => 'Converted';

  @override
  String get summaryConvertedToast => 'Task created.';

  @override
  String get summaryAlreadyConverted => 'That action item is already a task.';

  @override
  String get summarySave => 'Save summary';

  @override
  String get summarySaved => 'Summary saved.';

  @override
  String get summaryDiscardWarning =>
      'Nothing is saved yet. Leaving this screen discards the summary and the transcript.';

  @override
  String get summaryDiscardWarningWithTranscript =>
      'Nothing is saved yet. Leaving this screen discards the summary and the transcript you chose to keep.';

  @override
  String get aiSectionTitle => 'Claude';

  @override
  String get aiSectionDescription =>
      'Meeting summaries use your own Claude API key. It is stored in this device\'s secure storage and never leaves it except to call the API.';

  @override
  String get aiKeyField => 'API key';

  @override
  String get aiKeyFieldHint => 'sk-ant-…';

  @override
  String get aiKeyRequired => 'Paste your API key.';

  @override
  String get aiKeyConfigured => 'Key configured';

  @override
  String get aiKeyNotConfigured => 'No key configured';

  @override
  String get aiClearKey => 'Remove key';

  @override
  String get aiErrorMissingKey =>
      'Add your Claude API key in Settings to summarize meetings.';

  @override
  String get aiErrorRejectedKey =>
      'Claude rejected that API key. Check it in Settings.';

  @override
  String get aiErrorUnreadable =>
      'Claude answered with something this app could not read. Try again.';

  @override
  String get aiErrorRateLimited =>
      'Claude is rate limiting right now. Try again shortly.';

  @override
  String get aiErrorOffline => 'Cannot reach Claude. Check your connection.';

  @override
  String get aiErrorTimeout => 'Claude did not answer in time. Try again.';

  @override
  String get aiErrorStorage => 'Could not read this device\'s secure storage.';

  @override
  String get aiErrorGeneric => 'Summarizing failed. Try again.';

  @override
  String get templatesSectionTitle => 'Meeting templates';

  @override
  String get templatesSectionDescription =>
      'A template is the instruction and the headings a summary is built from. Edit them to match how your team runs its meetings.';

  @override
  String get templatesEdit => 'Edit';

  @override
  String get templatesRestoreDefaults => 'Restore the built-in templates';

  @override
  String get templatesPromptField => 'Instruction';

  @override
  String get templatesSectionsField => 'Sections';

  @override
  String get templatesSectionsHint =>
      'One heading per line, in the order they should appear.';

  @override
  String get templatesExtractActionItems => 'Extract action items';

  @override
  String get recordMeetingTitle => 'Record meeting';

  @override
  String get recordMeetingStart => 'Record audio';

  @override
  String get recordMeetingStartHint =>
      'Record the meeting and have it transcribed for you.';

  @override
  String get recordMeetingReady => 'Ready to record';

  @override
  String get recordMeetingRecording => 'Recording';

  @override
  String get recordMeetingPaused => 'Paused';

  @override
  String get recordMeetingPause => 'Pause';

  @override
  String get recordMeetingResume => 'Resume';

  @override
  String get recordMeetingStop => 'Stop and transcribe';

  @override
  String get recordMeetingDiscard => 'Discard recording';

  @override
  String get recordMeetingDiscardConfirm =>
      'Discard this recording? The audio is deleted and cannot be recovered.';

  @override
  String get recordMeetingLimitLabel => 'Maximum length';

  @override
  String recordMeetingLimitValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get recordMeetingInterrupted =>
      'Recording paused by the system. Resume when you are ready - nothing was lost.';

  @override
  String get recordMeetingStageUploading => 'Uploading the audio';

  @override
  String get recordMeetingStageTranscribing => 'Transcribing';

  @override
  String get recordMeetingStageSummarizing => 'Summarizing';

  @override
  String get recordMeetingKeepAudio =>
      'The recording is kept so you can try again without recording it over.';

  @override
  String get recordMeetingPermissionTitle => 'Microphone access is off';

  @override
  String get recordMeetingPermissionBody =>
      'Norte needs the microphone to record a meeting. The audio stays on this device until you send it for transcription, and it is deleted afterwards.';

  @override
  String get recordMeetingPermissionAllow => 'Allow microphone';

  @override
  String get recordMeetingPermissionSettings => 'Open settings';

  @override
  String get recordMeetingPermissionPermanent =>
      'The prompt will not appear again - grant microphone access in your system settings.';

  @override
  String get transcriptionErrorFailed =>
      'The audio could not be transcribed. Try again.';

  @override
  String get transcriptionErrorNoKey =>
      'No transcription key is configured. Add one in Settings.';

  @override
  String get transcriptionErrorRejected =>
      'The transcription key was rejected. Check it in Settings.';

  @override
  String get transcriptionErrorTooLong =>
      'The recording is too long to upload.';

  @override
  String get recordingErrorFailed =>
      'The recording could not be made. Try again.';

  @override
  String get settingsWhisperSection => 'Transcription';

  @override
  String get settingsWhisperDescription =>
      'Your own transcription key. It is stored in this device\'s secure store and never leaves it except to transcribe your audio.';

  @override
  String get settingsWhisperKeyField => 'Transcription API key';

  @override
  String get settingsWhisperConfigured => 'Key configured';

  @override
  String get voiceConnecting => 'Connecting…';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceUnderstanding => 'Understanding…';

  @override
  String get voiceStop => 'Stop';

  @override
  String get voiceNotUnderstood =>
      'I did not catch a command. Try saying it another way.';

  @override
  String get voiceConfirmTitle => 'Confirm this action';

  @override
  String get voiceReasonJiraWrite =>
      'Jira writes always ask first. You can change this in Settings.';

  @override
  String get voiceReasonLowConfidence =>
      'I am not certain I understood. Check it before it runs.';

  @override
  String voiceConfidenceLabel(int percent) {
    return 'Confidence $percent%';
  }

  @override
  String get voiceAskIssueKey => 'Which ticket?';

  @override
  String get voiceAskTransition => 'Which status?';

  @override
  String get voiceAskComment => 'What should the comment say?';

  @override
  String get voiceAskTitle => 'What should the task be called?';

  @override
  String get voiceAskText => 'What should I remind you about?';

  @override
  String get voiceAskTriggerAt => 'For when?';

  @override
  String voiceActionUpdateJira(String issueKey, String transition) {
    return '$issueKey → $transition';
  }

  @override
  String voiceActionAddComment(String issueKey, String comment) {
    return 'Comment on $issueKey: $comment';
  }

  @override
  String voiceActionCreateTask(String title) {
    return 'New task: $title';
  }

  @override
  String voiceActionCreateReminder(String text, String triggerAt) {
    return 'Remind $text — $triggerAt';
  }

  @override
  String voiceActionQueryStatus(String issueKey) {
    return 'Status of $issueKey';
  }

  @override
  String get voiceDoneTask => 'Task created';

  @override
  String get voiceDoneQueued => 'Queued for Jira';

  @override
  String get voiceDoneReminder => 'Reminder created';

  @override
  String voiceDoneStatus(String issueKey, String status) {
    return '$issueKey is $status';
  }

  @override
  String voiceErrorNotLinked(String issueKey) {
    return 'No task here is linked to $issueKey.';
  }

  @override
  String get voiceAskTaskRef => 'Which task?';

  @override
  String get voiceAskChange => 'Change it to what?';

  @override
  String voiceActionUpdateTask(String taskRef) {
    return 'Change $taskRef';
  }

  @override
  String voiceActionDeleteTask(String taskRef) {
    return 'Delete $taskRef';
  }

  @override
  String voiceActionCommentTask(String taskRef, String comment) {
    return 'Note on $taskRef: $comment';
  }

  @override
  String get voiceReasonDeletion =>
      'Deleting a task cannot be undone, so this always asks.';

  @override
  String voiceDoneTaskUpdated(String title) {
    return 'Task updated: $title';
  }

  @override
  String voiceDoneTaskDeleted(String title) {
    return 'Deleted $title';
  }

  @override
  String voiceDoneTaskCommented(String title) {
    return 'Note added to $title — it stays on your list';
  }

  @override
  String voiceTaskNotFound(String reference) {
    return 'No task called “$reference”.';
  }

  @override
  String voiceTaskAmbiguous(String candidates) {
    return 'Which one — $candidates?';
  }

  @override
  String get settingsVoiceSection => 'Voice';

  @override
  String get settingsVoiceDescription =>
      'How spoken commands behave before they change anything.';

  @override
  String get settingsAlwaysConfirmJira => 'Always confirm Jira writes';

  @override
  String get settingsAlwaysConfirmJiraDescription =>
      'Ask before every spoken transition or comment, however sure the app is. Low-confidence commands always ask, whatever this is set to.';

  @override
  String get settingsScribeKeyField => 'Realtime voice API key';

  @override
  String get settingsScribeDescription =>
      'Your ElevenLabs Scribe key, used only for voice commands. It is a different service from the transcription key above — meetings go to Whisper, spoken commands go to Scribe, and each keeps its own key.';

  @override
  String get settingsScribeConfigured => 'Realtime key configured';

  @override
  String get settingsScribeNotConfigured =>
      'No realtime key — voice commands will not run';

  @override
  String get voiceMeterLabel => 'Microphone level';

  @override
  String get voiceNoAudio => 'The microphone is open but no sound is arriving.';

  @override
  String get voiceReconnecting => 'Connection lost — reconnecting…';

  @override
  String get voiceTimeUnsupported =>
      'This app cannot work out that time yet. Try \"in 20 minutes\".';

  @override
  String get voiceFailed => 'Stopped';

  @override
  String get settingsScribeKeyHint => 'sk_...';
}
