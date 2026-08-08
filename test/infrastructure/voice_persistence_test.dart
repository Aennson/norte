import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/reminder.dart';
import 'package:norte/domain/entities/voice_settings.dart';
import 'package:norte/infrastructure/persistence/drift_reminder_repository.dart';
import 'package:norte/infrastructure/persistence/drift_voice_settings_store.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';
import 'package:norte/infrastructure/persistence/norte_database_factory.dart';

/// The Sprint 05 Drift adapters against a real in-memory database.
///
/// Not documented sprint cases — added under `docs/project-rules.md` §5.4,
/// alongside S01-IT-01 which does the same job for tasks. Schema version 4 is
/// the reason: a migration that created the wrong columns would otherwise be
/// discovered by a user whose reminders vanished.
void main() {
  late NorteDatabase database;

  setUp(() => database = openInMemoryNorteDatabase());
  tearDown(() => database.close());

  group('DriftReminderRepository', () {
    late DriftReminderRepository reminders;

    setUp(() => reminders = DriftReminderRepository(database));

    final Reminder reminder = Reminder(
      id: 'e3b0c442-98fc-4c14-9afb-f4c8996fb924',
      text: 'responder o e-mail do jurídico',
      // Non-zero milliseconds: the schema stores epoch milliseconds precisely
      // so this survives the round-trip, as the tasks table does.
      triggerAt: DateTime.utc(2026, 8, 8, 15, 0, 0, 250),
      createdAt: DateTime.utc(2026, 8, 8, 14, 30, 0, 125),
    );

    test('a reminder survives a round-trip unchanged', () async {
      await reminders.save(reminder);

      expect(await reminders.findById(reminder.id), reminder);
      expect(await reminders.listAll(), <Reminder>[reminder]);
    });

    test('BR-06: the audio note is dropped on write', () async {
      await reminders.save(
        reminder.copyWith(sourceAudioNote: 'in-memory-handle'),
      );

      final Reminder? read = await reminders.findById(reminder.id);
      expect(read!.sourceAudioNote, isNull);
      // And the schema gives it nowhere to have landed.
      expect(read, reminder);
    });

    test('save replaces by id rather than duplicating', () async {
      await reminders.save(reminder);
      await reminders.save(reminder.copyWith(isFired: true));

      final List<Reminder> all = await reminders.listAll();
      expect(all, hasLength(1));
      expect(all.single.isFired, isTrue);
    });

    test('deleting an absent id is a no-op', () async {
      await reminders.save(reminder);
      await reminders.delete('no-such-id');

      expect(await reminders.listAll(), hasLength(1));
    });

    test('watchAll emits on subscription and after every write', () async {
      final List<int> sizes = <int>[];
      final Stream<List<Reminder>> stream = reminders.watchAll();
      final sub = stream.listen((List<Reminder> all) => sizes.add(all.length));

      await pumpEventQueue();
      await reminders.save(reminder);
      await pumpEventQueue();

      expect(sizes, <int>[0, 1]);
      await sub.cancel();
    });
  });

  group('DriftVoiceSettingsStore', () {
    late DriftVoiceSettingsStore store;

    setUp(() => store = DriftVoiceSettingsStore(database));

    test('an unwritten store reads as the safe default', () async {
      // A first run confirms Jira writes. So does a run after a wipe.
      expect(await store.read(), const VoiceSettings());
      expect((await store.read()).alwaysConfirmJiraWrites, isTrue);
    });

    test('a written setting survives a round-trip', () async {
      await store.write(const VoiceSettings(alwaysConfirmJiraWrites: false));

      expect(
        await store.read(),
        const VoiceSettings(alwaysConfirmJiraWrites: false),
      );
    });

    test('a corrupt value reads as the default rather than failing', () async {
      await database
          .into(database.settingsRows)
          .insertOnConflictUpdate(
            SettingsRowsCompanion.insert(
              key: DriftVoiceSettingsStore.key,
              value: 'not json at all',
            ),
          );

      // Refusing to start over an unreadable checkbox would lock the user out
      // of their tasks; falling back to "confirm" cannot hurt them.
      expect(await store.read(), const VoiceSettings());
    });

    test('watch emits the current value and every change', () async {
      final List<bool> seen = <bool>[];
      final sub = store.watch().listen(
        (VoiceSettings s) => seen.add(s.alwaysConfirmJiraWrites),
      );

      await pumpEventQueue();
      await store.write(const VoiceSettings(alwaysConfirmJiraWrites: false));
      await pumpEventQueue();

      expect(seen, <bool>[true, false]);
      await sub.cancel();
    });
  });
}
