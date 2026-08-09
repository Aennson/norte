import 'package:flutter/material.dart';

import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';

/// A row of bars that rises with the microphone's actual input level.
///
/// **It is wired to the audio, not to a clock.** That distinction is the whole
/// point of the widget: an indicator that animates on a timer looks exactly the
/// same whether the microphone is working, muted, or absent, and so tells the
/// user nothing while appearing to reassure them. This one is flat when the
/// room is quiet and moves when someone speaks, which means a flat meter is
/// information rather than a bug.
///
/// The bars are deterministic — each has a fixed share of the level, so the
/// same input always draws the same picture and a golden test can pin it. No
/// randomness, no decorative motion (`docs/design-system.md` §1.5).
class AudioMeter extends StatelessWidget {
  const AudioMeter({
    required this.level,
    required this.semanticLabel,
    super.key,
    this.isLive = true,
  });

  /// Input level, `0.0..1.0`.
  final double level;

  /// `false` greys the meter out — the session is not capturing right now.
  final bool isLive;

  /// Localized description for screen readers (BR-11).
  ///
  /// A meter is the one control a blind user gets nothing from, so the state
  /// it conveys visually has to be said in words as well.
  final String semanticLabel;

  /// How much of the level each bar answers to, low to high.
  ///
  /// Rising thresholds rather than equal ones: quiet speech should move the
  /// first bars visibly, and only a raised voice should fill the last.
  static const List<double> thresholds = <double>[0.04, 0.12, 0.24, 0.40, 0.60];

  static const double _height = 20;
  static const double _barWidth = 3;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);
    final double clamped = level.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: SizedBox(
        height: _height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            for (final double threshold in thresholds) ...<Widget>[
              _Bar(
                // Never fully collapsed: a bar of zero height would read as a
                // missing widget rather than as silence.
                fill: clamped <= threshold
                    ? 0.15
                    : ((clamped - threshold) / (1 - threshold)).clamp(
                        0.15,
                        1.0,
                      ),
                color: !isLive
                    ? colors.textMuted
                    : clamped > threshold
                    ? colors.accent
                    : colors.border,
              ),
              const SizedBox(width: NorteSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AnimatedContainer(
        // Functional, and inside the design system's 200 ms ceiling: it
        // smooths the step between frames rather than inventing movement.
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: AudioMeter._barWidth,
        height: AudioMeter._height * fill,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AudioMeter._barWidth / 2),
        ),
      ),
    );
  }
}
