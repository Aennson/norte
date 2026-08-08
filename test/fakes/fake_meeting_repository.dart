import 'dart:async';

import 'package:norte/domain/entities/meeting.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/meeting_repository.dart';

/// In-memory [MeetingRepository] that records every write
/// (`docs/testing-strategy.md` §3).
///
/// **The spy is the point.** BR-03 is a statement about what reaches storage,
/// so the assertions that matter are about [saved]: what was written, and what
/// was in it. A repository that merely worked would prove nothing.
class FakeMeetingRepository implements MeetingRepository {
  FakeMeetingRepository([List<Meeting> initial = const <Meeting>[]]) {
    for (final Meeting meeting in initial) {
      _meetings[meeting.id] = meeting;
    }
  }

  final Map<String, Meeting> _meetings = <String, Meeting>{};
  final StreamController<List<Meeting>> _changes =
      StreamController<List<Meeting>>.broadcast();

  /// Every meeting handed to [save], in order and exactly as it arrived.
  final List<Meeting> saved = <Meeting>[];

  /// Ids passed to [delete], in order.
  final List<String> deleted = <String>[];

  /// When set, every operation throws it.
  Failure? failWith;

  List<Meeting> get _sorted =>
      _meetings.values.toList()
        ..sort((Meeting a, Meeting b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Meeting>> watchAll() async* {
    yield _sorted;
    yield* _changes.stream;
  }

  @override
  Future<List<Meeting>> listAll() async {
    _guard();
    return _sorted;
  }

  @override
  Future<Meeting?> findById(String id) async {
    _guard();
    return _meetings[id];
  }

  @override
  Future<void> save(Meeting meeting) async {
    _guard();
    saved.add(meeting);
    _meetings[meeting.id] = meeting;
    _changes.add(_sorted);
  }

  @override
  Future<void> delete(String id) async {
    _guard();
    deleted.add(id);
    _meetings.remove(id);
    _changes.add(_sorted);
  }

  /// Releases the change stream.
  Future<void> dispose() => _changes.close();

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }
}
