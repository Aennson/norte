import 'package:norte/domain/ports/reminder_notification_copy.dart';

/// [ReminderNotificationCopy] with a fixed title
/// (`docs/testing-strategy.md` §3).
///
/// The default is deliberately **not** an English word: a test asserting the
/// notification's title against `'Reminder'` would keep passing if the use
/// case hard-coded that literal instead of asking the port, which is exactly
/// the BR-11 defect this port exists to prevent.
class FakeReminderNotificationCopy implements ReminderNotificationCopy {
  const FakeReminderNotificationCopy([this.title = '«reminder-title»']);

  @override
  final String title;
}
