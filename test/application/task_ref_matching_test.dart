import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/add_jira_comment.dart';
import 'package:norte/application/usecases/comment_task.dart';
import 'package:norte/application/usecases/create_reminder.dart';
import 'package:norte/application/usecases/create_task.dart';
import 'package:norte/application/usecases/delete_task.dart';
import 'package:norte/application/usecases/refresh_jira_status.dart';
import 'package:norte/application/usecases/update_jira_status.dart';
import 'package:norte/application/usecases/update_task.dart';
import 'package:norte/application/voice/intent_router.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/entities/voice_settings.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/services/text_match.dart';

import '../fakes/fakes.dart';
import '../support/task_fixtures.dart';

final DateTime _now = DateTime.utc(2026, 8, 9, 10);

Task _task(String id, String title) => Task(
  id: id,
  title: title,
  status: TaskStatus.todo,
  priority: Priority.medium,
  createdAt: _now,
  updatedAt: _now,
);

/// S05b-UT-01..08 — the ladder of four tiers (`docs/architecture.md` §6.3.1).
///
/// **Real use cases over an in-memory repository**, as in `task_commands_test`
/// and for the same reason: the assertions are about which row was written to,
/// and a spy has no rows to be wrong about. The defect this sprint exists for
/// (S05b-UT-01) was a lookup returning nothing while every spy in the suite
/// was satisfied.
void main() {
  late FakeTaskRepository tasks;

  setUp(() => tasks = FakeTaskRepository());
  tearDown(() => tasks.dispose());

  IntentRouter router() {
    final FakeClock clock = FakeClock(_now);
    final FakeIdGenerator ids = FakeIdGenerator();
    final FakeOutboxRepository outbox = FakeOutboxRepository();
    return IntentRouter(
      tasks: tasks,
      createTask: CreateTask(repository: tasks, clock: clock, idGenerator: ids),
      updateTask: UpdateTask(repository: tasks, clock: clock),
      deleteTask: DeleteTask(repository: tasks),
      commentTask: CommentTask(
        repository: tasks,
        clock: clock,
        idGenerator: ids,
      ),
      createReminder: CreateReminder(
        repository: FakeReminderRepository(),
        clock: clock,
        idGenerator: ids,
      ),
      updateJiraStatus: UpdateJiraStatus(
        outbox: outbox,
        clock: clock,
        idGenerator: ids,
      ),
      addJiraComment: AddJiraComment(
        outbox: outbox,
        clock: clock,
        idGenerator: ids,
      ),
      refreshJiraStatus: RefreshJiraStatus(
        gateway: FakeJiraGateway(),
        repository: tasks,
        clock: clock,
      ),
      settings: FakeVoiceSettingsStore(const VoiceSettings()),
    );
  }

  Future<RouteOutcome> route(VoiceIntent intent) async {
    final Result<RouteOutcome> result = await router().route(intent);
    expect(result, isA<Ok<RouteOutcome>>(), reason: 'routing must not fail');
    return result.valueOrNull!;
  }

  /// An `updateTask` naming [reference] and asking for `done`.
  ///
  /// The intent of the reported defect, so every tier is exercised through the
  /// command the Developer actually spoke rather than a lookup helper the app
  /// does not call.
  VoiceIntent toDone(String reference) => VoiceIntent(
    type: IntentType.updateTask,
    slots: <String, dynamic>{'taskRef': reference, 'status': 'done'},
    confidence: 0.95,
  );

  Future<void> seed(Map<String, String> titles) async {
    for (final MapEntry<String, String> entry in titles.entries) {
      await tasks.save(_task(entry.key, entry.value));
    }
  }

  Future<Task> stored(String id) async =>
      (await tasks.listAll()).firstWhere((Task task) => task.id == id);

  group('S05b-UT-01: the reported defect, as a regression test', () {
    setUp(() => seed(<String, String>{'t1': 'HEROBRAZIL-762'}));

    test('S05b-UT-01: "Hero Brazil-762" finds HEROBRAZIL-762 and sets it '
        'done', () async {
      // 2026-08-09: the app answered "No task called 'Hero Brazil-762'".
      // One space was the entire cause — nothing was misheard and nothing was
      // misparsed (`docs/project-rules.md` §5.6 requires this test).
      final RouteOutcome outcome = await route(toDone('Hero Brazil-762'));

      expect(outcome, isNot(isA<TaskNotFound>()));
      expect(outcome, isA<IntentExecuted>());
      expect((await stored('t1')).status, TaskStatus.done);
    });

    test('S05b-UT-01: it resolved exactly, not approximately — tier 3 '
        'consults no threshold', () async {
      final RouteOutcome outcome = await route(toDone('Hero Brazil-762'));
      expect((outcome as IntentExecuted).resolvedApproximately, isFalse);
    });
  });

  group('S05b-UT-02: separators are ignored, in both directions', () {
    setUp(
      () => seed(<String, String>{
        't1': 'HEROBRAZIL-762',
        't2': 'Ligar para Samara',
      }),
    );

    for (final (String reference, String expected) in <(String, String)>[
      ('hero brazil 762', 't1'),
      ('HEROBRAZIL762', 't1'),
      ('Hero-Brazil-762', 't1'),
      ('ligarparasamara', 't2'),
    ]) {
      test('S05b-UT-02: "$reference" resolves to $expected', () async {
        final RouteOutcome outcome = await route(toDone(reference));

        expect(outcome, isA<IntentExecuted>());
        expect((await stored(expected)).status, TaskStatus.done);
        // Tier 3 is deterministic: the result must not depend on the
        // threshold, so it cannot report itself as an approximation.
        expect((outcome as IntentExecuted).resolvedApproximately, isFalse);
      });
    }
  });

  group('S05b-UT-03: a misheard letter still finds the task', () {
    setUp(() => seed(<String, String>{'t1': 'HEROBRAZIL-762'}));

    test('S05b-UT-03: "Hero Brasil-762" resolves, and says it '
        'approximated', () async {
      // A Brazilian speaker's spelling of an English word. This one is a
      // genuine transcription difference, so it is tier 4's to answer.
      final RouteOutcome outcome = await route(toDone('Hero Brasil-762'));

      expect(outcome, isA<IntentExecuted>());
      expect((outcome as IntentExecuted).resolvedApproximately, isTrue);
      expect((await stored('t1')).status, TaskStatus.done);
    });
  });

  group('S05b-UT-04: digits are not fuzzy', () {
    test('S05b-UT-04: "Hero Brasil-763" resolves to 763 and 762 is not even '
        'a candidate', () async {
      await seed(<String, String>{
        't762': 'HEROBRAZIL-762',
        't763': 'HEROBRAZIL-763',
      });

      // Both clear `similarityThreshold` — 0.923 and 0.846 — and the gap
      // between them is 0.077, which is *below* `similarityMargin`. So an
      // implementation that merely ranked the two would have to ask, and one
      // that excludes 762 outright acts. The assertion cannot pass by luck.
      expect(
        TextMatch.similarity('HEROBRAZIL-762', 'Hero Brasil-763'),
        greaterThanOrEqualTo(TextMatch.similarityThreshold),
      );
      expect(
        TextMatch.similarity('HEROBRAZIL-763', 'Hero Brasil-763') -
            TextMatch.similarity('HEROBRAZIL-762', 'Hero Brasil-763'),
        lessThan(TextMatch.similarityMargin),
      );

      final RouteOutcome outcome = await route(toDone('Hero Brasil-763'));

      expect(outcome, isNot(isA<TaskAmbiguous>()));
      expect(outcome, isA<IntentExecuted>());
      expect((await stored('t763')).status, TaskStatus.done);
      expect((await stored('t762')).status, TaskStatus.todo);
    });

    test('S05b-UT-04: one digit apart is a different chamado, not a close '
        'enough one', () async {
      await seed(<String, String>{'t762': 'HEROBRAZIL-762'});

      final RouteOutcome outcome = await route(toDone('Hero Brazil-763'));

      // Answering "close enough" here is how the wrong chamado gets closed.
      expect(outcome, isA<TaskNotFound>());
      expect((outcome as TaskNotFound).reference, 'Hero Brazil-763');
      expect((await stored('t762')).status, TaskStatus.todo);
    });
  });

  group('S05b-UT-05: a near tie asks rather than picking', () {
    test(
      'S05b-UT-05: two spellings within the margin are a question',
      () async {
        await seed(<String, String>{
          't1': 'Revisar o conector',
          't2': 'Revisar o coletor',
        });

        final RouteOutcome outcome = await route(toDone('revisar o conetor'));

        expect(outcome, isA<TaskAmbiguous>());
        expect(
          (outcome as TaskAmbiguous).candidates.map((Task t) => t.title),
          containsAll(<String>['Revisar o conector', 'Revisar o coletor']),
        );
        // No use case ran: both rows are untouched.
        expect((await stored('t1')).status, TaskStatus.todo);
        expect((await stored('t2')).status, TaskStatus.todo);
      },
    );
  });

  group('S05b-UT-06: nothing close enough is still nothing', () {
    test('S05b-UT-06: the ladder did not become a fallback that always '
        'finds something', () async {
      await seed(<String, String>{
        't1': 'Ligar para Samara',
        't2': 'Revisar PR',
      });

      final RouteOutcome outcome = await route(toDone('comprar café'));

      expect(outcome, isA<TaskNotFound>());
      expect((outcome as TaskNotFound).reference, 'comprar café');
      expect((await stored('t1')).status, TaskStatus.todo);
      expect((await stored('t2')).status, TaskStatus.todo);
    });
  });

  group('S05b-UT-07: a short reference never reaches the approximate tier', () {
    test('S05b-UT-07: "PR" finds Revisar PR by containment', () async {
      // Fixture note: the sprint file wrote the second task as "Preparar a
      // demo", whose fold *does* contain "pr" — tier 2 would return two
      // matches and the test would assert a question, not a resolution. The
      // rule under test is `minApproximateLength`, so the title was changed to
      // one that does not contain the reference (sprint-05b amendment,
      // recorded in the sprint file and the report).
      await seed(<String, String>{'t1': 'Revisar PR', 't2': 'Fazer a demo'});

      final RouteOutcome outcome = await route(toDone('PR'));

      expect(outcome, isA<IntentExecuted>());
      expect((outcome as IntentExecuted).resolvedApproximately, isFalse);
      expect((await stored('t1')).status, TaskStatus.done);
    });

    test('S05b-UT-07: with nothing to contain it, "PR" approximates its way '
        'to nothing', () async {
      await seed(<String, String>{'t2': 'Fazer a demo'});
      expect('pr'.length, lessThan(TextMatch.minApproximateLength));

      final RouteOutcome outcome = await route(toDone('PR'));

      expect(outcome, isA<TaskNotFound>());
      expect((await stored('t2')).status, TaskStatus.todo);
    });
  });

  group('S05b-UT-08: the exact tier is never beaten by a better score', () {
    test('S05b-UT-08: an exact title wins over a very close typo, with no '
        'question asked', () async {
      await seed(<String, String>{
        't1': 'Ligar para Samara',
        't2': 'Ligar para Samra', // a typo the user made when creating it
      });

      final RouteOutcome outcome = await route(toDone('Ligar para Samara'));

      expect(outcome, isNot(isA<TaskAmbiguous>()));
      expect(outcome, isA<IntentExecuted>());
      expect((outcome as IntentExecuted).resolvedApproximately, isFalse);
      expect((await stored('t1')).status, TaskStatus.done);
      expect((await stored('t2')).status, TaskStatus.todo);
    });
  });
}
