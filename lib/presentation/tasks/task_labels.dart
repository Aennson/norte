import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../application/usecases/list_tasks.dart';
import '../../domain/entities/task.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/widgets/status_badge.dart';

/// Translation of the domain enums into what the user reads and sees.
///
/// Kept in one place so a status is worded and coloured identically on the
/// card, in the filter bar and in the editor (BR-11 — every label comes from
/// the ARB resources).
extension TaskStatusPresentation on TaskStatus {
  /// Localized name of the status.
  String label(AppLocalizations l10n) => switch (this) {
    TaskStatus.todo => l10n.statusTodo,
    TaskStatus.inProgress => l10n.statusInProgress,
    TaskStatus.done => l10n.statusDone,
    TaskStatus.blocked => l10n.statusBlocked,
  };

  /// The design-system badge variant carrying this status' colour.
  NorteStatus get badge => switch (this) {
    TaskStatus.todo => NorteStatus.todo,
    TaskStatus.inProgress => NorteStatus.inProgress,
    TaskStatus.done => NorteStatus.done,
    TaskStatus.blocked => NorteStatus.blocked,
  };

  /// Dot colour used by the filter chips (`docs/design-system.md` §4).
  Color dotColor(NorteColors colors) => switch (this) {
    TaskStatus.todo => colors.textMuted,
    TaskStatus.inProgress => colors.info,
    TaskStatus.done => colors.success,
    TaskStatus.blocked => colors.error,
  };
}

extension PriorityPresentation on Priority {
  /// Localized name of the priority.
  String label(AppLocalizations l10n) => switch (this) {
    Priority.low => l10n.priorityLow,
    Priority.medium => l10n.priorityMedium,
    Priority.high => l10n.priorityHigh,
    Priority.urgent => l10n.priorityUrgent,
  };
}

extension TaskSortPresentation on TaskSort {
  /// Localized name of the ordering.
  String label(AppLocalizations l10n) => switch (this) {
    TaskSort.priority => l10n.sortByPriority,
    TaskSort.dueDate => l10n.sortByDueDate,
  };
}

/// Formats [date] for the active locale, e.g. `5 Jan 2026` / `5 de jan. de
/// 2026`.
///
/// Dates are stored in UTC and shown in local time, which is what the user
/// means by "due Friday".
String formatTaskDate(BuildContext context, DateTime date) {
  final String locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(date.toLocal());
}
