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
}
