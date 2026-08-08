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
}
