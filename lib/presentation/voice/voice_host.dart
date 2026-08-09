import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/voice/intent_router.dart';
import '../../domain/entities/voice_intent.dart';
import '../../l10n/generated/app_localizations.dart';
import '../app/norte_shell.dart';
import 'voice_labels.dart';
import 'voice_providers.dart';
import 'widgets/confirm_sheet.dart';
import 'widgets/voice_overlay.dart';

/// Puts the voice pipeline on screen (`docs/architecture.md` §6.1).
///
/// It owns the one decision the widget layer has left to make: **which panel
/// is showing**. A pending confirmation outranks everything, because it is the
/// only state in which a mutation is one tap away and the user has to be able
/// to see what they are about to do; below it come the question, the outcome,
/// and the plain transcript.
///
/// The session itself lives in `voiceSessionProvider`, outside the tree, so a
/// command survives the user switching tabs mid-sentence.
class VoiceHost extends ConsumerWidget {
  const VoiceHost({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final VoiceSessionState session = ref.watch(voiceSessionProvider);
    final VoiceSession controller = ref.read(voiceSessionProvider.notifier);

    return NorteShell(
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      onVoicePressed: controller.start,
      voicePanel: session.isActive
          ? _panelFor(context, l10n, session, controller)
          : null,
      child: child,
    );
  }

  Widget _panelFor(
    BuildContext context,
    AppLocalizations l10n,
    VoiceSessionState session,
    VoiceSession controller,
  ) {
    final ConfirmationRequired? confirming = session.confirming;
    if (confirming != null) {
      final VoiceIntent intent = confirming.intent;
      return ConfirmSheet(
        title: l10n.voiceConfirmTitle,
        action: intentDescription(l10n, intent, task: confirming.task),
        reason: confirmationReasonText(l10n, confirming.reason),
        confidence: intent.confidence,
        confidenceLabel: l10n.voiceConfidenceLabel(
          (intent.confidence * 100).round(),
        ),
        confirmLabel: l10n.actionConfirm,
        cancelLabel: l10n.actionCancel,
        onConfirm: controller.confirm,
        onCancel: controller.cancel,
      );
    }

    return VoiceOverlay(
      phase: session.phase,
      statusLabel: switch (session.phase) {
        // "Reconnecting" rather than "Connecting" once audio has been heard:
        // the user knows the session was working a moment ago, and telling
        // them it is starting up would be the app pretending nothing happened.
        VoicePhase.connecting =>
          session.hasHeardAudio ? l10n.voiceReconnecting : l10n.voiceConnecting,
        VoicePhase.listening => l10n.voiceListening,
        VoicePhase.understanding ||
        VoicePhase.asking => l10n.voiceUnderstanding,
        // Not "Understanding…". A failed session is not doing any work, and
        // saying it is was the app describing something that had stopped.
        VoicePhase.failed => l10n.voiceFailed,
      },
      stopLabel: l10n.voiceStop,
      meterLabel: l10n.voiceMeterLabel,
      level: session.level,
      onStop: controller.stop,
      partial: session.partial,
      committed: session.committed,
      message: _messageFor(l10n, session),
    );
  }

  /// The line under the transcript: a question, an outcome, or a failure.
  ///
  /// Order matters here too. A failure wins over an outcome because a command
  /// that failed after being understood must not read as one that worked.
  String? _messageFor(AppLocalizations l10n, VoiceSessionState session) {
    final failure = session.failure;
    if (failure != null) {
      return voiceFailureText(
        l10n,
        failure,
        issueKey: session.intent?.slotText('issueKey'),
      );
    }
    if (session.notUnderstood) return l10n.voiceNotUnderstood;
    final asking = session.askingFor;
    if (asking != null) return slotQuestion(l10n, asking.slot);
    // Both of these outrank an outcome for the same reason a failure does: an
    // earlier command's "Task created" showing under a question the app is
    // asking right now would read as the answer to it.
    final choosing = session.choosing;
    if (choosing != null) return taskAmbiguousText(l10n, choosing);
    final notFound = session.notFound;
    if (notFound != null) return taskNotFoundText(l10n, notFound);
    final executed = session.executed;
    if (executed != null) return executedText(l10n, executed);

    // Connected, listening, and nothing coming in. Said plainly, because
    // silence from a microphone and silence from a service look identical on
    // screen and send the user to completely different places.
    if (session.phase == VoicePhase.listening && !session.hasHeardAudio) {
      return l10n.voiceNoAudio;
    }
    return null;
  }
}
