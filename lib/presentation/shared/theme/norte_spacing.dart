/// Spacing and radius tokens (`docs/design-system.md` §1.5 and §5).
///
/// Everything sits on a 4px grid; corners are 8px; borders are 1px.
abstract final class NorteSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Default screen padding on mobile.
  static const double screenPaddingMobile = 16;

  /// Default screen padding on desktop.
  static const double screenPaddingDesktop = 24;

  /// Corner radius of every surface (cards, fields, buttons).
  static const double radius = 8;

  /// Hairline separators and outlines.
  static const double borderWidth = 1;

  /// Width of the collapsed desktop navigation rail.
  static const double railWidth = 72;

  /// Maximum content column width on desktop.
  static const double contentMaxWidth = 840;

  /// Viewport width at which the layout switches from bottom nav to rail.
  static const double desktopBreakpoint = 900;

  /// Height of a [NorteButton].
  static const double buttonHeight = 40;

  /// Functional animation ceiling — no decorative motion.
  static const Duration motion = Duration(milliseconds: 200);
}
