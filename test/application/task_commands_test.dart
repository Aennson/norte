import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/add_jira_comment.dart';
import 'package:norte/application/usecases/comment_task.dart';
import 'package:norte/application/usecases/create_reminder.dart';
import 'package:norte/application/usecases/create_task.dart';
import 'package:norte/application/usecases/delete_task.dart';
import 'package:norte/application/usecases/list_tasks.dart';
import 'package:norte/application/usecases/refresh_jira_status.dart';
import 'package:norte/application/usecases/update_jira_status.dart';
import 'package:norte/application/usecases/update_task.dart';
import 'package:norte/application/voice/intent_router.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/task_comment.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/entities/voice_settings.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fakes.dart';
import '../support/task_fixtures.dart';

final DateTime _now = DateTime.utc(2026, 8, 9, 10);

Task _task(
  String id,
  String title, {
  String? description,
  TaskStatus status = TaskStatus.todo,
  Priority priority = Priority.medium,
  JiraLink? jiraLink,
  List<TaskComment> comments = const <TaskComment>[],
}) => Task(
  id: id,
  title: title,
  description: description,
  status: status,
  priority: priority,
  jiraLink: jiraLink,
  comments: comments,
  createdAt: _now,
  updatedAt: _now,
);

/// S05a-UT-01..07 — the four local task intents, routed for real.
///
/// **Real use cases over an in-memory repository, not spies.** Sprint 05's
/// router tests mock the use cases, which is right for asserting *that* a
/// branch was taken; these assert what the branch *did* — all four attributes
/// on the created task, the row that survived a deletion, the outbox that
/// stayed empty. A spy cannot fail those, because a spy has no state to be
/// wrong about (`sprint-05` report §5).
void main() {
  late FakeTaskRepository tasks;
  late FakeOutboxRepository outbox;
  late FakeJiraGateway jira;
  late FakeIdGenerator ids;

  setUp(() {
    tasks = FakeTaskRepository();
    outbox = FakeOutboxRepository();
    jira = FakeJiraGateway();
    ids = FakeIdGenerator();
  });

  tearDown(() => tasks.dispose());

  IntentRouter router() {
    final FakeClock clock = FakeClock(_now);
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
        gateway: jira,
        repository: tasks,
        clock: clock,
      ),
      settings: FakeVoiceSettingsStore(const VoiceSettings()),
    );
  }

  Future<RouteOutcome> route(
    VoiceIntent intent, {
    bool confirmed = false,
    String? taskId,
  }) async {
    final Result<RouteOutcome> result = await router().route(
      intent,
      confirmed: confirmed,
      taskId: taskId,
    );
    expect(result, isA<Ok<RouteOutcome>>(), reason: 'routing must not fail');
    return result.valueOrNull!;
  }

  group('S05a-UT-01: rich creation from one utterance', () {
    const VoiceIntent rich = VoiceIntent(
      type: IntentType.createTask,
      slots: <String, dynamic>{
        'title': 'Ligar para Samara',
        'description': 'confirmar o orçamento',
        'status': 'inProgress',
        'priority': 'urgent',
      },
      confidence: 0.95,
    );

    test('S05a-UT-01: all four attributes reach the stored task', () async {
      final RouteOutcome outcome = await route(rich);

      expect(outcome, isA<IntentExecuted>());
      final Task created = (outcome as IntentExecuted).task!;
      expect(created.title, 'Ligar para Samara');
      expect(created.description, 'confirmar o orçamento');
      expect(created.status, TaskStatus.inProgress);
      expect(created.priority, Priority.urgent);
      // Stored, not merely returned: a router that built the entity and never
      // saved it would satisfy every assertion above.
      expect(await tasks.listAll(), <Task>[created]);
    });

    test('S05a-UT-01: no confirmation sheet — a local intent at 0.95 '
        'simply runs', () async {
      expect(await route(rich), isNot(isA<ConfirmationRequired>()));
    });
  });

  group('S05a-UT-02: status and priority vocabularies (§6.3.2)', () {
    for (final (String wire, TaskStatus expected) in <(String, TaskStatus)>[
      ('todo', TaskStatus.todo),
      ('inProgress', TaskStatus.inProgress),
      ('done', TaskStatus.done),
      ('blocked', TaskStatus.blocked),
    ]) {
      test('S05a-UT-02: status "$wire" maps to ${expected.name}', () async {
        final RouteOutcome outcome = await route(
          VoiceIntent(
            type: IntentType.createTask,
            slots: <String, dynamic>{'title': 'x', 'status': wire},
            confidence: 0.9,
          ),
        );
        expect((outcome as IntentExecuted).task!.status, expected);
      });
    }

    for (final (String wire, Priority expected) in <(String, Priority)>[
      ('low', Priority.low),
      ('medium', Priority.medium),
      ('high', Priority.high),
      ('urgent', Priority.urgent),
    ]) {
      test('S05a-UT-02: priority "$wire" maps to ${expected.name}', () async {
        final RouteOutcome outcome = await route(
          VoiceIntent(
            type: IntentType.createTask,
            slots: <String, dynamic>{'title': 'x', 'priority': wire},
            confidence: 0.9,
          ),
        );
        expect((outcome as IntentExecuted).task!.priority, expected);
      });
    }

    test('S05a-UT-02: a value outside the vocabulary is absent, not '
        'silently defaulted', () async {
      // The distinction the test exists for. On a *create* an unreadable value
      // and an absent one both leave `CreateTask`'s own default, so the proof
      // has to come from an update: `urgente` is not `urgent`, and a task the
      // user never asked to change must come back unchanged.
      await tasks.save(
        _task('t1', 'Ligar para Samara', priority: Priority.high),
      );

      final RouteOutcome outcome = await route(
        const VoiceIntent(
          type: IntentType.updateTask,
          slots: <String, dynamic>{
            'taskRef': 'samara',
            'priority': 'urgente',
            'status': 'em progresso',
            // One readable slot, so the intent is not merely incomplete.
            'title': 'Ligar para Samara amanhã',
          },
          confidence: 0.9,
        ),
      );

      final Task updated = (outcome as IntentExecuted).task!;
      expect(updated.title, 'Ligar para Samara amanhã');
      expect(updated.priority, Priority.high, reason: 'unchanged, not medium');
      expect(updated.status, TaskStatus.todo, reason: 'unchanged');
    });
  });

  group('S05a-UT-03: taskRef resolves to exactly one task (§6.3.1)', () {
    setUp(() async {
      await tasks.save(_task('t1', 'Ligar para Samara'));
      await tasks.save(_task('t2', 'Revisar PR'));
    });

    test('S05a-UT-03: a reference differing in case and accent still '
        'finds the task', () async {
      final RouteOutcome outcome = await route(
        const VoiceIntent(
          type: IntentType.updateTask,
          slots: <String, dynamic>{'taskRef': 'SAMÁRA', 'status': 'done'},
          confidence: 0.9,
        ),
      );

      expect((outcome as IntentExecuted).task!.id, 't1');
      expect((await tasks.findById('t1'))!.status, TaskStatus.done);
      expect((await tasks.findById('t2'))!.status, TaskStatus.todo);
    });

    test('S05a-UT-03: a reference matching nothing writes nothing', () async {
      final RouteOutcome outcome = await route(
        const VoiceIntent(
          type: IntentType.updateTask,
          slots: <String, dynamic>{'taskRef': 'nada disso', 'status': 'done'},
          confidence: 0.9,
        ),
      );

      expect(outcome, isA<TaskNotFound>());
      expect((outcome as TaskNotFound).reference, 'nada disso');
      // The whole point of case 3: not a guess, not an error — a no-op.
      expect(tasks.savedIds, <String>['t1', 't2'], reason: 'only the setup');
      expect(tasks.deletedIds, isEmpty);
    });
  });

  group('S05a-UT-04: an ambiguous taskRef asks rather than guesses', () {
    setUp(() async {
      await tasks.save(_task('t1', 'Ligar para Samara'));
      await tasks.save(_task('t2', 'Ligar para Samara de novo'));
    });

    const VoiceIntent ambiguous = VoiceIntent(
      type: IntentType.updateTask,
      slots: <String, dynamic>{
        'taskRef': 'ligar para samara de',
        'status': 'done',
      },
      confidence: 0.9,
    );

    test(
      'S05a-UT-04: both candidates are named and no use case runs',
      () async {
        // The reference is a prefix of both titles and equal to neither, so
        // there is nothing to prefer — which is exactly when the app must ask.
        await tasks.save(_task('t3', 'Ligar para Samara de tarde'));

        final RouteOutcome outcome = await route(ambiguous);

        expect(outcome, isA<TaskAmbiguous>());
        expect(
          (outcome as TaskAmbiguous).candidates.map((Task t) => t.id),
          <String>['t2', 't3'],
        );
        expect(tasks.savedIds, <String>[
          't1',
          't2',
          't3',
        ], reason: 'setup only');
      },
    );

    test(
      'S05a-UT-04: answering with one of them completes the command',
      () async {
        await tasks.save(_task('t3', 'Ligar para Samara de tarde'));

        final RouteOutcome outcome = await route(ambiguous, taskId: 't3');

        expect((outcome as IntentExecuted).task!.id, 't3');
        expect((await tasks.findById('t3'))!.status, TaskStatus.done);
        expect((await tasks.findById('t2'))!.status, TaskStatus.todo);
      },
    );

    test(
      'S05a-UT-04: an exact title is not held hostage by a longer one',
      () async {
        // "Ligar para Samara" is contained in "Ligar para Samara de novo", so a
        // naive contains-match would make the shorter task permanently
        // unreachable. Equality wins over containment.
        final RouteOutcome outcome = await route(
          const VoiceIntent(
            type: IntentType.deleteTask,
            slots: <String, dynamic>{'taskRef': 'Ligar para Samara'},
            confidence: 0.9,
          ),
          confirmed: true,
        );

        expect((outcome as IntentExecuted).deletedTitle, 'Ligar para Samara');
        expect(tasks.deletedIds, <String>['t1']);
      },
    );
  });

  group('S05a-UT-05: deletion always confirms', () {
    setUp(() => tasks.save(_task('t1', 'Ligar para Samara')));

    VoiceIntent deleteAt(double confidence) => VoiceIntent(
      type: IntentType.deleteTask,
      slots: const <String, dynamic>{'taskRef': 'samara'},
      confidence: confidence,
    );

    for (final double confidence in <double>[0.99, 0.40]) {
      test(
        'S05a-UT-05: at $confidence it still asks, and nothing is deleted',
        () async {
          final RouteOutcome outcome = await route(deleteAt(confidence));

          expect(outcome, isA<ConfirmationRequired>());
          // BR-04's threshold is a floor here, not a gate: the reason is the
          // irreversibility, not a doubtful parse, and 0.99 must not read as
          // "I am not sure I understood".
          expect(
            (outcome as ConfirmationRequired).reason,
            ConfirmationReason.deletion,
          );
          // The sheet can name the row it is about.
          expect(outcome.task!.title, 'Ligar para Samara');
          expect(tasks.deletedIds, isEmpty);
          expect(await tasks.listAll(), hasLength(1));
        },
      );
    }

    test('S05a-UT-05: confirming deletes exactly one task', () async {
      await tasks.save(_task('t2', 'Revisar PR'));

      final RouteOutcome outcome = await route(
        deleteAt(0.99),
        confirmed: true,
        taskId: 't1',
      );

      expect((outcome as IntentExecuted).deletedTitle, 'Ligar para Samara');
      expect(tasks.deletedIds, <String>['t1']);
      expect((await tasks.listAll()).single.id, 't2');
    });
  });

  group('S05a-UT-06: a local comment never reaches Jira (BR-01, §3.2)', () {
    test(
      'S05a-UT-06: the note lands on the task and the outbox stays empty',
      () async {
        await tasks.save(
          _task(
            't1',
            'Ligar para Samara',
            jiraLink: const JiraLink(
              issueKey: 'PROJ-123',
              siteUrl: 'https://example.atlassian.net',
            ),
          ),
        );

        final RouteOutcome outcome = await route(
          const VoiceIntent(
            type: IntentType.commentTask,
            slots: <String, dynamic>{
              'taskRef': 'samara',
              'comment': 'cliente retornou',
            },
            confidence: 0.9,
          ),
        );

        final Task commented = (outcome as IntentExecuted).task!;
        expect(commented.comments.single.body, 'cliente retornou');
        expect(commented.comments.single.createdAt, _now);
        // The assertion the rule turns on. The task is *linked*, so a router
        // that conflated the two intents would have queued something here.
        expect(outcome.operation, isNull);
        expect(outcome.intent.type, IntentType.commentTask);
        expect(outcome.intent.type.writesToJira, isFalse);
        expect(
          outbox.operations,
          isEmpty,
          reason: 'a private note must not become a comment the team reads',
        );
        expect(jira.writes, isEmpty);
        expect(jira.reads, isEmpty);
      },
    );

    test(
      'S05a-UT-06: comments accumulate in the order they were made',
      () async {
        await tasks.save(_task('t1', 'Ligar para Samara'));

        for (final String body in <String>['primeiro', 'segundo', 'terceiro']) {
          await route(
            VoiceIntent(
              type: IntentType.commentTask,
              slots: <String, dynamic>{'taskRef': 'samara', 'comment': body},
              confidence: 0.9,
            ),
          );
        }

        expect(
          (await tasks.findById('t1'))!.comments.map((TaskComment c) => c.body),
          <String>['primeiro', 'segundo', 'terceiro'],
        );
      },
    );
  });

  group('S05a-UT-07: Jira is not chosen without being named', () {
    test('S05a-UT-07: no local utterance in the dataset produces a Jira '
        'intent', () async {
      // The dataset rows themselves are exercised by S05-EV-01; this asserts
      // the *routing* half of the same rule — that a local intent, however it
      // arrived, cannot reach a Jira use case.
      await tasks.save(
        _task(
          't1',
          'Ligar para Samara',
          jiraLink: const JiraLink(
            issueKey: 'PROJ-123',
            siteUrl: 'https://example.atlassian.net',
          ),
        ),
      );

      final List<VoiceIntent> local = <VoiceIntent>[
        const VoiceIntent(
          type: IntentType.createTask,
          slots: <String, dynamic>{'title': 'Ligar para Samara'},
          confidence: 0.9,
        ),
        const VoiceIntent(
          type: IntentType.updateTask,
          slots: <String, dynamic>{'taskRef': 'samara', 'status': 'done'},
          confidence: 0.9,
        ),
        const VoiceIntent(
          type: IntentType.commentTask,
          slots: <String, dynamic>{'taskRef': 'samara', 'comment': 'oi'},
          confidence: 0.9,
        ),
        const VoiceIntent(
          type: IntentType.deleteTask,
          slots: <String, dynamic>{'taskRef': 'samara'},
          confidence: 0.9,
        ),
      ];

      for (final VoiceIntent intent in local) {
        await route(intent, confirmed: true);
        expect(intent.type.writesToJira, isFalse, reason: intent.type.name);
      }

      expect(outbox.operations, isEmpty);
      expect(jira.writes, isEmpty);
      expect(jira.reads, isEmpty);
    });

    test('S05a-UT-07: an updateTask that names no change asks what to '
        'change', () async {
      await tasks.save(_task('t1', 'Ligar para Samara'));

      final RouteOutcome outcome = await route(
        const VoiceIntent(
          type: IntentType.updateTask,
          slots: <String, dynamic>{'taskRef': 'samara'},
          confidence: 0.9,
        ),
      );

      expect((outcome as SlotMissing).slot, VoiceIntent.changeSlot);
      expect((await tasks.findById('t1'))!.status, TaskStatus.todo);
    });
  });

  group('S05a-UT-08: filters compose', () {
    List<Task> spread() => <Task>[
      _task('a', 'Ligar para Samara', status: TaskStatus.todo),
      _task('b', 'Revisar PR', status: TaskStatus.blocked),
      _task(
        'c',
        'Preparar a demo',
        description: 'ligar o projetor',
        status: TaskStatus.blocked,
      ),
      _task('d', 'Ligar para o suporte', status: TaskStatus.inProgress),
      _task('e', 'Ligar para o cliente', status: TaskStatus.done),
    ];

    test(
      'S05a-UT-08: two statuses are a union, and the search narrows it',
      () async {
        final List<Task> result = ListTasks.apply(
          spread(),
          const TaskQuery(
            statuses: <TaskStatus>{TaskStatus.todo, TaskStatus.blocked},
            search: 'ligar',
          ),
        );

        // `b` is blocked but says nothing about calling; `d` and `e` do but are
        // neither todo nor blocked. Both filters have to bite for this to hold.
        expect(result.map((Task t) => t.id), <String>['a', 'c']);
      },
    );

    test('S05a-UT-08: filtering does not reorder what it keeps', () async {
      final List<Task> all = spread();
      final List<Task> unfiltered = ListTasks.apply(all, const TaskQuery());
      final List<Task> filtered = ListTasks.apply(
        all,
        const TaskQuery(
          statuses: <TaskStatus>{TaskStatus.todo, TaskStatus.blocked},
        ),
      );

      final List<String> kept = <String>[
        for (final Task task in unfiltered)
          if (filtered.any((Task other) => other.id == task.id)) task.id,
      ];
      expect(filtered.map((Task t) => t.id), kept);
    });

    test('S05a-UT-08: an empty search box is not a filter', () async {
      const TaskQuery blank = TaskQuery(search: '   ');
      expect(blank.isUnfiltered, isTrue);
      expect(ListTasks.apply(spread(), blank), hasLength(5));
    });
  });

  group('S05a-UT-09: search reads the description too', () {
    final List<Task> stored = <Task>[
      _task('a', 'Ligar para Samara', description: 'confirmar o orçamento'),
      _task('b', 'Revisar PR'),
    ];

    test(
      'S05a-UT-09: a term only the description carries still finds it',
      () async {
        final List<Task> result = ListTasks.apply(
          stored,
          const TaskQuery(search: 'orçamento'),
        );

        expect(result.single.id, 'a');
        expect(result.single.title, isNot(contains('orçamento')));
      },
    );

    test('S05a-UT-09: the match is case- and accent-insensitive', () async {
      for (final String term in <String>[
        'ORÇAMENTO',
        'orcamento',
        'Orcamento',
      ]) {
        expect(
          ListTasks.apply(stored, TaskQuery(search: term)).single.id,
          'a',
          reason: term,
        );
      }
    });
  });
}
