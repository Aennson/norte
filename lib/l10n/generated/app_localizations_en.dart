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
}
