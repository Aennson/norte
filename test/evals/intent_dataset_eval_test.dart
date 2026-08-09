import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:norte/application/usecases/add_jira_comment.dart';
import 'package:norte/application/usecases/comment_task.dart';
import 'package:norte/application/usecases/create_reminder.dart';
import 'package:norte/application/usecases/create_task.dart';
import 'package:norte/application/usecases/delete_task.dart';
import 'package:norte/application/usecases/refresh_jira_status.dart';
import 'package:norte/application/usecases/update_jira_status.dart';
import 'package:norte/application/usecases/update_task.dart';
import 'package:norte/application/voice/intent_parser.dart';
import 'package:norte/application/voice/intent_router.dart';
import 'package:norte/domain/entities/intent_context.dart';
import 'package:norte/domain/entities/task.dart';
import 'package:norte/domain/entities/voice_intent.dart';
import 'package:norte/domain/entities/voice_settings.dart';
import 'package:norte/domain/failures/result.dart';

import '../fakes/fakes.dart';
import '../support/task_fixtures.dart';

final DateTime _t0 = DateTime.utc(2026, 8, 9, 10);

/// The list a `taskRef` from the dataset is resolved against.
///
/// The decoys are the point. `HEROBRAZIL-763` is one digit from `-762` and
/// scores above `similarityThreshold` against a reference for either, so a
/// ladder that ranked instead of excluding would have to ask; "Ligar para
/// Samara de novo" is the containment trap tier 1 exists for.
const List<(String, String)> _plausibleTitles = <(String, String)>[
  ('t-762', 'HEROBRAZIL-762'),
  ('t-763', 'HEROBRAZIL-763'),
  ('t-samara', 'Ligar para Samara'),
  ('t-samara-2', 'Ligar para Samara de novo'),
  ('t-demo', 'Preparar a demo'),
];

