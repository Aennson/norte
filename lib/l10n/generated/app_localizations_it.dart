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
  String get tasksEmptyMessage => 'Ancora nessuna attività.';

  @override
  String get meetingsEmptyMessage => 'Ancora nessuna riunione.';

  @override
  String get remindersEmptyMessage => 'Ancora nessun promemoria.';

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

  @override
  String get actionSave => 'Salva';

  @override
  String get actionCreate => 'Crea';

  @override
  String get actionClear => 'Cancella';

  @override
  String get tasksNewTask => 'Nuova attività';

  @override
  String get tasksEditTask => 'Modifica attività';

  @override
  String get tasksLoadingLabel => 'Caricamento attività';

  @override
  String get tasksErrorMessage =>
      'Non è stato possibile caricare le tue attività.';

  @override
  String get tasksFilteredEmptyMessage =>
      'Nessuna attività corrisponde a questo filtro.';

  @override
  String get tasksFilterAll => 'Tutte';

  @override
  String get taskFieldTitle => 'Titolo';

  @override
  String get taskFieldTitleHint => 'Che cosa c\'è da fare?';

  @override
  String get taskFieldTitleRequired => 'Il titolo è obbligatorio.';

  @override
  String get taskFieldDescription => 'Descrizione';

  @override
  String get taskFieldStatus => 'Stato';

  @override
  String get taskFieldPriority => 'Priorità';

  @override
  String get taskFieldDueDate => 'Scadenza';

  @override
  String get taskFieldDueDateEmpty => 'Nessuna scadenza';

  @override
  String get taskFieldTags => 'Etichette';

  @override
  String get taskFieldTagsHint => 'Separate da virgola';

  @override
  String taskDueLabel(String date) {
    return 'Scadenza $date';
  }

  @override
  String get taskMarkDone => 'Segna come completata';

  @override
  String get taskMarkNotDone => 'Riapri attività';

  @override
  String get taskDeleteTitle => 'Eliminare l\'attività?';

  @override
  String taskDeleteMessage(String title) {
    return '“$title” sarà rimossa definitivamente. L\'operazione non è reversibile.';
  }

  @override
  String get priorityLow => 'Bassa';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get sortLabel => 'Ordina';

  @override
  String get sortByPriority => 'Priorità';

  @override
  String get sortByDueDate => 'Scadenza';
}
