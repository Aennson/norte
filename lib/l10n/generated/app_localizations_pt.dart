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
      'Vincule tarefas a issues de um site Jira Cloud. Seu token de API fica no armazenamento seguro do aparelho e nunca sai de lá.';

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
}
