import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/app/norte_app.dart';

/// Composition root.
///
/// The only place allowed to wire `infrastructure/` adapters into the
/// providers the rest of the app consumes (`docs/project-rules.md` §3).
/// Sprint 00 has no adapters yet — the scope is the empty [ProviderScope].
void main() {
  runApp(const ProviderScope(child: NorteApp()));
}
