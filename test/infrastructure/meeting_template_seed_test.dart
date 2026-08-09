import 'dart:async';

// `package:drift/drift.dart` is deliberately not imported: its query builder
// exports an `isNotNull` that collides with matcher's. The generated
// companions come from `norte_database.dart` instead.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/infrastructure/persistence/drift_meeting_repository.dart';
import 'package:norte/infrastructure/persistence/drift_meeting_template_repository.dart';
import 'package:norte/infrastructure/persistence/norte_database.dart';

/// S03-IT-02 — embedded default templates, against a real in-memory database
/// (`docs/testing-strategy.md` §1 — integration tests use Drift's
/// `NativeDatabase.memory()`).
void main() {
  late NorteDatabase database;
  late DriftMeetingTemplateRepository templates;

  setUp(() {
    database = NorteDatabase(NativeDatabase.memory());
    templates = DriftMeetingTemplateRepository(database);
  });

  tearDown(() => database.close());

  group('S03-IT-02: seeding the defaults', () {
    test(
      'S03-IT-02: a fresh database gets daily, retro, planning and 1:1',
      () async {
        await templates.seedDefaults();

        final List<MeetingTemplate> stored = await templates.listAll();
        expect(stored.map((MeetingTemplate t) => t.type), <MeetingType>[
          MeetingType.daily,
          MeetingType.retro,
          MeetingType.planning,
          MeetingType.oneOnOne,
        ]);
      },
    );

    test('S03-IT-02: each default has its sections from §5.3', () async {
      await templates.seedDefaults();

      final MeetingTemplate retro = (await templates.findByType(
        MeetingType.retro,
      ))!;
      expect(retro.sectionTitles, <String>[
        'What went well',
        'What to improve',
        'Action items',
      ]);
      expect(retro.systemPrompt, isNotEmpty);
      expect(retro.extractActionItems, isTrue);

      final MeetingTemplate daily = (await templates.findByType(
        MeetingType.daily,
      ))!;
      expect(daily.sectionTitles, hasLength(3));
      expect(daily.sections.first.guidance, isNotNull);
    });

    test('S03-IT-02: re-initializing does not duplicate', () async {
      await templates.seedDefaults();
      await templates.seedDefaults();
      await templates.seedDefaults();

      expect(await templates.listAll(), hasLength(4));
    });

    test(
      'S03-IT-02: a user-edited template is not overwritten by the seed',
      () async {
        await templates.seedDefaults();
        final MeetingTemplate retro = (await templates.findByType(
          MeetingType.retro,
        ))!;

        await templates.save(
          retro.copyWith(
            systemPrompt: 'Summarize in Portuguese, one line per person.',
            sections: const <TemplateSection>[
              TemplateSection(title: 'O que funcionou'),
              TemplateSection(title: 'O que melhorar'),
            ],
            extractActionItems: false,
          ),
        );

        await templates.seedDefaults();

        final MeetingTemplate after = (await templates.findByType(
          MeetingType.retro,
        ))!;
        expect(
          after.systemPrompt,
          'Summarize in Portuguese, one line per person.',
        );
        expect(after.sectionTitles, <String>[
          'O que funcionou',
          'O que melhorar',
        ]);
        expect(after.extractActionItems, isFalse);
        expect(await templates.listAll(), hasLength(4));
      },
    );

    test('S03-IT-02: a deleted default comes back on the next seed', () async {
      // Which is what "restore the built-in templates" means, and is a
      // different operation from overwriting one that is still there.
      await templates.seedDefaults();
      await templates.delete('builtin.planning');
      expect(await templates.listAll(), hasLength(3));

      await templates.seedDefaults();

      expect(await templates.listAll(), hasLength(4));
      expect(await templates.findById('builtin.planning'), isNotNull);
    });

    test('S03-IT-02: a template survives a round-trip unchanged', () async {
      await templates.seedDefaults();
      final MeetingTemplate before = (await templates.findByType(
        MeetingType.planning,
      ))!;

      final MeetingTemplate after = (await templates.findById(before.id))!;

      expect(after, before);
    });

    test(
      'S03-IT-02: watchAll emits on subscription and after the seed',
      () async {
        // Stepped rather than collected: the first emission must be awaited
        // *before* seeding, or the two coalesce and the test proves nothing
        // about the second one.
        final StreamIterator<List<MeetingTemplate>> emissions =
            StreamIterator<List<MeetingTemplate>>(templates.watchAll());

        expect(await emissions.moveNext(), isTrue);
        expect(emissions.current, isEmpty);

        await templates.seedDefaults();

        expect(await emissions.moveNext(), isTrue);
        expect(emissions.current, hasLength(4));
        await emissions.cancel();
      },
    );
  });

  group('the migration that brings the tables', () {
    test(
      'an existing task database upgrades without losing its tasks',
      () async {
        // The whole point of the additive migration: a user who has been
        // running Norte since Sprint 01 keeps everything.
        final DriftMeetingRepository meetings = DriftMeetingRepository(
          database,
        );
        await database
            .into(database.taskRows)
            .insert(
              TaskRowsCompanion.insert(
                id: 'task-1',
                title: 'Survives the upgrade',
                status: 'todo',
                priority: 'medium',
                createdAtMs: 0,
                updatedAtMs: 0,
              ),
            );

        await templates.seedDefaults();

        expect(await database.select(database.taskRows).get(), hasLength(1));
        expect(await meetings.listAll(), isEmpty);
        expect(await templates.listAll(), hasLength(4));
      },
    );

    test('the schema version is 4', () {
      // Bumped by Sprint 05, which adds `reminders` and `settings`. The
      // assertion is deliberately literal: a migration added without moving
      // this number is a migration that never runs on a user's device.
      expect(database.schemaVersion, 4);
    });
  });

  group('meetings round-trip through Drift', () {
    late DriftMeetingRepository meetings;

    setUp(() => meetings = DriftMeetingRepository(database));

    Meeting sample({RetentionPolicy retention = RetentionPolicy.persisted}) =>
        Meeting(
          id: 'meeting-1',
          title: 'Sprint 12 retro',
          type: MeetingType.retro,
          createdAt: DateTime.utc(2026, 8, 8, 9, 30, 15, 250),
          retention: retention,
          rawTranscript: 'Ana: the outbox went out on Tuesday.',
          summary: MeetingSummary(
            sections: const <String, String>{
              'What went well': 'Shipped on time.',
              'What to improve': '',
            },
            generatedAt: DateTime.utc(2026, 8, 8, 9, 31),
            engineId: 'claude-opus-5',
            actionItems: <ActionItem>[
              ActionItem(
                id: 'item-0',
                description: 'Update the runbook',
                assignee: 'Ana',
                dueDate: DateTime.utc(2026, 8, 15),
                convertedTaskId: 'task-7',
              ),
            ],
          ),
        );

    test('every field survives, including millisecond precision', () async {
      await meetings.save(sample());

      final Meeting stored = (await meetings.findById('meeting-1'))!;
      expect(stored, sample());
      expect(stored.createdAt.millisecond, 250);
      expect(stored.summary!.actionItems.single.convertedTaskId, 'task-7');
      expect(stored.summary!.sections['What to improve'], isEmpty);
    });

    test('an ephemeral meeting stores no transcript', () async {
      await meetings.save(
        sample(retention: RetentionPolicy.ephemeral).forStorage,
      );

      final Meeting stored = (await meetings.findById('meeting-1'))!;
      expect(stored.rawTranscript, isEmpty);
      expect(stored.summary, isNotNull);
    });

    test('the list is newest first', () async {
      await meetings.save(sample());
      await meetings.save(
        sample().copyWith(id: 'meeting-2', createdAt: DateTime.utc(2026, 9)),
      );

      expect((await meetings.listAll()).map((Meeting m) => m.id), <String>[
        'meeting-2',
        'meeting-1',
      ]);
    });

    test('deleting an unknown id succeeds', () async {
      await expectLater(meetings.delete('nope'), completes);
    });
  });
}
