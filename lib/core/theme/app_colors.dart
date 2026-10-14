import 'package:flutter/material.dart';

/// A soft tint used behind an icon, named by colour so the theme stays
/// unaware of which feature uses it.
enum Tint { apricot, sky, sage, teal, rose, pink, olive, neutral }

/// The Ocean palette on a soft (neumorphic) base: one blue-grey surface that
/// cards and controls share, lit from the top left. Blue 245° marks actions
/// and selection; its complement, apricot 65°, marks money kept. Tints share
/// one OKLCH lightness so no category outshouts another, and every text
/// pairing clears WCAG AA on both the surface and the darker well.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.well,
    required this.highlight,
    required this.shade,
    required this.onBad,
    required this.ink,
    required this.muted,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.keepSurface,
    required this.keep,
    required this.goodSurface,
    required this.good,
    required this.badSurface,
    required this.bad,
    required this.tintFills,
    required this.tintInks,
  });

  final Color background;
  final Color card;

  /// A sunken area pressed into the surface: inputs, tracks, notices.
  final Color well;

  /// The lit edge and the shadowed edge of a raised or pressed surface.
  final Color highlight;
  final Color shade;
  final Color onBad;
  final Color ink;
  final Color muted;
  final Color line;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;

  /// Money kept: the goal card, buffer line and savings figures.
  final Color keepSurface;
  final Color keep;
  final Color goodSurface;
  final Color good;
  final Color badSurface;
  final Color bad;

  final Map<Tint, Color> tintFills;
  final Map<Tint, Color> tintInks;

  Color tintFill(Tint tint) => tintFills[tint]!;
  Color tintInk(Tint tint) => tintInks[tint]!;

  static const light = AppColors(
    background: Color(0xFFE3E9EF),
    card: Color(0xFFE3E9EF),
    well: Color(0xFFD7DFE7),
    highlight: Color(0xE6FFFFFF),
    shade: Color(0x99A3B1C0),
    onBad: Color(0xFFFFFFFF),
    ink: Color(0xFF1E2830),
    muted: Color(0xFF545E68),
    line: Color(0xFFD0D9E2),
    primary: Color(0xFF0C5F96),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFD4ECFD),
    keepSurface: Color(0xFFFDDFC2),
    keep: Color(0xFF88491A),
    goodSurface: Color(0xFFD0EED5),
    good: Color(0xFF2E643B),
    badSurface: Color(0xFFFFDFDE),
    bad: Color(0xFFA8383C),
    tintFills: {
      Tint.apricot: Color(0xFFFADFC6),
      Tint.sky: Color(0xFFCBE9FF),
      Tint.sage: Color(0xFFD0EED5),
      Tint.teal: Color(0xFFC3EFEB),
      Tint.rose: Color(0xFFFFD9D8),
      Tint.pink: Color(0xFFFCD9EB),
      Tint.olive: Color(0xFFEBE6C4),
      Tint.neutral: Color(0xFFE2E7EB),
    },
    tintInks: {
      Tint.apricot: Color(0xFF8A5619),
      Tint.sky: Color(0xFF1F6A96),
      Tint.sage: Color(0xFF337344),
      Tint.teal: Color(0xFF007570),
      Tint.rose: Color(0xFF944A4B),
      Tint.pink: Color(0xFF8B4A70),
      Tint.olive: Color(0xFF71640B),
      Tint.neutral: Color(0xFF606A74),
    },
  );

  /// Dark slate rather than black, so the shadowed edge still has somewhere
  /// darker to go, and off-white text to avoid the halation of pure white on
  /// black (Material's dark theme guidance).
  static const dark = AppColors(
    background: Color(0xFF1D2329),
    card: Color(0xFF1D2329),
    well: Color(0xFF161B20),
    highlight: Color(0x1FFFFFFF),
    shade: Color(0xB3080A0C),
    onBad: Color(0xFF2A0D0E),
    ink: Color(0xFFE3E9EE),
    muted: Color(0xFFA3ACB4),
    line: Color(0xFF2B333B),
    primary: Color(0xFF79C0F1),
    onPrimary: Color(0xFF031C30),
    primarySoft: Color(0xFF193043),
    keepSurface: Color(0xFF2D2217),
    keep: Color(0xFFEFC093),
    goodSurface: Color(0xFF1F3724),
    good: Color(0xFF9DD8A9),
    badSurface: Color(0xFF4B2727),
    bad: Color(0xFFF8A4A3),
    tintFills: {
      Tint.apricot: Color(0xFF473018),
      Tint.sky: Color(0xFF1B394C),
      Tint.sage: Color(0xFF223D27),
      Tint.teal: Color(0xFF0D3D3B),
      Tint.rose: Color(0xFF4C2B2B),
      Tint.pink: Color(0xFF482B3B),
      Tint.olive: Color(0xFF3B3615),
      Tint.neutral: Color(0xFF292F34),
    },
    tintInks: {
      Tint.apricot: Color(0xFFEFC093),
      Tint.sky: Color(0xFF9BD2FA),
      Tint.sage: Color(0xFFA6DAAF),
      Tint.teal: Color(0xFF8BDCD6),
      Tint.rose: Color(0xFFFBB6B5),
      Tint.pink: Color(0xFFF1B6D6),
      Tint.olive: Color(0xFFD6CC8F),
      Tint.neutral: Color(0xFF9DA6AE),
    },
  );

  @override
  AppColors copyWith() => this;

  // Two fixed palettes; animating between them is not something bajet does.
  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
