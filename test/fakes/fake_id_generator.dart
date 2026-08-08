import 'dart:math';

import 'package:norte/domain/ports/id_generator.dart';

/// Deterministic [IdGenerator] (`docs/testing-strategy.md` §3).
///
/// Wraps the production [UuidV4Generator] around a seeded [Random], so the
/// values are real, well-formed UUID v4 strings — S01-UT-01 asserts the shape —
/// while the sequence repeats identically on every run.
class FakeIdGenerator implements IdGenerator {
  FakeIdGenerator({int seed = 20260101})
    : _delegate = UuidV4Generator(Random(seed));

  /// Always hands out [id], ignoring the sequence. Useful when a test needs to
  /// name the identifier it will look up later.
  FakeIdGenerator.fixed(String id) : _delegate = _FixedId(id);

  /// Hands out [ids] in order, then keeps returning the last one.
  ///
  /// Lets a test that asserts on several operations name each one — an outbox
  /// assertion reads far better against `op-1` than against a UUID.
  FakeIdGenerator.sequence(List<String> ids) : _delegate = _SequencedIds(ids);

  final IdGenerator _delegate;

  /// Every id handed out, in call order.
  final List<String> issued = <String>[];

  @override
  String newId() {
    final String id = _delegate.newId();
    issued.add(id);
    return id;
  }
}

class _FixedId implements IdGenerator {
  const _FixedId(this._id);

  final String _id;

  @override
  String newId() => _id;
}

class _SequencedIds implements IdGenerator {
  _SequencedIds(this._ids) : assert(_ids.isNotEmpty, 'needs at least one id');

  final List<String> _ids;
  int _index = 0;

  @override
  String newId() => _ids[_index < _ids.length ? _index++ : _ids.length - 1];
}
