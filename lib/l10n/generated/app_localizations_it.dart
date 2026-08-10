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
  String get tasksSearchHint => 'Cerca nel titolo e nella descrizione';

  @override
  String get tasksSearchClear => 'Cancella la ricerca';

  @override
  String tasksSearchEmptyMessage(String term) {
    return 'Nulla corrisponde a “$term”.';
  }

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
      'Collega le attività alle issue di un sito Jira Cloud o Server/Data Center. Il token resta nell\'archivio sicuro del dispositivo e non lo lascia mai.';

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

  @override
  String get jiraFieldDeployment => 'Tipo di Jira';

  @override
  String get jiraDeploymentCloud => 'Cloud';

  @override
  String get jiraDeploymentDataCenter => 'Server / Data Center';

  @override
  String get jiraFieldApiTokenDataCenter => 'Token di accesso personale';

  @override
  String get jiraErrorNotRestApi =>
      'Quell\'URL ha risposto, ma non come API REST di Jira — controlla l\'indirizzo del sito e se è protetto da single sign-on.';

  @override
  String get meetingsNewMeeting => 'Nuova riunione';

  @override
  String get meetingsLoadingLabel => 'Caricamento delle riunioni';

  @override
  String get meetingsErrorMessage =>
      'Non è stato possibile caricare le tue riunioni.';

  @override
  String meetingsActionItemSummary(int total, int converted) {
    return '$converted di $total azioni convertite';
  }

  @override
  String get meetingsTranscriptKept => 'Trascrizione conservata';

  @override
  String get meetingsTranscriptDiscarded => 'Trascrizione eliminata';

  @override
  String get meetingTypeDaily => 'Daily';

  @override
  String get meetingTypeRetro => 'Retrospettiva';

  @override
  String get meetingTypePlanning => 'Planning';

  @override
  String get meetingTypeOneOnOne => '1:1';

  @override
  String get meetingTypeCustom => 'Personalizzato';

  @override
  String get newMeetingTitle => 'Nuova riunione';

  @override
  String get newMeetingTitleField => 'Titolo';

  @override
  String get newMeetingTitleRequired => 'Dai un titolo alla riunione.';

  @override
  String get newMeetingTypeLabel => 'Tipo di riunione';

  @override
  String get newMeetingTranscriptField => 'Trascrizione';

  @override
  String get newMeetingTranscriptHint =>
      'Incolla la trascrizione da Teams, Meet o da dove preferisci.';

  @override
  String get newMeetingTranscriptRequired => 'Incolla prima una trascrizione.';

  @override
  String get newMeetingSaveTranscript => 'Conserva anche la trascrizione';

  @override
  String get newMeetingSaveTranscriptOn =>
      'Il testo completo verrà conservato insieme al riassunto.';

  @override
  String get newMeetingSaveTranscriptOff =>
      'Viene conservato solo il riassunto. Il testo è eliminato quando esci.';

  @override
  String get newMeetingProcess => 'Riassumi';

  @override
  String get newMeetingProcessing => 'Riassumo…';

  @override
  String get newMeetingNoTemplates =>
      'Nessun modello. Ripristina quelli predefiniti nelle Impostazioni.';

  @override
  String get summaryTitle => 'Riassunto';

  @override
  String get summaryGone => 'Quel riassunto non è più in memoria.';

  @override
  String get summaryEmptySection => 'Non trattato in questa riunione.';

  @override
  String get summaryActionItems => 'Follow-up';

  @override
  String get summaryConvert => 'Crea attività';

  @override
  String get summaryConverted => 'Convertita';

  @override
  String get summaryConvertedToast => 'Attività creata.';

  @override
  String get summaryAlreadyConverted => 'Quell\'azione è già un\'attività.';

  @override
  String get summarySave => 'Salva riassunto';

  @override
  String get summarySaved => 'Riassunto salvato.';

  @override
  String get summaryDiscardWarning =>
      'Non è stato ancora salvato nulla. Uscire da questa schermata elimina il riassunto e la trascrizione.';

  @override
  String get summaryDiscardWarningWithTranscript =>
      'Non è stato ancora salvato nulla. Uscire da questa schermata elimina il riassunto e la trascrizione che hai scelto di conservare.';

  @override
  String get aiSectionTitle => 'Claude';

  @override
  String get aiSectionDescription =>
      'I riassunti delle riunioni usano la tua chiave API di Claude. Resta nell\'archivio sicuro di questo dispositivo e ne esce solo per chiamare l\'API.';

  @override
  String get aiKeyField => 'Chiave API';

  @override
  String get aiKeyFieldHint => 'sk-ant-…';

  @override
  String get aiKeyRequired => 'Incolla la tua chiave API.';

  @override
  String get aiKeyConfigured => 'Chiave configurata';

  @override
  String get aiKeyNotConfigured => 'Nessuna chiave configurata';

  @override
  String get aiClearKey => 'Rimuovi chiave';

  @override
  String get aiErrorMissingKey =>
      'Aggiungi la tua chiave API di Claude nelle Impostazioni per riassumere le riunioni.';

  @override
  String get aiErrorRejectedKey =>
      'Claude ha rifiutato quella chiave API. Controllala nelle Impostazioni.';

  @override
  String get aiErrorUnreadable =>
      'Claude ha risposto con qualcosa che questa app non è riuscita a leggere. Riprova.';

  @override
  String get aiErrorRateLimited =>
      'Claude sta limitando le richieste in questo momento. Riprova tra poco.';

  @override
  String get aiErrorOffline =>
      'Impossibile raggiungere Claude. Controlla la connessione.';

  @override
  String get aiErrorTimeout => 'Claude non ha risposto in tempo. Riprova.';

  @override
  String get aiErrorStorage =>
      'Non è stato possibile leggere l\'archivio sicuro di questo dispositivo.';

  @override
  String get aiErrorGeneric => 'Il riassunto non è riuscito. Riprova.';

  @override
  String get templatesSectionTitle => 'Modelli di riunione';

  @override
  String get templatesSectionDescription =>
      'Un modello è l\'istruzione e i titoli con cui viene costruito il riassunto. Modificali per rispecchiare come il tuo team conduce le riunioni.';

  @override
  String get templatesEdit => 'Modifica';

  @override
  String get templatesRestoreDefaults => 'Ripristina i modelli predefiniti';

  @override
  String get templatesPromptField => 'Istruzione';

  @override
  String get templatesSectionsField => 'Sezioni';

  @override
  String get templatesSectionsHint =>
      'Un titolo per riga, nell\'ordine in cui devono comparire.';

  @override
  String get templatesExtractActionItems => 'Estrai le azioni';

  @override
  String get recordMeetingTitle => 'Registra riunione';

  @override
  String get recordMeetingStart => 'Registra audio';

  @override
  String get recordMeetingStartHint =>
      'Registra la riunione e ricevi la trascrizione già pronta.';

  @override
  String get recordMeetingReady => 'Pronto a registrare';

  @override
  String get recordMeetingRecording => 'Registrazione';

  @override
  String get recordMeetingPaused => 'In pausa';

  @override
  String get recordMeetingPause => 'Metti in pausa';

  @override
  String get recordMeetingResume => 'Riprendi';

  @override
  String get recordMeetingStop => 'Ferma e trascrivi';

  @override
  String get recordMeetingDiscard => 'Elimina registrazione';

  @override
  String get recordMeetingDiscardConfirm =>
      'Eliminare questa registrazione? L\'audio viene cancellato e non è recuperabile.';

  @override
  String get recordMeetingLimitLabel => 'Durata massima';

  @override
  String recordMeetingLimitValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get recordMeetingInterrupted =>
      'Registrazione messa in pausa dal sistema. Riprendi quando vuoi — non si è perso nulla.';

  @override
  String get recordMeetingStageUploading => 'Caricamento dell\'audio';

  @override
  String get recordMeetingStageTranscribing => 'Trascrizione';

  @override
  String get recordMeetingStageSummarizing => 'Riepilogo';

  @override
  String get recordMeetingKeepAudio =>
      'La registrazione è stata conservata: puoi riprovare senza registrare di nuovo.';

  @override
  String get recordMeetingPermissionTitle => 'Accesso al microfono disattivato';

  @override
  String get recordMeetingPermissionBody =>
      'Norte ha bisogno del microfono per registrare una riunione. L\'audio resta su questo dispositivo finché non lo invii per la trascrizione, e poi viene cancellato.';

  @override
  String get recordMeetingPermissionAllow => 'Consenti microfono';

  @override
  String get recordMeetingPermissionSettings => 'Apri impostazioni';

  @override
  String get recordMeetingPermissionPermanent =>
      'L\'avviso non comparirà più — concedi l\'accesso al microfono nelle impostazioni di sistema.';

  @override
  String get transcriptionErrorFailed =>
      'Non è stato possibile trascrivere l\'audio. Riprova.';

  @override
  String get transcriptionErrorNoKey =>
      'Nessuna chiave di trascrizione configurata. Aggiungine una in Impostazioni.';

  @override
  String get transcriptionErrorRejected =>
      'La chiave di trascrizione è stata rifiutata. Controllala in Impostazioni.';

  @override
  String get transcriptionErrorTooLong =>
      'La registrazione è troppo lunga per essere caricata.';

  @override
  String get recordingErrorFailed =>
      'Non è stato possibile registrare. Riprova.';

  @override
  String get settingsWhisperSection => 'Trascrizione';

  @override
  String get settingsWhisperDescription =>
      'La tua chiave di trascrizione. Resta nell\'archivio sicuro di questo dispositivo e non ne esce se non per trascrivere il tuo audio.';

  @override
  String get settingsWhisperKeyField => 'Chiave API di trascrizione';

  @override
  String get settingsWhisperConfigured => 'Chiave configurata';

  @override
  String get voiceConnecting => 'Connessione…';

  @override
  String get voiceListening => 'In ascolto…';

  @override
  String get voiceUnderstanding => 'Sto capendo…';

  @override
  String get voiceStop => 'Ferma';

  @override
  String get voiceNotUnderstood =>
      'Non ho colto nessun comando. Prova a dirlo in un altro modo.';

  @override
  String get voiceConfirmTitle => 'Conferma questa azione';

  @override
  String get voiceReasonJiraWrite =>
      'Le scritture su Jira chiedono sempre conferma. Puoi cambiarlo in Impostazioni.';

  @override
  String get voiceReasonLowConfidence =>
      'Non sono sicuro di aver capito. Controlla prima di eseguire.';

  @override
  String voiceConfidenceLabel(int percent) {
    return 'Affidabilità $percent%';
  }

  @override
  String get voiceAskIssueKey => 'Quale ticket?';

  @override
  String get voiceAskTransition => 'Quale stato?';

  @override
  String get voiceAskComment => 'Cosa deve dire il commento?';

  @override
  String get voiceAskTitle => 'Come si chiama l\'attività?';

  @override
  String get voiceAskText => 'Ricordarti che cosa?';

  @override
  String get voiceAskTriggerAt => 'Per quando?';

  @override
  String voiceActionUpdateJira(String issueKey, String transition) {
    return '$issueKey → $transition';
  }

  @override
  String voiceActionAddComment(String issueKey, String comment) {
    return 'Commenta su $issueKey: $comment';
  }

  @override
  String voiceActionCreateTask(String title) {
    return 'Nuova attività: $title';
  }

  @override
  String voiceActionCreateReminder(String text, String triggerAt) {
    return 'Ricorda $text — $triggerAt';
  }

  @override
  String voiceActionQueryStatus(String issueKey) {
    return 'Stato di $issueKey';
  }

  @override
  String get voiceDoneTask => 'Attività creata';

  @override
  String get voiceDoneQueued => 'In coda per Jira';

  @override
  String get voiceDoneReminder => 'Promemoria creato';

  @override
  String voiceDoneStatus(String issueKey, String status) {
    return '$issueKey è $status';
  }

  @override
  String voiceErrorNotLinked(String issueKey) {
    return 'Nessuna attività qui è collegata a $issueKey.';
  }

  @override
  String get voiceAskTaskRef => 'Quale attività?';

  @override
  String get voiceAskChange => 'Cambiarla in che cosa?';

  @override
  String voiceActionUpdateTask(String taskRef) {
    return 'Modifica $taskRef';
  }

  @override
  String voiceActionDeleteTask(String taskRef) {
    return 'Elimina $taskRef';
  }

  @override
  String voiceActionCommentTask(String taskRef, String comment) {
    return 'Nota su $taskRef: $comment';
  }

  @override
  String get voiceReasonDeletion =>
      'Eliminare un’attività è irreversibile, quindi chiediamo sempre.';

  @override
  String voiceDoneTaskUpdated(String title) {
    return 'Attività aggiornata: $title';
  }

  @override
  String voiceDoneTaskDeleted(String title) {
    return '$title eliminata';
  }

  @override
  String voiceDoneTaskCommented(String title) {
    return 'Nota aggiunta a $title — resta nella tua lista';
  }

  @override
  String voiceTaskNotFound(String reference) {
    return 'Nessuna attività chiamata “$reference”.';
  }

  @override
  String voiceTaskAmbiguous(String candidates) {
    return 'Quale — $candidates?';
  }

  @override
  String get settingsVoiceSection => 'Voce';

  @override
  String get settingsVoiceDescription =>
      'Come si comportano i comandi vocali prima di cambiare qualcosa.';

  @override
  String get settingsAlwaysConfirmJira =>
      'Conferma sempre le scritture su Jira';

  @override
  String get settingsAlwaysConfirmJiraDescription =>
      'Chiede prima di ogni transizione o commento dettato, per quanto sicura sia l\'app. I comandi poco affidabili chiedono sempre, comunque sia impostato questo.';

  @override
  String get settingsScribeKeyField => 'Chiave API della voce in tempo reale';

  @override
  String get settingsScribeDescription =>
      'La tua chiave ElevenLabs Scribe, usata solo per i comandi vocali. È un servizio diverso dalla chiave di trascrizione qui sopra — le riunioni vanno a Whisper, i comandi dettati vanno a Scribe, e ognuno conserva la propria chiave.';

  @override
  String get settingsScribeConfigured => 'Chiave in tempo reale configurata';

  @override
  String get settingsScribeNotConfigured =>
      'Nessuna chiave in tempo reale — i comandi vocali non funzioneranno';

  @override
  String get voiceMeterLabel => 'Livello del microfono';

  @override
  String get voiceNoAudio =>
      'Il microfono è aperto, ma non arriva alcun suono.';

  @override
  String get voiceReconnecting => 'Connessione persa — riconnessione…';

  @override
  String get voiceTimeUnsupported =>
      'Questa app non sa ancora risolvere quell\'orario. Prova \"tra 20 minuti\".';

  @override
  String get voiceFailed => 'Fermato';

  @override
  String get settingsScribeKeyHint => 'sk_...';

  @override
  String get reminderNotificationTitle => 'Promemoria';

  @override
  String get remindersUpcoming => 'Prossimi';

  @override
  String get remindersPast => 'Passati';

  @override
  String get remindersHold => 'Tieni premuto per parlare';

  @override
  String get remindersListening => 'In ascolto…';

  @override
  String remindersSecondsLeft(int seconds) {
    return '${seconds}s rimasti';
  }

  @override
  String get remindersLimitReached =>
      'Il limite è 15 secondi — è tutto quello che ho sentito.';

  @override
  String get remindersTypeInstead => 'Scrivilo invece';

  @override
  String get remindersTextLabel => 'Ricordami di…';

  @override
  String get remindersTimeLabel => 'Quando?';

  @override
  String get remindersInTwentyMinutes => 'Tra 20 minuti';

  @override
  String get remindersInAnHour => 'Tra un\'ora';

  @override
  String get remindersTomorrowMorning => 'Domani 09:00';

  @override
  String get remindersPickDateTime => 'Scegli data e ora';

  @override
  String get remindersCreate => 'Crea promemoria';

  @override
  String get remindersCancel => 'Annulla promemoria';

  @override
  String get remindersCancelled => 'Promemoria annullato';

  @override
  String get remindersTimePassed => 'Quell\'orario è già passato.';

  @override
  String get remindersTimeUnreadable =>
      'Non sono riuscito a capire quell\'orario. Prova \"tra 20 minuti\".';

  @override
  String get remindersNotPermitted =>
      'Le notifiche sono disattivate, quindi questo promemoria non suonerà. È stato salvato.';

  @override
  String get remindersLoadFailed =>
      'Non è stato possibile caricare i promemoria.';

  @override
  String get remindersRetry => 'Riprova';

  @override
  String get remindersFired => 'Consegnato';

  @override
  String get settingsEngineSection => 'Motore IA';

  @override
  String get settingsEngineDescription =>
      'Quale assistente riassume le tue riunioni e interpreta i comandi vocali. I motori a riga di comando usano il proprio accesso e sono disponibili solo su Windows.';

  @override
  String get settingsEngineClaudeApi => 'API Claude (la tua chiave)';

  @override
  String get settingsEngineCopilotCli => 'GitHub Copilot CLI';

  @override
  String get settingsEngineClaudeCodeCli => 'Claude Code CLI';

  @override
  String get settingsEngineModelAutomatic => 'Automatico';

  @override
  String settingsEngineAnswers(int count) {
    return '$count risposte';
  }

  @override
  String get settingsEngineFallback => 'Ripiega su un altro motore';

  @override
  String get settingsEngineFallbackDescription =>
      'Se il motore scelto non riesce a rispondere, prova l\'API Claude invece di mostrare un errore. Disattivalo per essere sempre avvisato quando il tuo motore fallisce.';

  @override
  String get aiErrorEngineUnavailable =>
      'Nessun motore IA ha potuto rispondere. Controlla la sezione Motore IA nelle Impostazioni.';

  @override
  String get aiErrorEngineNotInstalled =>
      'Non è stato possibile avviare quel motore a riga di comando. Verifica che sia installato e connesso.';

  @override
  String get aiErrorEngineTooSlow =>
      'Il motore non ha risposto in tempo ed è stato interrotto. Riprova.';
}
