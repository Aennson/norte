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
}
