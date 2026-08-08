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

  @override
  String get jiraSectionTitle => 'Jira';

  @override
  String get jiraSectionDescription =>
      'Collega le attività alle issue di un sito Jira Cloud. Il token API resta nell\'archivio sicuro del dispositivo e non lo lascia mai.';

  @override
  String get jiraFieldSiteUrl => 'URL del sito';

  @override
  String get jiraFieldSiteUrlHint => 'https://il-tuo-team.atlassian.net';

  @override
  String get jiraFieldEmail => 'E-mail dell\'account';

  @override
  String get jiraFieldApiToken => 'Token API';

  @override
  String get jiraConnectAction => 'Connetti';

  @override
  String get jiraDisconnectAction => 'Disconnetti';

  @override
  String jiraConnectedAs(String email) {
    return 'Connesso come $email';
  }

  @override
  String get jiraNotConnected => 'Non connesso.';

  @override
  String get jiraCredentialsIncomplete =>
      'Compila il sito, l\'e-mail e il token.';

  @override
  String get jiraLinkAction => 'Collega a Jira';

  @override
  String get jiraLinkTitle => 'Collega una issue di Jira';

  @override
  String get jiraFieldIssueKey => 'Chiave della issue';

  @override
  String get jiraFieldIssueKeyHint => 'PROJ-123';

  @override
  String get jiraUnlinkAction => 'Rimuovi il collegamento a Jira';

  @override
  String get jiraRefreshAction => 'Aggiorna da Jira';

  @override
  String get jiraCommentAction => 'Commenta su Jira';

  @override
  String get jiraCommentTitle => 'Aggiungi un commento';

  @override
  String get jiraFieldComment => 'Commento';

  @override
  String get jiraPushStatusAction => 'Invia lo stato a Jira';

  @override
  String get jiraCreateIssueAction => 'Crea una issue su Jira';

  @override
  String get jiraCreateIssueTitle => 'Crea una issue da questa attività';

  @override
  String get jiraFieldProjectKey => 'Chiave del progetto';

  @override
  String get jiraFieldProjectKeyHint => 'PROJ';

  @override
  String get jiraQueuedMessage =>
      'In coda — arriverà a Jira appena ci sarà connessione.';

  @override
  String jiraErrorIssueNotFound(String issueKey) {
    return 'Questo sito non ha la issue $issueKey.';
  }

  @override
  String get jiraErrorOffline =>
      'Collegare una issue richiede una connessione.';

  @override
  String get jiraErrorAuth =>
      'Jira ha rifiutato le credenziali. Controllale in Impostazioni.';

  @override
  String get jiraErrorRateLimited =>
      'Jira sta limitando le richieste. Riprova tra poco.';

  @override
  String get jiraErrorGeneric => 'Non è stato possibile raggiungere Jira.';

  @override
  String get jiraNotConfiguredMessage =>
      'Collega prima un sito Jira in Impostazioni.';

  @override
  String jiraSyncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche in attesa di sincronizzazione',
      one: '1 modifica in attesa di sincronizzazione',
    );
    return '$_temp0';
  }

  @override
  String jiraSyncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche non sono state inviate',
      one: '1 modifica non è stata inviata',
    );
    return '$_temp0';
  }

  @override
  String get jiraSyncRetryAction => 'Riprova';

  @override
  String jiraLastSyncedLabel(String date) {
    return 'Sincronizzato $date';
  }

  @override
  String get jiraNeverSyncedLabel => 'Mai sincronizzato';

  @override
  String get jiraDivergenceTitle => 'Jira non concorda con lo stato locale';

  @override
  String jiraDivergenceMessage(String local, String issueKey, String remote) {
    return 'Qui questa attività è “$local”; su $issueKey è “$remote”. Non cambia nulla finché non scegli.';
  }

  @override
  String get jiraDivergenceKeepLocal => 'Mantieni il locale';

  @override
  String get jiraDivergenceAdoptRemote => 'Adotta quello di Jira';
}
