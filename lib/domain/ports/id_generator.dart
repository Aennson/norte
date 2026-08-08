import 'dart:math';

/// Source of new entity identifiers.
///
/// Identifiers are generated in the **use case**, never in the entity or in
/// the repository (`sprint-01` validation rules), so a test can pin them the
/// same way it pins the clock.
///
/// **Contract**
/// * [newId] never returns the same value twice and never throws.
/// * The value is a canonical lowercase UUID v4 string,
///   `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` with `y` in `8..b`.
abstract interface class IdGenerator {
  /// A fresh identifier.
  String newId();
}

/// The production [IdGenerator]: RFC 4122 version 4 UUIDs from
/// [Random.secure].
///
/// Hand-rolled rather than pulled from a package — the algorithm is 16 random
/// bytes with six bits pinned, and the stack in `docs/architecture.md` §2.1
/// names no UUID dependency.
final class UuidV4Generator implements IdGenerator {
  UuidV4Generator([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  static const String _hex = '0123456789abcdef';

  @override
  String newId() {
    final List<int> bytes = List<int>.generate(
      16,
      (_) => _random.nextInt(256),
      growable: false,
    );
    // Version 4 in the high nibble of byte 6, variant 10xx in byte 8.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) buffer.write('-');
      buffer
        ..write(_hex[bytes[i] >> 4])
        ..write(_hex[bytes[i] & 0x0f]);
    }
    return buffer.toString();
  }
}
