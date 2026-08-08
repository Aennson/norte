import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/meeting_repository.dart';
import 'package:norte/l10n/generated/app_localizations.dart';
import 'package:norte/presentation/meetings/meeting_providers.dart';
import 'package:norte/presentation/meetings/meetings_screen.dart';
import 'package:norte/presentation/meetings/new_meeting_screen.dart';
import 'package:norte/presentation/meetings/summary_screen.dart';
import 'package:norte/presentation/shared/theme/norte_theme.dart';
import 'package:norte/presentation/tasks/task_providers.dart';

import '../../fakes/fake_ai_engine.dart';
import '../../fakes/fake_clock.dart';
import '../../fakes/fake_id_generator.dart';
import '../../fakes/fake_meeting_repository.dart';
import '../../fakes/fake_meeting_template_repository.dart';
import '../../support/meeting_fixtures.dart';
import '../../support/platform_goldens.dart';
import '../../support/task_fixtures.dart';
import '../../support/test_fonts.dart';

/// A [MeetingRepository] that never emits — the loading state.
class _PendingMeetingRepository implements MeetingRepository {
  @override
  Stream<List<Meeting>> watchAll() => const Stream<List<Meeting>>.empty()
      .asyncExpand((_) => const Stream<List<Meeting>>.empty());
  @override
  Future<List<Meeting>> listAll() async => <Meeting>[];
  @override
  Future<Meeting?> findById(String id) async => null;
  @override
  Future<void> save(Meeting meeting) async {}
  @override
  Future<void> delete(String id) async {}
}

