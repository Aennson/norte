// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Norte';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get navMeetings => 'Reuniões';

  @override
  String get navReminders => 'Lembretes';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get voiceCommandLabel => 'Comando de voz';

  @override
  String get tasksEmptyMessage => 'Nenhuma tarefa ainda.';

  @override
  String get meetingsEmptyMessage => 'Nenhuma reunião ainda.';

  @override
  String get remindersEmptyMessage => 'Nenhum lembrete ainda.';

  @override
  String get settingsEmptyMessage => 'Nenhum ajuste disponível ainda.';

  @override
  String get statusTodo => 'A fazer';

  @override
  String get statusInProgress => 'Em andamento';

  @override
  String get statusDone => 'Concluída';

  @override
  String get statusBlocked => 'Bloqueada';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionRetry => 'Tentar novamente';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionCreate => 'Criar';

  @override
  String get actionClear => 'Limpar';

  @override
  String get tasksNewTask => 'Nova tarefa';

  @override
  String get tasksEditTask => 'Editar tarefa';

  @override
  String get tasksLoadingLabel => 'Carregando tarefas';

  @override
  String get tasksErrorMessage => 'Não foi possível carregar suas tarefas.';

  @override
  String get tasksFilteredEmptyMessage =>
      'Nenhuma tarefa corresponde a este filtro.';

  @override
  String get tasksFilterAll => 'Todas';

  @override
  String get tasksSearchHint => 'Buscar no título e na descrição';

  @override
  String get tasksSearchClear => 'Limpar a busca';

  @override
  String tasksSearchEmptyMessage(String term) {
    return 'Nada corresponde a “$term”.';
  }

  @override
  String get taskFieldTitle => 'Título';

  @override
  String get taskFieldTitleHint => 'O que precisa ser feito?';

  @override
  String get taskFieldTitleRequired => 'O título é obrigatório.';

  @override
  String get taskFieldDescription => 'Descrição';

  @override
  String get taskFieldStatus => 'Status';

  @override
  String get taskFieldPriority => 'Prioridade';

  @override
  String get taskFieldDueDate => 'Prazo';

  @override
  String get taskFieldDueDateEmpty => 'Sem prazo';

  @override
  String get taskFieldTags => 'Etiquetas';

  @override
  String get taskFieldTagsHint => 'Separadas por vírgula';

  @override
  String taskDueLabel(String date) {
    return 'Prazo $date';
  }

  @override
  String get taskMarkDone => 'Marcar como concluída';

  @override
  String get taskMarkNotDone => 'Reabrir tarefa';

  @override
  String get taskDeleteTitle => 'Excluir tarefa?';

  @override
  String taskDeleteMessage(String title) {
    return '“$title” será removida permanentemente. Não é possível desfazer.';
  }

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get sortLabel => 'Ordenar';

  @override
  String get sortByPriority => 'Prioridade';

  @override
  String get sortByDueDate => 'Prazo';

  @override
  String get jiraSectionTitle => 'Jira';

  @override
  String get jiraSectionDescription =>
      'Vincule tarefas a issues de um site Jira Cloud ou Server/Data Center. Seu token fica no armazenamento seguro do aparelho e nunca sai de lá.';

  @override
  String get jiraFieldSiteUrl => 'URL do site';

  @override
  String get jiraFieldSiteUrlHint => 'https://seu-time.atlassian.net';

  @override
  String get jiraFieldEmail => 'E-mail da conta';

  @override
  String get jiraFieldApiToken => 'Token de API';

  @override
  String get jiraConnectAction => 'Conectar';

  @override
  String get jiraDisconnectAction => 'Desconectar';

  @override
  String jiraConnectedAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get jiraNotConnected => 'Não conectado.';

  @override
  String get jiraCredentialsIncomplete =>
      'Preencha o site, o e-mail e o token.';

  @override
  String get jiraLinkAction => 'Vincular ao Jira';

  @override
  String get jiraLinkTitle => 'Vincular uma issue do Jira';

  @override
  String get jiraFieldIssueKey => 'Chave da issue';

  @override
  String get jiraFieldIssueKeyHint => 'PROJ-123';

  @override
  String get jiraUnlinkAction => 'Remover vínculo com o Jira';

  @override
  String get jiraRefreshAction => 'Atualizar pelo Jira';

  @override
  String get jiraCommentAction => 'Comentar no Jira';

  @override
  String get jiraCommentTitle => 'Adicionar um comentário';

  @override
  String get jiraFieldComment => 'Comentário';

  @override
  String get jiraPushStatusAction => 'Enviar status para o Jira';

  @override
  String get jiraCreateIssueAction => 'Criar issue no Jira';

  @override
  String get jiraCreateIssueTitle => 'Criar uma issue a partir desta tarefa';

  @override
  String get jiraFieldProjectKey => 'Chave do projeto';

  @override
  String get jiraFieldProjectKeyHint => 'PROJ';

  @override
  String get jiraQueuedMessage =>
      'Na fila — vai chegar ao Jira assim que houver conexão.';

  @override
  String jiraErrorIssueNotFound(String issueKey) {
    return 'Este site não tem a issue $issueKey.';
  }

  @override
  String get jiraErrorOffline => 'Vincular uma issue exige conexão.';

  @override
  String get jiraErrorAuth =>
      'O Jira recusou as credenciais. Confira em Configurações.';

  @override
  String get jiraErrorRateLimited =>
      'O Jira está limitando as requisições. Tente de novo em instantes.';

  @override
  String get jiraErrorGeneric => 'Não foi possível falar com o Jira.';

  @override
  String get jiraNotConfiguredMessage =>
      'Conecte um site do Jira em Configurações primeiro.';

  @override
  String jiraSyncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações esperando sincronizar',
      one: '1 alteração esperando sincronizar',
    );
    return '$_temp0';
  }

  @override
  String jiraSyncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações não puderam ser enviadas',
      one: '1 alteração não pôde ser enviada',
    );
    return '$_temp0';
  }

  @override
  String get jiraSyncRetryAction => 'Tentar de novo';

  @override
  String jiraLastSyncedLabel(String date) {
    return 'Sincronizado $date';
  }

  @override
  String get jiraNeverSyncedLabel => 'Nunca sincronizado';

  @override
  String get jiraDivergenceTitle => 'O Jira discorda do status local';

  @override
  String jiraDivergenceMessage(String local, String issueKey, String remote) {
    return 'Aqui esta tarefa está “$local”; na $issueKey está “$remote”. Nada muda até você escolher.';
  }

  @override
  String get jiraDivergenceKeepLocal => 'Manter o local';

  @override
  String get jiraDivergenceAdoptRemote => 'Adotar o do Jira';

  @override
  String get jiraFieldDeployment => 'Tipo de Jira';

  @override
  String get jiraDeploymentCloud => 'Cloud';

  @override
  String get jiraDeploymentDataCenter => 'Server / Data Center';

  @override
  String get jiraFieldApiTokenDataCenter => 'Token de acesso pessoal';

  @override
  String get jiraErrorNotRestApi =>
      'A URL respondeu, mas não como a API REST do Jira — confira o endereço do site e se ele está atrás de single sign-on.';

  @override
  String get meetingsNewMeeting => 'Nova reunião';

  @override
  String get meetingsLoadingLabel => 'Carregando reuniões';

  @override
  String get meetingsErrorMessage => 'Não foi possível carregar suas reuniões.';

  @override
  String meetingsActionItemSummary(int total, int converted) {
    return '$converted de $total ações convertidas';
  }

  @override
  String get meetingsTranscriptKept => 'Transcrição mantida';

  @override
  String get meetingsTranscriptDiscarded => 'Transcrição descartada';

  @override
  String get meetingTypeDaily => 'Daily';

  @override
  String get meetingTypeRetro => 'Retrospectiva';

  @override
  String get meetingTypePlanning => 'Planning';

  @override
  String get meetingTypeOneOnOne => '1:1';

  @override
  String get meetingTypeCustom => 'Personalizado';

  @override
  String get newMeetingTitle => 'Nova reunião';

  @override
  String get newMeetingTitleField => 'Título';

  @override
  String get newMeetingTitleRequired => 'Dê um título à reunião.';

  @override
  String get newMeetingTypeLabel => 'Tipo de reunião';

  @override
  String get newMeetingTranscriptField => 'Transcrição';

  @override
  String get newMeetingTranscriptHint =>
      'Cole a transcrição do Teams, do Meet ou de onde vier.';

  @override
  String get newMeetingTranscriptRequired => 'Cole uma transcrição primeiro.';

  @override
  String get newMeetingSaveTranscript => 'Salvar também a transcrição';

  @override
  String get newMeetingSaveTranscriptOn =>
      'O texto completo será guardado junto com o resumo.';

  @override
  String get newMeetingSaveTranscriptOff =>
      'Só o resumo é guardado. O texto é descartado quando você sair.';

  @override
  String get newMeetingProcess => 'Resumir';

  @override
  String get newMeetingProcessing => 'Resumindo…';

  @override
  String get newMeetingNoTemplates =>
      'Nenhum modelo. Restaure os padrões em Configurações.';

  @override
  String get summaryTitle => 'Resumo';

  @override
  String get summaryGone => 'Esse resumo não está mais em memória.';

  @override
  String get summaryEmptySection => 'Não tratado nesta reunião.';

  @override
  String get summaryActionItems => 'Encaminhamentos';

  @override
  String get summaryConvert => 'Criar tarefa';

  @override
  String get summaryConverted => 'Convertida';

  @override
  String get summaryConvertedToast => 'Tarefa criada.';

  @override
  String get summaryAlreadyConverted => 'Essa ação já virou tarefa.';

  @override
  String get summarySave => 'Salvar resumo';

  @override
  String get summarySaved => 'Resumo salvo.';

  @override
  String get summaryDiscardWarning =>
      'Nada foi salvo ainda. Sair desta tela descarta o resumo e a transcrição.';

  @override
  String get summaryDiscardWarningWithTranscript =>
      'Nada foi salvo ainda. Sair desta tela descarta o resumo e a transcrição que você optou por manter.';

  @override
  String get aiSectionTitle => 'Claude';

  @override
  String get aiSectionDescription =>
      'Os resumos de reunião usam a sua própria chave da API do Claude. Ela fica no armazenamento seguro deste dispositivo e só sai dele para chamar a API.';

  @override
  String get aiKeyField => 'Chave da API';

  @override
  String get aiKeyFieldHint => 'sk-ant-…';

  @override
  String get aiKeyRequired => 'Cole a sua chave da API.';

  @override
  String get aiKeyConfigured => 'Chave configurada';

  @override
  String get aiKeyNotConfigured => 'Nenhuma chave configurada';

  @override
  String get aiClearKey => 'Remover chave';

  @override
  String get aiErrorMissingKey =>
      'Adicione a sua chave da API do Claude em Configurações para resumir reuniões.';

  @override
  String get aiErrorRejectedKey =>
      'O Claude recusou essa chave da API. Confira em Configurações.';

  @override
  String get aiErrorUnreadable =>
      'O Claude respondeu com algo que este app não conseguiu ler. Tente de novo.';

  @override
  String get aiErrorRateLimited =>
      'O Claude está limitando as requisições agora. Tente daqui a pouco.';

  @override
  String get aiErrorOffline =>
      'Não foi possível alcançar o Claude. Verifique sua conexão.';

  @override
  String get aiErrorTimeout => 'O Claude não respondeu a tempo. Tente de novo.';

  @override
  String get aiErrorStorage =>
      'Não foi possível ler o armazenamento seguro deste dispositivo.';

  @override
  String get aiErrorGeneric => 'O resumo falhou. Tente de novo.';

  @override
  String get templatesSectionTitle => 'Modelos de reunião';

  @override
  String get templatesSectionDescription =>
      'Um modelo é a instrução e os títulos com que o resumo é montado. Edite-os para refletir como o seu time conduz as reuniões.';

  @override
  String get templatesEdit => 'Editar';

  @override
  String get templatesRestoreDefaults => 'Restaurar os modelos originais';

  @override
  String get templatesPromptField => 'Instrução';

  @override
  String get templatesSectionsField => 'Seções';

  @override
  String get templatesSectionsHint =>
      'Um título por linha, na ordem em que devem aparecer.';

  @override
  String get templatesExtractActionItems => 'Extrair ações';

  @override
  String get recordMeetingTitle => 'Gravar reunião';

  @override
  String get recordMeetingStart => 'Gravar áudio';

  @override
  String get recordMeetingStartHint =>
      'Grave a reunião e receba a transcrição pronta.';

  @override
  String get recordMeetingReady => 'Pronto para gravar';

  @override
  String get recordMeetingRecording => 'Gravando';

  @override
  String get recordMeetingPaused => 'Pausado';

  @override
  String get recordMeetingPause => 'Pausar';

  @override
  String get recordMeetingResume => 'Retomar';

  @override
  String get recordMeetingStop => 'Parar e transcrever';

  @override
  String get recordMeetingDiscard => 'Descartar gravação';

  @override
  String get recordMeetingDiscardConfirm =>
      'Descartar esta gravação? O áudio é apagado e não dá para recuperar.';

  @override
  String get recordMeetingLimitLabel => 'Duração máxima';

  @override
  String recordMeetingLimitValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get recordMeetingInterrupted =>
      'Gravação pausada pelo sistema. Retome quando quiser — nada foi perdido.';

  @override
  String get recordMeetingStageUploading => 'Enviando o áudio';

  @override
  String get recordMeetingStageTranscribing => 'Transcrevendo';

  @override
  String get recordMeetingStageSummarizing => 'Resumindo';

  @override
  String get recordMeetingKeepAudio =>
      'A gravação foi mantida para você tentar de novo sem gravar tudo outra vez.';

  @override
  String get recordMeetingPermissionTitle => 'Acesso ao microfone desligado';

  @override
  String get recordMeetingPermissionBody =>
      'O Norte precisa do microfone para gravar uma reunião. O áudio fica neste aparelho até você enviá-lo para transcrição, e é apagado depois.';

  @override
  String get recordMeetingPermissionAllow => 'Permitir microfone';

  @override
  String get recordMeetingPermissionSettings => 'Abrir configurações';

  @override
  String get recordMeetingPermissionPermanent =>
      'O aviso não vai aparecer de novo — libere o microfone nas configurações do sistema.';

  @override
  String get transcriptionErrorFailed =>
      'Não deu para transcrever o áudio. Tente de novo.';

  @override
  String get transcriptionErrorNoKey =>
      'Nenhuma chave de transcrição configurada. Adicione uma em Ajustes.';

  @override
  String get transcriptionErrorRejected =>
      'A chave de transcrição foi recusada. Confira em Ajustes.';

  @override
  String get transcriptionErrorTooLong =>
      'A gravação é longa demais para enviar.';

  @override
  String get recordingErrorFailed => 'Não deu para gravar. Tente de novo.';

  @override
  String get settingsWhisperSection => 'Transcrição';

  @override
  String get settingsWhisperDescription =>
      'Sua própria chave de transcrição. Ela fica no cofre seguro deste aparelho e só sai dele para transcrever o seu áudio.';

  @override
  String get settingsWhisperKeyField => 'Chave da API de transcrição';

  @override
  String get settingsWhisperConfigured => 'Chave configurada';

  @override
  String get voiceConnecting => 'Conectando…';

  @override
  String get voiceListening => 'Ouvindo…';

  @override
  String get voiceUnderstanding => 'Entendendo…';

  @override
  String get voiceStop => 'Parar';

  @override
  String get voiceNotUnderstood =>
      'Não peguei nenhum comando. Tente falar de outro jeito.';

  @override
  String get voiceConfirmTitle => 'Confirmar esta ação';

  @override
  String get voiceReasonJiraWrite =>
      'Escritas no Jira sempre pedem confirmação. Você pode mudar isso em Ajustes.';

  @override
  String get voiceReasonLowConfidence =>
      'Não tenho certeza se entendi. Confira antes de executar.';

  @override
  String voiceConfidenceLabel(int percent) {
    return 'Confiança $percent%';
  }

  @override
  String get voiceAskIssueKey => 'Qual ticket?';

  @override
  String get voiceAskTransition => 'Qual status?';

  @override
  String get voiceAskComment => 'O que o comentário deve dizer?';

  @override
  String get voiceAskTitle => 'Qual vai ser o nome da tarefa?';

  @override
  String get voiceAskText => 'Lembrar de quê?';

  @override
  String get voiceAskTriggerAt => 'Para quando?';

  @override
  String voiceActionUpdateJira(String issueKey, String transition) {
    return '$issueKey → $transition';
  }

  @override
  String voiceActionAddComment(String issueKey, String comment) {
    return 'Comentar no $issueKey: $comment';
  }

  @override
  String voiceActionCreateTask(String title) {
    return 'Nova tarefa: $title';
  }

  @override
  String voiceActionCreateReminder(String text, String triggerAt) {
    return 'Lembrar $text — $triggerAt';
  }

  @override
  String voiceActionQueryStatus(String issueKey) {
    return 'Status do $issueKey';
  }

  @override
  String get voiceDoneTask => 'Tarefa criada';

  @override
  String get voiceDoneQueued => 'Na fila para o Jira';

  @override
  String get voiceDoneReminder => 'Lembrete criado';

  @override
  String voiceDoneStatus(String issueKey, String status) {
    return '$issueKey está $status';
  }

  @override
  String voiceErrorNotLinked(String issueKey) {
    return 'Nenhuma tarefa daqui está ligada ao $issueKey.';
  }

  @override
  String get voiceAskTaskRef => 'Qual tarefa?';

  @override
  String get voiceAskChange => 'Mudar para o quê?';

  @override
  String voiceActionUpdateTask(String taskRef) {
    return 'Alterar $taskRef';
  }

  @override
  String voiceActionDeleteTask(String taskRef) {
    return 'Apagar $taskRef';
  }

  @override
  String voiceActionCommentTask(String taskRef, String comment) {
    return 'Nota em $taskRef: $comment';
  }

  @override
  String get voiceReasonDeletion =>
      'Apagar uma tarefa não tem volta, então sempre perguntamos.';

  @override
  String get voiceDoneTaskUpdated => 'Tarefa atualizada';

  @override
  String voiceDoneTaskDeleted(String title) {
    return '$title apagada';
  }

  @override
  String get voiceDoneTaskCommented => 'Nota adicionada — fica na sua lista';

  @override
  String voiceTaskNotFound(String reference) {
    return 'Nenhuma tarefa chamada “$reference”.';
  }

  @override
  String voiceTaskAmbiguous(String candidates) {
    return 'Qual delas — $candidates?';
  }

  @override
  String get settingsVoiceSection => 'Voz';

  @override
  String get settingsVoiceDescription =>
      'Como os comandos falados se comportam antes de mudar qualquer coisa.';

  @override
  String get settingsAlwaysConfirmJira => 'Sempre confirmar escritas no Jira';

  @override
  String get settingsAlwaysConfirmJiraDescription =>
      'Pergunta antes de cada transição ou comentário falado, por mais certeza que o app tenha. Comandos com pouca confiança sempre perguntam, esteja isto ligado ou não.';

  @override
  String get settingsScribeKeyField => 'Chave da API de voz em tempo real';

  @override
  String get settingsScribeDescription =>
      'Sua chave do ElevenLabs Scribe, usada só para comandos de voz. É um serviço diferente da chave de transcrição acima — reuniões vão para o Whisper, comandos falados vão para o Scribe, e cada um guarda a sua própria chave.';

  @override
  String get settingsScribeConfigured => 'Chave de tempo real configurada';

  @override
  String get settingsScribeNotConfigured =>
      'Sem chave de tempo real — os comandos de voz não vão funcionar';

  @override
  String get voiceMeterLabel => 'Nível do microfone';

  @override
  String get voiceNoAudio =>
      'O microfone está aberto, mas nenhum som está chegando.';

  @override
  String get voiceReconnecting => 'Conexão caiu — reconectando…';

  @override
  String get voiceTimeUnsupported =>
      'Este app ainda não sabe resolver esse horário. Tente \"em 20 minutos\".';

  @override
  String get voiceFailed => 'Parado';

  @override
  String get settingsScribeKeyHint => 'sk_...';
}
