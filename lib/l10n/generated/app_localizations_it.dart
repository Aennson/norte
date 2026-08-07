// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Norte';

  @override
  String get navTasks => 'Attività';

  @override
  String get navMeetings => 'Riunioni';

  @override
  String get navReminders => 'Promemoria';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get voiceCommandLabel => 'Comando vocale';

  @override
  String get tasksEmptyMessage => 'Nessuna attività al momento.';

  @override
  String get meetingsEmptyMessage => 'Nessuna riunione al momento.';

  @override
  String get remindersEmptyMessage => 'Nessun promemoria al momento.';

  @override
  String get settingsEmptyMessage => 'Nessuna impostazione disponibile.';

  @override
  String get statusTodo => 'Da fare';

  @override
  String get statusInProgress => 'In corso';

  @override
  String get statusDone => 'Completata';

  @override
  String get statusBlocked => 'Bloccata';

  @override
  String get actionConfirm => 'Conferma';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionRetry => 'Riprova';
}
