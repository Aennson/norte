import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/usecases/cancel_reminder.dart';
import '../../application/usecases/check_due_reminders.dart';
import '../../application/usecases/create_voice_reminder.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/ports/notification_scheduler.dart';
import '../../domain/ports/reminder_notification_copy.dart';
import '../../domain/ports/reminder_repository.dart';
import '../../domain/ports/time_zone.dart';
import '../../l10n/generated/app_localizations.dart';
import '../tasks/task_providers.dart';

/// Storage for reminders. Overridden in the composition root.
final Provider<ReminderRepository> reminderRepositoryProvider =
    Provider<ReminderRepository>(
      (Ref ref) => throw UnimplementedError('wired in main.dart'),
    );

/// The platform's notification scheduler. Overridden in the composition root —
/// `flutter_local_notifications` on Android and iOS, a WinRT toast on Windows
/// (`docs/architecture.md` §8).
final Provider<NotificationScheduler> notificationSchedulerProvider =
    Provider<NotificationScheduler>(
      (Ref ref) => throw UnimplementedError('wired in main.dart'),
    );

/// The user's timezone. Overridden in the composition root with the zone the
/// `timezone` package reports; a test overrides it with a fixed offset.
///
/// The default is UTC rather than a throw, because unlike the ports above this
/// one has a defensible answer when nothing is wired: a reminder resolved in
/// UTC is wrong by hours, and one that crashed the app is wrong by everything.
final Provider<TimeZone> timeZoneProvider = Provider<TimeZone>(
  (Ref ref) => const FixedOffsetTimeZone.utc(),
);

/// The locale the app resolved, as the widget layer sees it (BR-11).
///
/// Nothing outside the widget tree can ask a `BuildContext` what language the
/// user reads, and two things now need to know: the notification title, which
/// the platform is handed long before anyone looks at a screen, and the tag
/// the speech model is told to expect.
///
/// **It is written into rather than overridden.** A nested `ProviderScope`
/// under `MaterialApp` would look like the obvious way to inject it, and it
/// silently would not work: a provider that is not itself overridden
/// initialises in the root container, so everything *depending* on the locale
/// would keep reading the default while the scope below held the real one.
///
/// The English default is the fallback locale (BR-11), and it is only ever
/// read in the one frame before `NorteApp` binds the real one.
final NotifierProvider<AppLocale, Locale> appLocaleProvider =
    NotifierProvider<AppLocale, Locale>(AppLocale.new);

/// Holder for [appLocaleProvider].
class AppLocale extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  /// Records the locale `MaterialApp` resolved. A no-op when it has not
  /// changed, so binding it on every dependency change costs nothing.
  void set(Locale locale) {
    if (state != locale) state = locale;
  }
}

/// The reminder notification's words, in the app's language.
final Provider<ReminderNotificationCopy> reminderNotificationCopyProvider =
    Provider<ReminderNotificationCopy>(
      (Ref ref) => _LocalizedReminderCopy(
        lookupAppLocalizations(ref.watch(appLocaleProvider)),
      ),
    );

final Provider<CreateVoiceReminder> createVoiceReminderProvider =
    Provider<CreateVoiceReminder>(
      (Ref ref) => CreateVoiceReminder(
        repository: ref.watch(reminderRepositoryProvider),
        scheduler: ref.watch(notificationSchedulerProvider),
        clock: ref.watch(clockProvider),
        zone: ref.watch(timeZoneProvider),
        idGenerator: ref.watch(idGeneratorProvider),
        copy: ref.watch(reminderNotificationCopyProvider),
      ),
    );

final Provider<CancelReminder> cancelReminderProvider =
    Provider<CancelReminder>(
      (Ref ref) => CancelReminder(
        repository: ref.watch(reminderRepositoryProvider),
        scheduler: ref.watch(notificationSchedulerProvider),
      ),
    );

final Provider<CheckDueReminders> checkDueRemindersProvider =
    Provider<CheckDueReminders>(
      (Ref ref) => CheckDueReminders(
        repository: ref.watch(reminderRepositoryProvider),
        scheduler: ref.watch(notificationSchedulerProvider),
        clock: ref.watch(clockProvider),
        copy: ref.watch(reminderNotificationCopyProvider),
      ),
    );

/// The reminder a notification asked the app to open, until it has been.
///
/// A one-shot mailbox rather than a navigation call, because the tap arrives
/// from a platform callback that has no `BuildContext` and may fire before the
/// router exists at all — a toast raised during startup, or the tap that
/// launched the process. `NorteApp` drains it and navigates.
final NotifierProvider<ReminderDeepLink, String?> reminderDeepLinkProvider =
    NotifierProvider<ReminderDeepLink, String?>(ReminderDeepLink.new);

/// Holder for [reminderDeepLinkProvider].
class ReminderDeepLink extends Notifier<String?> {
  @override
  String? build() => null;

  /// Asks for the reminder with [id] to be opened.
  void open(String id) => state = id;

  /// Marks the request as handled, so a rebuild does not navigate twice.
  void clear() => state = null;
}

/// Every stored reminder, live.
///
/// Unsorted, as the port's contract says: the screen splits them into upcoming
/// and past against the clock, which is a decision about *now* and cannot be
/// baked into a query.
final StreamProvider<List<Reminder>> remindersProvider =
    StreamProvider<List<Reminder>>(
      (Ref ref) => ref.watch(reminderRepositoryProvider).watchAll(),
    );

class _LocalizedReminderCopy implements ReminderNotificationCopy {
  const _LocalizedReminderCopy(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get title => _l10n.reminderNotificationTitle;
}
