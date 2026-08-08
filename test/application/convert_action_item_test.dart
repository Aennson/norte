import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/convert_action_item_to_task.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fake_clock.dart';
import '../fakes/fake_id_generator.dart';
import '../fakes/fake_meeting_repository.dart';
import '../support/task_fixtures.dart';

/// S03-UT-05 — ActionItem → Task.
void main() {
  late FakeTaskRepository tasks;
  late FakeMeetingRepository meetings;
  late ConvertActionItemToTask convert;

  final DateTime now = DateTime.utc(2026, 8, 8, 10);

  /// A summarized meeting with the sprint's own example item.
  Meeting meetingWith({
    String? convertedTaskId,
    RetentionPolicy retention = RetentionPolicy.ephemeral,
  }) => Meeting(
    id: 'meeting-1',
    title: 'Sprint 12 retro',
    type: MeetingType.retro,
    createdAt: now,
    retention: retention,
    summary: MeetingSummary(
      sections: const <String, String>{'Action items': 'One follow-up.'},
      generatedAt: now,
      actionItems: <ActionItem>[
        ActionItem(
          id: 'item-0',
          description: 'Update the runbook',
          assignee: 'Ana',
          convertedTaskId: convertedTaskId,
        ),
        const ActionItem(id: 'item-1', description: 'Book the room'),
      ],
    ),
  );

  setUp(() {
    tasks = FakeTaskRepository();
    meetings = FakeMeetingRepository();
    convert = ConvertActionItemToTask(
      tasks: tasks,
      meetings: meetings,
      clock: FakeClock(now),
      idGenerator: FakeIdGenerator.fixed('task-1'),
    );
  });

  tearDown(() => meetings.dispose());

  group('S03-UT-05: ActionItem to Task', () {
    test(
      'S03-UT-05: the task carries the item title, todo and the tag',
      () async {
        final Result<ActionItemConversion> result = await convert(
          meeting: meetingWith(),
          itemId: 'item-0',
        );

        final Task task = result.valueOrNull!.task;
        expect(task.title, 'Update the runbook');
        expect(task.status, TaskStatus.todo);
        expect(task.tags, <String>[meetingTag]);
        expect(task.createdAt, now);
        expect(await tasks.findById('task-1'), isNotNull);
      },
    );

    test('S03-UT-05: the item is marked as converted', () async {
      final Result<ActionItemConversion> result = await convert(
        meeting: meetingWith(),
        itemId: 'item-0',
      );

      final Meeting updated = result.valueOrNull!.meeting;
      final ActionItem item = updated.summary!.itemById('item-0')!;
      expect(item.convertedTaskId, 'task-1');
      expect(item.isConverted, isTrue);
      // Its neighbour is untouched — conversion is individual.
      expect(updated.summary!.itemById('item-1')!.isConverted, isFalse);
    });

    test('S03-UT-05: converting the same item again is refused', () async {
      final Result<ActionItemConversion> result = await convert(
        meeting: meetingWith(convertedTaskId: 'task-earlier'),
        itemId: 'item-0',
      );

      expect(result.failureOrNull, isA<AlreadyConvertedFailure>());
      expect(
        (result.failureOrNull! as AlreadyConvertedFailure).taskId,
        'task-earlier',
      );
      // And no second task exists.
      expect(tasks.saved, isEmpty);
    });

    test(
      'S03-UT-05: a second conversion through the real path is refused',
      () async {
        // The realistic version of the case above: convert, take the meeting
        // that comes back, and try the same item on it.
        final Meeting once = (await convert(
          meeting: meetingWith(),
          itemId: 'item-0',
        )).valueOrNull!.meeting;

        final Result<ActionItemConversion> twice = await convert(
          meeting: once,
          itemId: 'item-0',
        );

        expect(twice.failureOrNull, isA<AlreadyConvertedFailure>());
        expect(tasks.saved, hasLength(1));
      },
    );
  });

  group('the reference back to the meeting', () {
    test('is set when the meeting is stored', () async {
      final Meeting meeting = meetingWith(retention: RetentionPolicy.persisted);
      await meetings.save(meeting);

      final Result<ActionItemConversion> result = await convert(
        meeting: meeting,
        itemId: 'item-0',
      );

      expect(result.valueOrNull!.task.sourceMeetingId, 'meeting-1');
    });

    test('is null when the meeting has not been saved', () async {
      // "A reference to the meeting id (if saved)" — an unsaved meeting is
      // discarded on exit, so a task pointing at it would point at nothing.
      final Result<ActionItemConversion> result = await convert(
        meeting: meetingWith(),
        itemId: 'item-0',
      );

      expect(result.valueOrNull!.task.sourceMeetingId, isNull);
    });

    test('a stored meeting is written back with the mark', () async {
      final Meeting meeting = meetingWith(retention: RetentionPolicy.persisted);
      await meetings.save(meeting);
      meetings.saved.clear();

      await convert(meeting: meeting, itemId: 'item-0');

      final Meeting written = meetings.saved.single;
      expect(written.summary!.itemById('item-0')!.convertedTaskId, 'task-1');
    });

    test('an unsaved meeting is not persisted as a side effect', () async {
      // Writing it here would persist a meeting the user has not asked to
      // keep — and with it a transcript BR-03 says is already gone.
      await convert(meeting: meetingWith(), itemId: 'item-0');

      expect(meetings.saved, isEmpty);
    });
  });

  group('what cannot be converted', () {
    test('an unknown item id', () async {
      final Result<ActionItemConversion> result = await convert(
        meeting: meetingWith(),
        itemId: 'item-9',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(tasks.saved, isEmpty);
    });

    test('a meeting with no summary', () async {
      final Result<ActionItemConversion> result = await convert(
        meeting: Meeting(id: 'm', title: 'Retro', createdAt: now),
        itemId: 'item-0',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('an item whose description is only whitespace', () async {
      final Meeting blank = Meeting(
        id: 'm',
        title: 'Retro',
        createdAt: now,
        summary: MeetingSummary(
          sections: const <String, String>{},
          generatedAt: now,
          actionItems: const <ActionItem>[
            ActionItem(id: 'item-0', description: '   '),
          ],
        ),
      );

      final Result<ActionItemConversion> result = await convert(
        meeting: blank,
        itemId: 'item-0',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(tasks.saved, isEmpty);
    });

    test('a storage failure is returned, not thrown', () async {
      tasks.failWith = const StorageFailure('disk full');

      final Result<ActionItemConversion> result = await convert(
        meeting: meetingWith(),
        itemId: 'item-0',
      );

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });

  group('what the item carries across', () {
    test('the due date becomes the task due date', () async {
      final DateTime due = DateTime.utc(2026, 8, 15);
      final Meeting meeting = Meeting(
        id: 'm',
        title: 'Retro',
        createdAt: now,
        summary: MeetingSummary(
          sections: const <String, String>{},
          generatedAt: now,
          actionItems: <ActionItem>[
            ActionItem(id: 'item-0', description: 'Ship it', dueDate: due),
          ],
        ),
      );

      final Result<ActionItemConversion> result = await convert(
        meeting: meeting,
        itemId: 'item-0',
      );

      expect(result.valueOrNull!.task.dueDate, due);
    });

    test('the assignee is recorded rather than dropped', () async {
      // Norte is single-user, so there is no assignee field to put it in —
      // but losing "Ana said she would do this" loses the meeting's meaning.
      final Result<ActionItemConversion> result = await convert(
        meeting: meetingWith(),
        itemId: 'item-0',
      );

      expect(result.valueOrNull!.task.description, contains('Ana'));
    });

    test('an item with no assignee makes a task with no description', () async {
      final Result<ActionItemConversion> result = await convert(
        meeting: meetingWith(),
        itemId: 'item-1',
      );

      expect(result.valueOrNull!.task.description, isNull);
    });
  });
}
