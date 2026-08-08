import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:norte/application/usecases/add_jira_comment.dart';
import 'package:norte/application/usecases/create_reminder.dart';
import 'package:norte/application/usecases/create_task.dart';
import 'package:norte/application/usecases/refresh_jira_status.dart';
import 'package:norte/application/usecases/update_jira_status.dart';
import 'package:norte/application/voice/intent_router.dart';
import 'package:norte/domain/entities/jira_link.dart';
import 'package:norte/domain/entities/outbox_operation.dart';
import 'package:norte/domain/entities/reminder.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/entities/voice_settings.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/ports/task_repository.dart';

class _SpyCreateTask extends Mock implements CreateTask {}

class _SpyCreateReminder extends Mock implements CreateReminder {}

class _SpyUpdateJiraStatus extends Mock implements UpdateJiraStatus {}

class _SpyAddJiraComment extends Mock implements AddJiraComment {}

class _SpyRefreshJiraStatus extends Mock implements RefreshJiraStatus {}

class _MockTaskRepository extends Mock implements TaskRepository {}

final DateTime _now = DateTime.utc(2026, 8, 8, 12);

/// A task already linked to PROJ-123 — the state every Jira intent needs.
final Task linkedTask = Task(
  id: 'task-1',
  title: 'revisar o conector',
  createdAt: _now,
  updatedAt: _now,
  jiraLink: const JiraLink(
    issueKey: 'PROJ-123',
    siteUrl: 'https://example.atlassian.net',
  ),
);

final OutboxOperation queuedOperation = OutboxOperation(
  operationId: 'op-1',
  kind: OutboxOperationKind.transition,
  issueKey: 'PROJ-123',
  payload: 'Done',
  taskId: 'task-1',
  createdAt: _now,
);