/// S03-GT-01 — the meeting screens in the four mandatory states
/// (`docs/design-system.md` §6), dark and light.
///
/// The state worth pinning is the summary screen. It is the only place in the
/// app that shows a user something the app is about to forget, so the golden
/// holds two things in place: the discard warning, and the fact that a
/// converted action item keeps its row and loses its button. A change that
/// quietly removed either would pass every other test in the suite.
void main() {
  setUpAll(() async {
    usePlatformGoldens();
    await loadNorteFonts();
  });

  const Size desktop = Size(1000, 900);

  final List<(String, ThemeData)> themes = <(String, ThemeData)>[
    ('dark', NorteTheme.dark),
    ('light', NorteTheme.light),
  ];

  final DateTime t0 = DateTime.utc(2026, 8, 8, 9, 30);

  Meeting savedMeeting() => Meeting(
    id: 'meeting-1',
    title: 'Sprint 12 retro',
    type: MeetingType.retro,
    createdAt: t0,
    summary: MeetingSummary(
      sections: const <String, String>{
        'What went well': 'The team shipped the outbox on time.',
        'What to improve': 'Code review latency — two PRs sat for three days.',
        'Action items': 'Two follow-ups were committed to.',
      },
      generatedAt: t0,
      actionItems: const <ActionItem>[
        ActionItem(
          id: 'item-0',
          description: 'Update the runbook',
          assignee: 'Ana',
          convertedTaskId: 'task-1',
        ),
        ActionItem(id: 'item-1', description: 'Set up a review reminder'),
      ],
    ),
  );

  Future<void> pump(
    WidgetTester tester, {
    required ThemeData theme,
    required Widget screen,
    required List<Override> overrides,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(desktop);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          clockProvider.overrideWithValue(FakeClock(t0)),
          idGeneratorProvider.overrideWithValue(FakeIdGenerator.fixed('id-1')),
          taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
          ...overrides,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: screen),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  for (final (String name, ThemeData theme) in themes) {
    testWidgets('S03-GT-01: meetings screen — empty ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme: theme,
        screen: const MeetingsScreen(),
        overrides: <Override>[
          meetingRepositoryProvider.overrideWithValue(FakeMeetingRepository()),
        ],
      );

      await expectLater(
        find.byType(MeetingsScreen),
        matchesGoldenFile('images/meetings_empty_$name.png'),
      );
    });

    testWidgets('S03-GT-01: meetings screen — content ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme: theme,
        screen: const MeetingsScreen(),
        overrides: <Override>[
          meetingRepositoryProvider.overrideWithValue(
            FakeMeetingRepository(<Meeting>[savedMeeting()]),
          ),
        ],
      );

      await expectLater(
        find.byType(MeetingsScreen),
        matchesGoldenFile('images/meetings_content_$name.png'),
      );
    });

    testWidgets('S03-GT-01: meetings screen — loading ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme: theme,
        screen: const MeetingsScreen(),
        overrides: <Override>[
          meetingRepositoryProvider.overrideWithValue(
            _PendingMeetingRepository(),
          ),
        ],
        settle: false,
      );

      await expectLater(
        find.byType(MeetingsScreen),
        matchesGoldenFile('images/meetings_loading_$name.png'),
      );
    });

    testWidgets('S03-GT-01: meetings screen — error ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme: theme,
        screen: const MeetingsScreen(),
        overrides: <Override>[
          meetingRepositoryProvider.overrideWithValue(
            FakeMeetingRepository()..failWith = const StorageFailure('boom'),
          ),
        ],
      );

      await expectLater(
        find.byType(MeetingsScreen),
        matchesGoldenFile('images/meetings_error_$name.png'),
      );
    });

    testWidgets('S03-GT-01: new meeting screen ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme: theme,
        screen: const NewMeetingScreen(),
        overrides: <Override>[
          meetingTemplateRepositoryProvider.overrideWithValue(
            FakeMeetingTemplateRepository.seeded(),
          ),
          meetingRepositoryProvider.overrideWithValue(FakeMeetingRepository()),
          aiEngineProvider.overrideWithValue(FakeAiEngine()),
        ],
      );

      await expectLater(
        find.byType(NewMeetingScreen),
        matchesGoldenFile('images/new_meeting_$name.png'),
      );
    });

    testWidgets('S03-GT-01: summary screen — sections and items ($name)', (
      WidgetTester tester,
    ) async {
      // Driven through the real composer, so the golden shows what a user
      // actually reaches after processing rather than a hand-built widget.
      final FakeAiEngine engine = FakeAiEngine(generatedAt: t0)
        ..alwaysAnswer(summaryFixture('retro.json'));
      late ProviderContainer container;

      await pump(
        tester,
        theme: theme,
        screen: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            container = ProviderScope.containerOf(context);
            return const SummaryScreen();
          },
        ),
        overrides: <Override>[
          meetingTemplateRepositoryProvider.overrideWithValue(
            FakeMeetingTemplateRepository.seeded(),
          ),
          meetingRepositoryProvider.overrideWithValue(FakeMeetingRepository()),
          aiEngineProvider.overrideWithValue(engine),
        ],
      );

      final MeetingComposer composer = container.read(
        meetingComposerProvider.notifier,
      )..selectTemplate(retroTemplate);
      await composer.summarize(
        transcript: retroTranscript,
        title: 'Sprint 12 retro',
      );
      // One item converted, one not — the state the golden exists to pin.
      await composer.convert('item-0');
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SummaryScreen),
        matchesGoldenFile('images/summary_screen_$name.png'),
      );
    });

    testWidgets('S03-GT-01: summary screen — nothing to show ($name)', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        theme: theme,
        screen: const SummaryScreen(),
        overrides: <Override>[
          meetingTemplateRepositoryProvider.overrideWithValue(
            FakeMeetingTemplateRepository.seeded(),
          ),
          meetingRepositoryProvider.overrideWithValue(FakeMeetingRepository()),
          aiEngineProvider.overrideWithValue(FakeAiEngine()),
        ],
      );

      await expectLater(
        find.byType(SummaryScreen),
        matchesGoldenFile('images/summary_empty_$name.png'),
      );
    });
  }
}
