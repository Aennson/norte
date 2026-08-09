/// The words a reminder's notification is delivered in.
///
/// `ScheduledNotification` says its title and body arrive **already localized
/// by the caller** (BR-11), and the caller is a use case — a layer with no
/// `BuildContext` and no business holding an English literal. This port is how
/// the three ARB files reach it: the composition root binds an implementation
/// built from the active locale, and the use case asks it.
///
/// It is deliberately tiny. The body of a reminder notification is the
/// reminder's own text, which needs no translating; only the title does, and
/// on Windows the toast wants a second line naming the app.
abstract interface class ReminderNotificationCopy {
  /// Title of a reminder notification — "Reminder", "Lembrete", "Promemoria".
  String get title;
}
