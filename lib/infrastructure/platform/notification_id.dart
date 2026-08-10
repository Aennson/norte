/// The reminder id, as a 31-bit integer.
///
/// `flutter_local_notifications` keys everything on an `int`, and a
/// [ScheduledNotification] is keyed on a `String`. Something has to map one to
/// the other, and it has to give the same answer **after the app restarts** —
/// a cancel that computes a different number from the same reminder cancels
/// nothing, and the notification fires for something the user deleted last
/// week.
///
/// `String.hashCode` is the obvious candidate and is the wrong one: nothing in
/// the language promises it is stable across processes or SDK versions, and a
/// scheduler that breaks on a Flutter upgrade breaks silently. FNV-1a is
/// twelve lines, is specified outside this repository, and cannot drift.
///
/// Collisions are possible in principle — 31 bits over arbitrary strings — and
/// harmless in practice at the size of one person's reminder list. What a
/// collision would cost is one reminder replacing another's registration,
/// which the launch check repairs on the next start.
library;

/// FNV-1a over the UTF-16 code units of [id], folded into 31 bits.
int notificationIdOf(String id) {
  const int offsetBasis = 0x811c9dc5;
  const int prime = 0x01000193;
  int hash = offsetBasis;
  for (final int unit in id.codeUnits) {
    hash = (hash ^ unit) & 0xffffffff;
    hash = (hash * prime) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
