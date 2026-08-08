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
}
