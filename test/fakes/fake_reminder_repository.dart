import 'dart:async';

import 'package:norte/domain/entities/reminder.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/ports/reminder_repository.dart';

/// In-memory [ReminderRepository] for the unit tests
/// (`docs/testing-strategy.md` §3).
///
/// **It drops `sourceAudioNote` exactly as the Drift adapter does**, so a test
/// asserting BR-06 against this fake is asserting the same guarantee the app
/// gives. A lenient fake here would let a caller that leaked the audio note
/// pass every unit test and fail only in production, which is the one place
/// nobody is watching for it.
class FakeReminderRepository implements ReminderRepository {
  FakeReminderRepository([List<Reminder> initial = const <Reminder>[]])
    : _mode = _Mode.data {
    for (final Reminder reminder in initial) {
      reminders[reminder.id] = reminder;
    }
  }

  /// Every read fails — drives the screen's error state.
  FakeReminderRepository.failing() : _mode = _Mode.failing;

  /// Never emits — drives the screen's loading state.
  FakeReminderRepository.pending() : _mode = _Mode.pending;

  final _Mode _mode;

  /// Every reminder stored, keyed by id.
  final Map<String, Reminder> reminders = <String, Reminder>{};

  final StreamController<List<Reminder>> _controller =
      StreamController<List<Reminder>>.broadcast();

  /// Number of times [save] has been called, including replacements.
  int saves = 0;

  /// When set, every call throws it.
  Failure? failWith;

  /// The reminders stored, in insertion order.
  List<Reminder> get all => List<Reminder>.unmodifiable(reminders.values);

  @override
  Stream<List<Reminder>> watchAll() {
    switch (_mode) {
      case _Mode.pending:
        // Never emits and never closes — the screen stays in its loading
        // state for as long as the test needs it to.
        return _controller.stream;
      case _Mode.failing:
        return Stream<List<Reminder>>.error(
          const StorageFailure('fake repository failure'),
        );
      case _Mode.data:
        scheduleMicrotask(_emit);
        return _controller.stream;
    }
  }

  @override
  Future<List<Reminder>> listAll() async {
    _guard();
    return all;
  }

  @override
  Future<Reminder?> findById(String id) async {
    _guard();
    return reminders[id];
  }

  @override
  Future<void> save(Reminder reminder) async {
    _guard();
    saves++;
    // The audio note never lands, here or in Drift (BR-06).
    reminders[reminder.id] = reminder.copyWith(sourceAudioNote: null);
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _guard();
    reminders.remove(id);
    _emit();
  }

  /// Releases the broadcast controller.
  Future<void> dispose() => _controller.close();

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(all);
  }

  void _guard() {
    final Failure? failure = failWith;
    if (failure != null) throw failure;
  }
}

/// Which of the three list states this fake is standing in for.
enum _Mode { data, failing, pending }
