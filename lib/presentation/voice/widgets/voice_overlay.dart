import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../../shared/widgets/norte_button.dart';
import 'audio_meter.dart';

/// What the voice session is doing, as far as the user is concerned.
enum VoicePhase {
  /// Opening the realtime session.
  connecting,

  /// The microphone is live.
  listening,

  /// Speech is committed and the parser is working.
  understanding,

  /// A question is on screen — a missing slot, or a refusal to guess.
  asking,
}

/// The terminal-style panel that shows what the app is hearing
/// (`docs/design-system.md` §4).
///
/// **Partial in `mono` `textSecondary`, committed in `textPrimary`** — the one
/// visual distinction the design system asks for here, and it carries real
/// meaning: grey text is the app's current guess and will change, solid text
/// is what it has settled on and will act upon. A user watching the grey
/// settle into solid knows exactly when the sentence was heard.
///
/// The `❯` prefix in `accent` is the terminal prompt the whole aesthetic is
/// built on (§1.1).
///
/// **The meter is the honest part.** Before it, this panel said "Listening…"
/// from the moment the button was pressed and looked identical whether the
/// microphone was feeding the pipeline, sitting mute, or never opened at all —
/// which is what a user reported, and they were right to. [level] comes from
/// the PCM actually captured, so a flat meter is information: the microphone
/// is open and producing nothing.
class VoiceOverlay extends StatelessWidget {
  const VoiceOverlay({
    required this.phase,
    required this.statusLabel,
    required this.stopLabel,
    required this.onStop,
    required this.meterLabel,
    super.key,
    this.level = 0,
    this.partial,
    this.committed,
    this.message,
  });

  final VoicePhase phase;

  /// Localized phase line — "Listening…", "Understanding…" (BR-11).
  final String statusLabel;

  /// Localized label of the stop button.
  final String stopLabel;

  final VoidCallback onStop;

  /// The provisional transcript; replaced by each new event, never appended.
  final String? partial;

  /// The committed transcript, once VAD closed the segment.
  final String? committed;

  /// A question or a refusal — "Which ticket?", "I did not catch a command."
  final String? message;

  /// Microphone input level, `0.0..1.0`, measured from the captured audio.
  final double level;

  /// Localized description of the meter, for screen readers (BR-11).
  final String meterLabel;

  /// The prompt character of the design system's terminal aesthetic.
  static const String prompt = '❯';

  /// Key the widget and E2E suites drive the stop button by.
  static const Key stopButtonKey = Key('voice.stop');

  @override
  Widget build(BuildContext context) {
    final colors = NorteColors.of(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: statusLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.border,
              width: NorteSpacing.borderWidth,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(NorteSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      switch (phase) {
                        VoicePhase.connecting => LucideIcons.plug,
                        VoicePhase.listening => LucideIcons.mic,
                        VoicePhase.understanding ||
                        VoicePhase.asking => LucideIcons.sparkles,
                      },
                      size: 16,
                      // Connecting is not yet listening, and saying so in the
                      // accent colour would overstate it.
                      color: phase == VoicePhase.connecting
                          ? colors.textMuted
                          : colors.accent,
                    ),
                    const SizedBox(width: NorteSpacing.sm),
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: NorteTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    AudioMeter(
                      level: level,
                      isLive: phase == VoicePhase.listening,
                      semanticLabel: meterLabel,
                    ),
                  ],
                ),
                const SizedBox(height: NorteSpacing.md),
                _TranscriptLine(
                  text: committed ?? partial ?? '',
                  // Solid once committed; grey while it is still a guess.
                  color: committed != null
                      ? colors.textPrimary
                      : colors.textSecondary,
                  promptColor: colors.accent,
                ),
                if (message != null) ...<Widget>[
                  const SizedBox(height: NorteSpacing.md),
                  Text(
                    message!,
                    style: NorteTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: NorteSpacing.lg),
                NorteButton(
                  key: VoiceOverlay.stopButtonKey,
                  label: stopLabel,
                  onPressed: onStop,
                  variant: NorteButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One line of transcript behind the `❯` prompt.
class _TranscriptLine extends StatelessWidget {
  const _TranscriptLine({
    required this.text,
    required this.color,
    required this.promptColor,
  });

  final String text;
  final Color color;
  final Color promptColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          VoiceOverlay.prompt,
          style: NorteTypography.mono.copyWith(color: promptColor),
        ),
        const SizedBox(width: NorteSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: NorteTypography.mono.copyWith(color: color),
            // Three lines is a long spoken command; past that the user is
            // dictating a document, and the overlay is not the place for one.
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
