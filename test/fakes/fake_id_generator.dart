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
