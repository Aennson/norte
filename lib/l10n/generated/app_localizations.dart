import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
    Locale('pt'),
  ];

  /// Application name, shown as the window/task title.
  ///
  /// In en, this message translates to:
  /// **'Norte'**
  String get appTitle;

  /// Navigation label for the tasks destination.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// Navigation label for the meetings destination.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get navMeetings;

  /// Navigation label for the reminders destination.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navReminders;

  /// Navigation label for the settings destination.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Accessible label of the floating voice button.
  ///
  /// In en, this message translates to:
  /// **'Voice command'**
  String get voiceCommandLabel;

  /// Empty state of the tasks screen.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet.'**
  String get tasksEmptyMessage;

  /// Empty state of the meetings screen.
  ///
  /// In en, this message translates to:
  /// **'No meetings yet.'**
  String get meetingsEmptyMessage;

  /// Empty state of the reminders screen.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet.'**
  String get remindersEmptyMessage;

  /// Empty state of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'No settings available yet.'**
  String get settingsEmptyMessage;

  /// Status badge label for a task that has not started.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// Status badge label for a task being worked on.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// Status badge label for a completed task.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// Status badge label for a blocked task.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// Generic confirmation button label.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// Generic cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic destructive button label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Button label that retries the failed operation.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Button label that saves an edited task.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Button label that creates a new task.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// Button label that empties an optional field, such as a due date.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// Label of the action that opens the task editor for a new task.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get tasksNewTask;

  /// Title of the task editor when changing an existing task.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get tasksEditTask;

  /// Accessible label of the loading skeleton on the tasks screen.
  ///
  /// In en, this message translates to:
  /// **'Loading tasks'**
  String get tasksLoadingLabel;

  /// Error state of the tasks screen, shown above the retry button.
  ///
  /// In en, this message translates to:
  /// **'Your tasks could not be loaded.'**
  String get tasksErrorMessage;

  /// Empty state shown when a filter is active and matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No task matches this filter.'**
  String get tasksFilteredEmptyMessage;

  /// Filter chip that clears the status filter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tasksFilterAll;

  /// Label of the task title input.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskFieldTitle;

  /// Placeholder of the task title input.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get taskFieldTitleHint;

  /// Validation message shown when the task title is blank.
  ///
  /// In en, this message translates to:
  /// **'A title is required.'**
  String get taskFieldTitleRequired;

  /// Label of the optional task description input.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskFieldDescription;

  /// Label of the task status selector.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get taskFieldStatus;

  /// Label of the task priority selector.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskFieldPriority;

  /// Label of the optional task due date.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskFieldDueDate;

  /// Shown in the due date field when the task has none.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get taskFieldDueDateEmpty;

  /// Label of the task tags input.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get taskFieldTags;

  /// Placeholder explaining how to type several tags.
  ///
  /// In en, this message translates to:
  /// **'Comma separated'**
  String get taskFieldTagsHint;

  /// Due date shown on a task card.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String taskDueLabel(String date);

  /// Accessible label of the control that completes a task.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get taskMarkDone;

  /// Accessible label of the control that reopens a completed task.
  ///
  /// In en, this message translates to:
  /// **'Reopen task'**
  String get taskMarkNotDone;

  /// Title of the destructive confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get taskDeleteTitle;

  /// Body of the destructive confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed permanently. This cannot be undone.'**
  String taskDeleteMessage(String title);

  /// Lowest task priority.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Default task priority.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// High task priority.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// Highest task priority.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// Label of the task ordering selector.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// Ordering option: most urgent first.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get sortByPriority;

  /// Ordering option: soonest deadline first.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get sortByDueDate;

  /// Title of the Jira configuration section in Settings.
  ///
  /// In en, this message translates to:
  /// **'Jira'**
  String get jiraSectionTitle;

  /// Explanatory text under the Jira settings title.
  ///
  /// In en, this message translates to:
  /// **'Link tasks to issues on a Jira Cloud site. Your API token is kept in the device\'s secure storage and never leaves it.'**
  String get jiraSectionDescription;

  /// Label of the Jira site URL field.
  ///
  /// In en, this message translates to:
  /// **'Site URL'**
  String get jiraFieldSiteUrl;

  /// Placeholder of the Jira site URL field.
  ///
  /// In en, this message translates to:
  /// **'https://your-team.atlassian.net'**
  String get jiraFieldSiteUrlHint;

  /// Label of the Atlassian account e-mail field.
  ///
  /// In en, this message translates to:
  /// **'Account e-mail'**
  String get jiraFieldEmail;

  /// Label of the Jira API token field.
  ///
  /// In en, this message translates to:
  /// **'API token'**
  String get jiraFieldApiToken;

  /// Button that stores the Jira credentials.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get jiraConnectAction;

  /// Button that clears the stored Jira credentials.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get jiraDisconnectAction;

  /// Shown when Jira credentials are stored.
  ///
  /// In en, this message translates to:
  /// **'Connected as {email}'**
  String jiraConnectedAs(String email);

  /// Shown when no Jira credentials are stored.
  ///
  /// In en, this message translates to:
  /// **'Not connected.'**
  String get jiraNotConnected;

  /// Validation message when a credential field is empty.
  ///
  /// In en, this message translates to:
  /// **'Fill in the site, the e-mail and the token.'**
  String get jiraCredentialsIncomplete;

  /// Task action that attaches a Jira issue.
  ///
  /// In en, this message translates to:
  /// **'Link to Jira'**
  String get jiraLinkAction;

  /// Title of the link dialog.
  ///
  /// In en, this message translates to:
  /// **'Link a Jira issue'**
  String get jiraLinkTitle;

  /// Label of the Jira issue key field.
  ///
  /// In en, this message translates to:
  /// **'Issue key'**
  String get jiraFieldIssueKey;

  /// Placeholder of the Jira issue key field.
  ///
  /// In en, this message translates to:
  /// **'PROJ-123'**
  String get jiraFieldIssueKeyHint;

  /// Task action that detaches the Jira issue.
  ///
  /// In en, this message translates to:
  /// **'Remove Jira link'**
  String get jiraUnlinkAction;

  /// Task action that re-reads the issue status.
  ///
  /// In en, this message translates to:
  /// **'Refresh from Jira'**
  String get jiraRefreshAction;

  /// Task action that posts a comment on the linked issue.
  ///
  /// In en, this message translates to:
  /// **'Comment on Jira'**
  String get jiraCommentAction;

  /// Title of the comment dialog.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get jiraCommentTitle;

  /// Label of the Jira comment field.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get jiraFieldComment;

  /// Task action that queues a transition to the local status.
  ///
  /// In en, this message translates to:
  /// **'Send status to Jira'**
  String get jiraPushStatusAction;

  /// Task action that creates an issue from the task.
  ///
  /// In en, this message translates to:
  /// **'Create Jira issue'**
  String get jiraCreateIssueAction;

  /// Title of the issue creation dialog.
  ///
  /// In en, this message translates to:
  /// **'Create an issue from this task'**
  String get jiraCreateIssueTitle;

  /// Label of the Jira project key field.
  ///
  /// In en, this message translates to:
  /// **'Project key'**
  String get jiraFieldProjectKey;

  /// Placeholder of the Jira project key field.
  ///
  /// In en, this message translates to:
  /// **'PROJ'**
  String get jiraFieldProjectKeyHint;

  /// Confirmation shown after a Jira write is enqueued.
  ///
  /// In en, this message translates to:
  /// **'Queued — it will reach Jira as soon as there is a connection.'**
  String get jiraQueuedMessage;

  /// Error when the typed Jira key does not exist.
  ///
  /// In en, this message translates to:
  /// **'This site has no issue {issueKey}.'**
  String jiraErrorIssueNotFound(String issueKey);

  /// Error when linking is attempted with no network.
  ///
  /// In en, this message translates to:
  /// **'Linking an issue requires a connection.'**
  String get jiraErrorOffline;

  /// Error on HTTP 401/403 from Jira.
  ///
  /// In en, this message translates to:
  /// **'Jira rejected the credentials. Check them in Settings.'**
  String get jiraErrorAuth;

  /// Error on HTTP 429 from Jira.
  ///
  /// In en, this message translates to:
  /// **'Jira is throttling requests. Try again shortly.'**
  String get jiraErrorRateLimited;

  /// Fallback error for any other Jira failure.
  ///
  /// In en, this message translates to:
  /// **'Jira could not be reached.'**
  String get jiraErrorGeneric;

  /// Shown when a Jira action is attempted with no credentials.
  ///
  /// In en, this message translates to:
  /// **'Connect a Jira site in Settings first.'**
  String get jiraNotConfiguredMessage;

  /// Indicator for operations still queued in the outbox.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String jiraSyncPending(int count);

  /// Indicator for operations that exhausted their attempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change could not be sent} other{{count} changes could not be sent}}'**
  String jiraSyncFailed(int count);

  /// Manual retry of the failed outbox operations.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get jiraSyncRetryAction;

  /// When the linked issue status was last read.
  ///
  /// In en, this message translates to:
  /// **'Synced {date}'**
  String jiraLastSyncedLabel(String date);

  /// Shown when a link has never been refreshed.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get jiraNeverSyncedLabel;

  /// Title of the divergence banner (BR-02).
  ///
  /// In en, this message translates to:
  /// **'Jira disagrees with the local status'**
  String get jiraDivergenceTitle;

  /// Body of the divergence banner.
  ///
  /// In en, this message translates to:
  /// **'Here this task is “{local}”; on {issueKey} it is “{remote}”. Nothing changes until you choose.'**
  String jiraDivergenceMessage(String local, String issueKey, String remote);

  /// Divergence decision: keep the local status and tell Jira.
  ///
  /// In en, this message translates to:
  /// **'Keep local'**
  String get jiraDivergenceKeepLocal;

  /// Divergence decision: take Jira's status locally.
  ///
  /// In en, this message translates to:
  /// **'Adopt from Jira'**
  String get jiraDivergenceAdoptRemote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