/// The real router over [tasks], with the real use cases behind it.
///
/// The eval asserts which row a spoken reference reached, and a spy has no
/// rows to reach.
IntentRouter _routerOver(FakeTaskRepository tasks) {
  final FakeClock clock = FakeClock(_t0);
  final FakeIdGenerator ids = FakeIdGenerator();
  final FakeOutboxRepository outbox = FakeOutboxRepository();
  return IntentRouter(
    tasks: tasks,
    createTask: CreateTask(repository: tasks, clock: clock, idGenerator: ids),
    updateTask: UpdateTask(repository: tasks, clock: clock),
    deleteTask: DeleteTask(repository: tasks),
    commentTask: CommentTask(repository: tasks, clock: clock, idGenerator: ids),
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

/// One utterance with its ground truth and the raw answer the fake replays.
class _Row {
  const _Row({
    required this.id,
    required this.utterance,
    required this.expectedIntent,
    required this.expectedSlots,
    required this.response,
    this.resolvesTo,
  });

  factory _Row.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> expected =
        json['expected']! as Map<String, Object?>;
    return _Row(
      id: json['id']! as String,
      utterance: json['utterance']! as String,
      expectedIntent: IntentType.fromWire(expected['intent']),
      expectedSlots: <String, Object?>{
        ...(expected['slots']! as Map<String, Object?>),
      },
      response: json['response']! as String,
      resolvesTo: json['resolvesTo'] as String?,
    );
  }

  final String id;
  final String utterance;
  final IntentType expectedIntent;
  final Map<String, Object?> expectedSlots;
  final String response;

  /// The title this row's `taskRef` must reach through the ladder of §6.3.1,
  /// when the two are spelled differently (Sprint 05b). `null` on every row
  /// whose reference is spelled the way the title is.
  final String? resolvesTo;

  bool get isAmbiguous => expectedIntent == IntentType.unknown;
}

/// What one dataset scored.
class _Score {
  _Score(this.locale);

  final String locale;
  int rows = 0;
  int intentHits = 0;
  int slotHits = 0;
  int ambiguous = 0;
  int ambiguousHits = 0;
  final List<String> errors = <String>[];

  double get intentAccuracy => rows == 0 ? 0 : intentHits / rows;
  double get slotAccuracy => rows == 0 ? 0 : slotHits / rows;

  String get summary =>
      '$locale: $rows utterances · '
      'intent ${(intentAccuracy * 100).toStringAsFixed(1)}% '
      '($intentHits/$rows) · '
      'slots ${(slotAccuracy * 100).toStringAsFixed(1)}% ($slotHits/$rows) · '
      'ambiguous $ambiguousHits/$ambiguous';
}

/// S05-EV-01 — multilingual intent dataset eval (architecture §13, strategy
/// §5).
///
/// **What it actually measures.** The fixtures are raw model answers replayed
/// through `FakeAiEngine`, which parses them with the production `IntentCodec`.
/// So this is a regression eval over the *parsing pipeline* — the schema
/// validation, the fenced/prose tolerance, the slot normalisation, and above
/// all the refusal to turn an unreadable answer into an action. It is not a
/// measurement of the model, which would need the network and could not run in
/// CI (`docs/project-rules.md` §5.4).
///
/// The datasets carry answers a real model plausibly gets wrong, so the
/// thresholds bite: PT-BR currently scores 96.2% on intent and 88.5% on exact
/// slots, against 90% and 85%. A regression in the codec moves both below the
/// line rather than leaving a permanent 100%.
///
/// **The ambiguous rows are the hard gate.** Every utterance whose ground truth
/// is `unknown` must come out `unknown` — 100%, not 90%. An ambiguous sentence
/// that becomes an action is the failure mode the whole confirmation design
/// exists to prevent, and one is one too many.
void main() {
  const Map<String, String> datasets = <String, String>{
    'pt-BR': 'test/fixtures/intents/ptbr_dataset.json',
    'en': 'test/fixtures/intents/en_dataset.json',
    'it': 'test/fixtures/intents/it_dataset.json',
  };

  /// Exit criteria from the sprint.
  const double minIntentAccuracy = 0.90;
  const double minSlotAccuracy = 0.85;

  /// Where the per-utterance error report is written for the CI artifact.
  const String reportPath = 'build/eval/s05_ev_01_report.md';

  final List<_Score> scores = <_Score>[];

  List<_Row> load(String path) {
    final Object? decoded = jsonDecode(File(path).readAsStringSync());
    final List<Object?> rows =
        (decoded! as Map<String, Object?>)['rows']! as List<Object?>;
    return <_Row>[
      for (final Object? row in rows)
        _Row.fromJson(row! as Map<String, Object?>),
    ];
  }

  /// Exact-set comparison: every expected slot present with the expected
  /// value, and no extra ones.
  bool slotsMatch(Map<String, Object?> expected, Map<String, dynamic> actual) {
    if (expected.length != actual.length) return false;
    for (final MapEntry<String, Object?> entry in expected.entries) {
      if (actual[entry.key] != entry.value) return false;
    }
    return true;
  }

  tearDownAll(() {
    // The artifact the sprint asks for. Written even on a pass, because the
    // interesting question after a green run is *which* six it got wrong.
    final StringBuffer report = StringBuffer()
      ..writeln('# S05-EV-01 — intent dataset eval')
      ..writeln()
      ..writeln('Thresholds: intent ≥ 90%, exact slots ≥ 85%, ambiguous 100%.')
      ..writeln();
    for (final _Score score in scores) {
      report
        ..writeln('## ${score.locale}')
        ..writeln()
        ..writeln(score.summary)
        ..writeln();
      if (score.errors.isEmpty) {
        report.writeln('No errors.');
      } else {
        for (final String error in score.errors) {
          report.writeln('- $error');
        }
      }
      report.writeln();
    }
    File(reportPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(report.toString());
  });

  for (final MapEntry<String, String> dataset in datasets.entries) {
    final String locale = dataset.key;

    group('S05-EV-01: $locale', () {
      late List<_Row> rows;
      late _Score score;

      setUpAll(() async {
        rows = load(dataset.value);
        score = _Score(locale);
        scores.add(score);

        for (final _Row row in rows) {
          final IntentParser parser = IntentParser(
            engine: FakeAiEngine(
              intents: <String, String>{row.utterance: row.response},
            ),
          );
          final Result<VoiceIntent> result = await parser.parse(
            row.utterance,
            context: IntentContext(locale: locale),
          );
          final VoiceIntent intent =
              result.valueOrNull ?? const VoiceIntent(type: IntentType.unknown);

          score.rows++;
          final bool intentOk = intent.type == row.expectedIntent;
          final bool slotsOk =
              intentOk && slotsMatch(row.expectedSlots, intent.slots);
          if (intentOk) score.intentHits++;
          if (slotsOk) score.slotHits++;
          if (row.isAmbiguous) {
            score.ambiguous++;
            if (intentOk) score.ambiguousHits++;
          }

          if (!intentOk) {
            score.errors.add(
              '`${row.id}` "${row.utterance}" — expected '
              '`${row.expectedIntent.name}`, got `${intent.type.name}`',
            );
          } else if (!slotsOk) {
            score.errors.add(
              '`${row.id}` "${row.utterance}" — intent right, slots '
              '`${intent.slots}` ≠ `${row.expectedSlots}`',
            );
          }
        }
      });

      test('S05-EV-01: the dataset meets its documented size', () {
        // 50 for the target language, 10 for a smoke set. A dataset that
        // shrank would make the percentages easier to hit for the wrong
        // reason.
        expect(rows.length, greaterThanOrEqualTo(locale == 'pt-BR' ? 50 : 10));
        if (locale == 'pt-BR') {
          expect(
            rows.where((_Row r) => r.isAmbiguous).length,
            greaterThanOrEqualTo(10),
          );
        }
      });

      test('S05-EV-01: intent accuracy ≥ 90%', () {
        expect(
          score.intentAccuracy,
          greaterThanOrEqualTo(minIntentAccuracy),
          reason: '${score.summary}\n${score.errors.join('\n')}',
        );
      });

      test('S05-EV-01: exact slots ≥ 85%', () {
        expect(
          score.slotAccuracy,
          greaterThanOrEqualTo(minSlotAccuracy),
          reason: '${score.summary}\n${score.errors.join('\n')}',
        );
      });

      test('S05-EV-01: every ambiguous utterance stays unknown', () {
        // The hard gate. Not a percentage — a count.
        expect(
          score.ambiguousHits,
          score.ambiguous,
          reason:
              'an ambiguous utterance became an action:\n'
              '${score.errors.join('\n')}',
        );
      });

      test('S05a-UT-07: no local utterance produces a Jira intent', () async {
        // **Jira is opt-in by naming** (`sprint-05a` validation rules). An
        // utterance that mentions neither an issue key nor Jira may not become
        // a transition, a Jira comment or a status lookup — a wrong local task
        // is a row the user deletes, a wrong Jira write is a change their
        // whole team saw.
        //
        // The rule is checked against what the *codec* produced, not against
        // the ground truth: a dataset can only be wrong about itself, and the
        // failure this guards is the pipeline turning a local sentence into a
        // remote action.
        final RegExp issueKey = RegExp(r'\b[A-Z]{2,}-\d+\b');
        const Set<IntentType> jira = <IntentType>{
          IntentType.updateJira,
          IntentType.addComment,
          IntentType.queryStatus,
        };

        for (final _Row row in rows) {
          final bool namesJira =
              issueKey.hasMatch(row.utterance) ||
              row.utterance.toLowerCase().contains('jira');
          if (namesJira) continue;

          final Result<VoiceIntent> result = await IntentParser(
            engine: FakeAiEngine(
              intents: <String, String>{row.utterance: row.response},
            ),
          ).parse(row.utterance, context: IntentContext(locale: locale));
          final VoiceIntent intent =
              result.valueOrNull ?? const VoiceIntent(type: IntentType.unknown);

          expect(
            jira,
            isNot(contains(intent.type)),
            reason:
                '`${row.id}` "${row.utterance}" names no issue key and no '
                'Jira, but produced `${intent.type.name}`',
          );
        }
      });

      test('S05a-UT-07: the local intents are represented at all', () {
        // A rule about local utterances is vacuous if the dataset has none.
        // Every one of the four is exercised, in every language.
        for (final IntentType type in <IntentType>[
          IntentType.createTask,
          IntentType.updateTask,
          IntentType.deleteTask,
          IntentType.commentTask,
        ]) {
          expect(
            rows.where((_Row r) => r.expectedIntent == type),
            isNotEmpty,
            reason: '$locale carries no ${type.name} row',
          );
        }
      });

      test('S05b-EV-01: a taskRef spelled differently still finds its '
          'row', () async {
        // The Definition of Done of Sprint 05b: at least three rows whose
        // `taskRef` is spelled differently from any plausible title, routed
        // through the real ladder against a list that includes the decoys the
        // thresholds exist to keep apart — `HEROBRAZIL-763` one digit away,
        // and a second "Ligar para…" close enough to score.
        //
        // Only pt-BR carries them: the defect was found in pt-BR, and the
        // reference is spelled by whoever is speaking, not by the parser.
        final List<_Row> spelled = rows
            .where((_Row row) => row.resolvesTo != null)
            .toList();
        if (locale != 'pt-BR') {
          expect(spelled, isEmpty);
          return;
        }
        expect(spelled.length, greaterThanOrEqualTo(3));

        for (final _Row row in spelled) {
          final FakeTaskRepository tasks = FakeTaskRepository();
          addTearDown(tasks.dispose);
          for (final (String id, String title) in _plausibleTitles) {
            await tasks.save(
              Task(
                id: id,
                title: title,
                createdAt: _t0,
                updatedAt: _t0,
                status: TaskStatus.todo,
              ),
            );
          }

          final Result<VoiceIntent> parsed = await IntentParser(
            engine: FakeAiEngine(
              intents: <String, String>{row.utterance: row.response},
            ),
          ).parse(row.utterance, context: IntentContext(locale: locale));
          final VoiceIntent intent = parsed.valueOrNull!;

          final Result<RouteOutcome> routed = await _routerOver(
            tasks,
          ).route(intent);
          final RouteOutcome outcome = routed.valueOrNull!;

          // A deletion stops at the confirmation sheet however it resolved
          // (BR-04's floor), so the row it named is on the sheet rather than
          // in an executed outcome. Both must name the same title.
          final String? named = switch (outcome) {
            IntentExecuted(:final Task? task, :final String? deletedTitle) =>
              task?.title ?? deletedTitle,
            ConfirmationRequired(:final Task? task) => task?.title,
            _ => null,
          };
          expect(
            named,
            row.resolvesTo,
            reason:
                '`${row.id}` "${row.utterance}" — `${row.expectedSlots['taskRef']}` '
                'reached `$named`, not `${row.resolvesTo}` '
                '(outcome ${outcome.runtimeType})',
          );
        }
      });

      test('S05-EV-01: no unknown-labelled row carries slots', () async {
        // Belt and braces on the same guarantee: even if a row were
        // misclassified, `unknown` must be empty of anything the router could
        // act on.
        for (final _Row row in rows.where((_Row r) => r.isAmbiguous)) {
          final Result<VoiceIntent> result = await IntentParser(
            engine: FakeAiEngine(
              intents: <String, String>{row.utterance: row.response},
            ),
          ).parse(row.utterance);
          expect(result.valueOrNull!.slots, isEmpty, reason: row.id);
        }
      });
    });
  }
}
