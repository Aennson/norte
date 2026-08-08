import 'package:flutter/material.dart';

import '../theme/norte_colors.dart';
import '../theme/norte_spacing.dart';

/// A single placeholder bar.
///
/// Flat `surfaceRaised` fill — the design system forbids decorative motion, so
/// there is no shimmer sweeping across it (`docs/design-system.md` §1.5).
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({required this.width, super.key, this.height = 12});

  /// `double.infinity` stretches the bar to the available width.
  final double width;

  final double height;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(NorteSpacing.xs),
      ),
    );
  }
}

/// The loading state of a list screen (`docs/design-system.md` §6): a few card
/// outlines rather than a full-screen spinner, so the layout does not jump
/// when the content arrives.
class LoadingSkeletonList extends StatelessWidget {
  const LoadingSkeletonList({
    required this.semanticLabel,
    super.key,
    this.itemCount = 3,
  });

  /// Localized label announced by screen readers while the list loads (BR-11).
  final String semanticLabel;

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final NorteColors colors = NorteColors.of(context);

    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: ListView.separated(
        // Nothing here reacts to input; scrolling a placeholder is noise.
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: NorteSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          return Container(
            padding: const EdgeInsets.all(NorteSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(NorteSpacing.radius),
              border: Border.all(
                color: colors.border,
                width: NorteSpacing.borderWidth,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonBar(width: 72, height: 10),
                SizedBox(height: NorteSpacing.md),
                SkeletonBar(width: double.infinity),
                SizedBox(height: NorteSpacing.sm),
                SkeletonBar(width: 160),
              ],
            ),
          );
        },
      ),
    );
  }
}
