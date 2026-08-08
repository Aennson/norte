import 'dart:async';

import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/entities/meeting_template.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/meeting_template_repository.dart';

/// In-memory [MeetingTemplateRepository]
/// (`docs/testing-strategy.md` §3).
///
/// [seedDefaults] mirrors the Drift adapter's rule exactly — insert only what
/// is absent — because the widget and E2E suites lean on it and must not be
/// shown a friendlier version of the behaviour than production has.
class FakeMeetingTemplateRepository implements MeetingTemplateRepository {
  FakeMeetingTemplateRepository([
    List<MeetingTemplate> initial = const <MeetingTemplate>[],
  ]) {
    for (final MeetingTemplate template in initial) {
      _templates[template.id] = template;
    }
  }

  /// Pre-loaded with the four built-ins, as a fresh install has them.
  factory FakeMeetingTemplateRepository.seeded() =>
      FakeMeetingTemplateRepository(defaultMeetingTemplates);

  final Map<String, MeetingTemplate> _templates = <String, MeetingTemplate>{};
  final StreamController<List<MeetingTemplate>> _changes =
      StreamController<List<MeetingTemplate>>.broadcast();

  /// How many times [seedDefaults] has run.
  int seedCount = 0;

  /// When set, every operation throws it.
  Failure? failWith;

  List<MeetingTemplate> get _sorted => _templates.values.toList()
    ..sort(
      (MeetingTemplate a, MeetingTemplate b) =>
          a.type.index.compareTo(b.type.index),
    );

  @override
  Future<void> seedDefaults() async {
    _guard();
    seedCount++;
    for (final MeetingTemplate template in defaultMeetingTemplates) {
      _templates.putIfAbsent(template.id, () => template);
    }
    _changes.add(_sorted);
  }

  @override
  Stream<List<MeetingTemplate>> watchAll() async* {
    yield _sorted;
    yield* _changes.stream;
  }

  @override
  Future<List<MeetingTemplate>> listAll() async {
    _guard();
    return _sorted;
  }

  @override
  Future<MeetingTemplate?> findById(String id) async {
    _guard();
    return _templates[id];
  }

  @override
  Future<MeetingTemplate?> findByType(MeetingType type) async {
    _guard();
    for (final MeetingTemplate template in _sorted) {
      if (template.type == type) return template;
    }
    return null;
  }

  @override
  Future<void> save(MeetingTemplate template) async {
    _guard();
    _templates[template.id] = template;
    _changes.add(_sorted);
  }

  @override
  Future<void> delete(String id) async {
    _guard();
    _templates.remove(id);
    _changes.add(_sorted);
  }

  /// Releases the change stream.
  Future<void> dispose() => _changes.close();

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }
}