/// S05-UT-03, S05-UT-04 and S05-UT-05 — the intent router.
void main() {
  late _SpyCreateTask createTask;
  late _SpyCreateReminder createReminder;
  late _SpyUpdateJiraStatus updateJiraStatus;
  late _SpyAddJiraComment addJiraComment;
  late _SpyRefreshJiraStatus refreshJiraStatus;
  late _MockTaskRepository tasks;

  setUpAll(() {
    registerFallbackValue(linkedTask);
    registerFallbackValue(Priority.medium);
  });

  setUp(() {
    createTask = _SpyCreateTask();
    createReminder = _SpyCreateReminder();
    updateJiraStatus = _SpyUpdateJiraStatus();
    addJiraComment = _SpyAddJiraComment();
    refreshJiraStatus = _SpyRefreshJiraStatus();
    tasks = _MockTaskRepository();

    when(() => tasks.listAll()).thenAnswer((_) async => <Task>[linkedTask]);
    when(
      () => createTask(
        title: any(named: 'title'),
        priority: any(named: 'priority'),
        dueDate: any(named: 'dueDate'),
      ),
    ).thenAnswer((_) async => Ok<Task>(linkedTask));
    when(
      () => createReminder(
        text: any(named: 'text'),
        triggerAt: any(named: 'triggerAt'),
      ),
    ).thenAnswer(
      (_) async => Ok<Reminder>(
        Reminder(
          id: 'r-1',
          text: 'responder o e-mail',
          triggerAt: _now,
          createdAt: _now,
        ),
      ),
    );
    when(
      () => updateJiraStatus(
        task: any(named: 'task'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => Ok<OutboxOperation>(queuedOperation));
    when(
      () => addJiraComment(
        task: any(named: 'task'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => Ok<OutboxOperation>(queuedOperation));
    when(() => refreshJiraStatus(any())).thenAnswer(
      (_) async => Ok<JiraRefresh>(
        JiraRefresh(
          task: linkedTask,
          remoteStatus: 'In Progress',
          hasDivergence: false,
        ),
      ),
    );
  });

  IntentRouter routerWith({bool alwaysConfirmJiraWrites = true}) =>
      IntentRouter(
        tasks: tasks,
        createTask: createTask,
        createReminder: createReminder,
        updateJiraStatus: updateJiraStatus,
        addJiraComment: addJiraComment,
        refreshJiraStatus: refreshJiraStatus,
        settings: VoiceSettings(
          alwaysConfirmJiraWrites: alwaysConfirmJiraWrites,
        ),
      );

  RouteOutcome outcomeOf(Result<RouteOutcome> result) {
    expect(result, isA<Ok<RouteOutcome>>(), reason: 'routing must not fail');
    return result.valueOrNull!;
  }

  group('S05-UT-03: confidence decides confirmation (BR-04)', () {
    VoiceIntent createTaskAt(double confidence) => VoiceIntent(
      type: IntentType.createTask,
      slots: const <String, dynamic>{'title': 'revisar PR do conector'},
      confidence: confidence,
    );

    test(
      'S05-UT-03: 0.74 asks first, and the use case is never called',
      () async {
        final RouteOutcome outcome = outcomeOf(
          await routerWith().route(createTaskAt(0.74)),
        );

        expect(outcome, isA<ConfirmationRequired>());
        expect(
          (outcome as ConfirmationRequired).reason,
          ConfirmationReason.lowConfidence,
        );
        // The point of the guard order: nothing ran, so there is nothing to
        // undo if the user says no.
        verifyNever(
          () => createTask(
            title: any(named: 'title'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          ),
        );
      },
    );

    test('S05-UT-03: 0.76 runs straight through', () async {
      final RouteOutcome outcome = outcomeOf(
        await routerWith().route(createTaskAt(0.76)),
      );

      expect(outcome, isA<IntentExecuted>());
      expect((outcome as IntentExecuted).task, linkedTask);
      verify(
        () => createTask(
          title: 'revisar PR do conector',
          priority: Priority.medium,
          dueDate: null,
        ),
      ).called(1);
    });

    test(
      'S05-UT-03: the threshold itself passes — 0.75 is not "under"',
      () async {
        expect(
          outcomeOf(await routerWith().route(createTaskAt(0.75))),
          isA<IntentExecuted>(),
        );
      },
    );

    test('S05-UT-03: confirming the 0.74 intent then runs it', () async {
      final RouteOutcome outcome = outcomeOf(
        await routerWith().route(createTaskAt(0.74), confirmed: true),
      );

      expect(outcome, isA<IntentExecuted>());
      verify(
        () => createTask(
          title: any(named: 'title'),
          priority: any(named: 'priority'),
          dueDate: any(named: 'dueDate'),
        ),
      ).called(1);
    });
  });

  group('S05-UT-04: Jira writes always confirm', () {
    const VoiceIntent confidentTransition = VoiceIntent(
      type: IntentType.updateJira,
      slots: <String, dynamic>{'issueKey': 'PROJ-123', 'transition': 'Done'},
      confidence: 0.99,
    );

    test(
      'S05-UT-04: with the setting on, even 0.99 asks — and says why',
      () async {
        final RouteOutcome outcome = outcomeOf(
          await routerWith().route(confidentTransition),
        );

        expect(outcome, isA<ConfirmationRequired>());
        // Not `lowConfidence`: telling the user the parse was doubtful when it
        // was 0.99 would be the app blaming them for its own policy.
        expect(
          (outcome as ConfirmationRequired).reason,
          ConfirmationReason.jiraWrite,
        );
        verifyNever(
          () => updateJiraStatus(
            task: any(named: 'task'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    test(
      'S05-UT-04: with the setting off, it executes via the outbox',
      () async {
        final RouteOutcome outcome = outcomeOf(
          await routerWith(
            alwaysConfirmJiraWrites: false,
          ).route(confidentTransition),
        );

        expect(outcome, isA<IntentExecuted>());
        // BR-05: through the Sprint 02 use case into the queue, never straight
        // to the gateway.
        expect((outcome as IntentExecuted).operation, queuedOperation);
        verify(
          () => updateJiraStatus(task: linkedTask, status: 'Done'),
        ).called(1);
      },
    );

    test(
      'S05-UT-04: with the setting off, a low-confidence write still asks',
      () async {
        // Turning the policy off does not turn BR-04 off. The two guards are
        // independent, and only one of them is the user's to disable.
        final RouteOutcome outcome = outcomeOf(
          await routerWith(
            alwaysConfirmJiraWrites: false,
          ).route(confidentTransition.copyWith(confidence: 0.4)),
        );

        expect(
          (outcome as ConfirmationRequired).reason,
          ConfirmationReason.lowConfidence,
        );
      },
    );

    test(
      'S05-UT-04: the rule covers comments too, not just transitions',
      () async {
        const VoiceIntent comment = VoiceIntent(
          type: IntentType.addComment,
          slots: <String, dynamic>{
            'issueKey': 'PROJ-123',
            'comment': 'subiu pra staging',
          },
          confidence: 0.98,
        );

        expect(
          outcomeOf(await routerWith().route(comment)),
          isA<ConfirmationRequired>(),
        );
        expect(
          outcomeOf(
            await routerWith(alwaysConfirmJiraWrites: false).route(comment),
          ),
          isA<IntentExecuted>(),
        );
        verify(
          () => addJiraComment(task: linkedTask, body: 'subiu pra staging'),
        ).called(1);
      },
    );

    test(
      'S05-UT-04: a local task at high confidence is unaffected by the rule',
      () async {
        // The setting is about Jira, and a local task is the user's own row.
        final RouteOutcome outcome = outcomeOf(
          await routerWith().route(
            const VoiceIntent(
              type: IntentType.createTask,
              slots: <String, dynamic>{'title': 'limpar as branches antigas'},
              confidence: 0.95,
            ),
          ),
        );

        expect(outcome, isA<IntentExecuted>());
      },
    );

    test('S05-UT-04: queryStatus reads without confirmation', () async {
      final RouteOutcome outcome = outcomeOf(
        await routerWith().route(
          const VoiceIntent(
            type: IntentType.queryStatus,
            slots: <String, dynamic>{'issueKey': 'PROJ-123'},
            confidence: 0.9,
          ),
        ),
      );

      expect((outcome as IntentExecuted).status, 'In Progress');
      verify(() => refreshJiraStatus(linkedTask)).called(1);
    });
  });

  group('S05-UT-05: a missing slot is asked for on its own', () {
    const VoiceIntent withoutIssueKey = VoiceIntent(
      type: IntentType.updateJira,
      slots: <String, dynamic>{'transition': 'Done'},
      confidence: 0.9,
    );

    test('S05-UT-05: the missing slot is named, and nothing runs', () async {
      final RouteOutcome outcome = outcomeOf(
        await routerWith().route(withoutIssueKey),
      );

      expect(outcome, isA<SlotMissing>());
      expect((outcome as SlotMissing).slot, 'issueKey');
      verifyNever(
        () => updateJiraStatus(
          task: any(named: 'task'),
          status: any(named: 'status'),
        ),
      );
    });

    test(
      'S05-UT-05: the slot that is present is not asked about again',
      () async {
        final SlotMissing outcome =
            outcomeOf(await routerWith().route(withoutIssueKey)) as SlotMissing;

        expect(outcome.intent.slots['transition'], 'Done');
        expect(outcome.intent.missingSlots, <String>['issueKey']);
      },
    );

    test(
      'S05-UT-05: supplying the slot completes the intent and it executes',
      () async {
        final VoiceIntent completed = withoutIssueKey.copyWith(
          slots: <String, dynamic>{
            ...withoutIssueKey.slots,
            'issueKey': 'PROJ-123',
          },
        );

        final RouteOutcome outcome = outcomeOf(
          await routerWith(alwaysConfirmJiraWrites: false).route(completed),
        );

        expect(outcome, isA<IntentExecuted>());
        verify(
          () => updateJiraStatus(task: linkedTask, status: 'Done'),
        ).called(1);
      },
    );

    test(
      'S05-UT-05: a blank slot counts as missing, not as an answer',
      () async {
        // A model that answered `{"issueKey": ""}` has not identified a
        // ticket, and sending an empty key to Jira is worse than asking.
        final RouteOutcome outcome = outcomeOf(
          await routerWith().route(
            withoutIssueKey.copyWith(
              slots: <String, dynamic>{'transition': 'Done', 'issueKey': '  '},
            ),
          ),
        );

        expect((outcome as SlotMissing).slot, 'issueKey');
      },
    );

    test('S05-UT-05: a missing slot outranks confirmation — the question comes '
        'first', () async {
      // Asking "are you sure?" about an incomplete action would be asking
      // the user to confirm something the app cannot describe.
      final RouteOutcome outcome = outcomeOf(
        await routerWith().route(withoutIssueKey.copyWith(confidence: 0.2)),
      );

      expect(outcome, isA<SlotMissing>());
    });

    test('S05-UT-05: confirming does not supply a missing slot', () async {
      expect(
        outcomeOf(await routerWith().route(withoutIssueKey, confirmed: true)),
        isA<SlotMissing>(),
      );
    });

    test('S05-UT-05: each intent asks for its own slots', () async {
      final Map<VoiceIntent, String> expected = <VoiceIntent, String>{
        const VoiceIntent(type: IntentType.addComment, confidence: 0.9):
            'issueKey',
        const VoiceIntent(type: IntentType.createTask, confidence: 0.9):
            'title',
        const VoiceIntent(
          type: IntentType.createReminder,
          slots: <String, dynamic>{'text': 'responder o e-mail'},
          confidence: 0.9,
        ): 'triggerAt',
        const VoiceIntent(type: IntentType.queryStatus, confidence: 0.9):
            'issueKey',
      };

      for (final MapEntry<VoiceIntent, String> entry in expected.entries) {
        final RouteOutcome outcome = outcomeOf(
          await routerWith().route(entry.key),
        );
        expect((outcome as SlotMissing).slot, entry.value);
      }
    });
  });

  group('the unknown intent goes nowhere', () {
    test('an unknown intent runs nothing, confirmed or not', () async {
      for (final bool confirmed in <bool>[false, true]) {
        expect(
          outcomeOf(
            await routerWith().route(
              const VoiceIntent(type: IntentType.unknown),
              confirmed: confirmed,
            ),
          ),
          isA<IntentNotUnderstood>(),
        );
      }

      verifyNever(
        () => createTask(
          title: any(named: 'title'),
          priority: any(named: 'priority'),
          dueDate: any(named: 'dueDate'),
        ),
      );
      verifyNever(
        () => updateJiraStatus(
          task: any(named: 'task'),
          status: any(named: 'status'),
        ),
      );
      verifyNever(() => refreshJiraStatus(any()));
    });
  });

  group('an issue nobody linked', () {
    test(
      'a Jira intent for an unlinked key is a failure, not a guess',
      () async {
        when(() => tasks.listAll()).thenAnswer((_) async => <Task>[]);

        final Result<RouteOutcome> result =
            await routerWith(alwaysConfirmJiraWrites: false).route(
              const VoiceIntent(
                type: IntentType.updateJira,
                slots: <String, dynamic>{
                  'issueKey': 'PROJ-999',
                  'transition': 'Done',
                },
                confidence: 0.99,
              ),
            );

        expect(result.failureOrNull, isA<NotLinkedFailure>());
        expect(result.failureOrNull!.message, contains('PROJ-999'));
      },
    );

    test('the key matches case-insensitively', () async {
      // The key came out of a transcript. Refusing `Proj-123` on
      // capitalisation would be the app being pedantic about its own input.
      final RouteOutcome outcome = outcomeOf(
        await routerWith(alwaysConfirmJiraWrites: false).route(
          const VoiceIntent(
            type: IntentType.updateJira,
            slots: <String, dynamic>{
              'issueKey': 'proj-123',
              'transition': 'Done',
            },
            confidence: 0.99,
          ),
        ),
      );

      expect(outcome, isA<IntentExecuted>());
    });
  });

  group('a failing use case surfaces as a failure', () {
    test('a storage failure reaches the caller untouched', () async {
      when(
        () => createTask(
          title: any(named: 'title'),
          priority: any(named: 'priority'),
          dueDate: any(named: 'dueDate'),
        ),
      ).thenAnswer(
        (_) async => const Err<Task>(StorageFailure('the disk is full')),
      );

      final Result<RouteOutcome> result = await routerWith().route(
        const VoiceIntent(
          type: IntentType.createTask,
          slots: <String, dynamic>{'title': 'algo'},
          confidence: 0.9,
        ),
      );

      expect(result.failureOrNull, isA<StorageFailure>());
    });
  });
}
