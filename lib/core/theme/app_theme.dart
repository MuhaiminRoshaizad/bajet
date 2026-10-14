import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static const fontFamily = 'Figtree';

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.ink,
      secondary: c.keep,
      onSecondary: c.card,
      // Tonal buttons fill with secondaryContainer, which would otherwise
      // fall back to the apricot keep colour.
      secondaryContainer: c.primarySoft,
      onSecondaryContainer: c.ink,
      error: c.bad,
      onError: c.card,
      surface: c.background,
      onSurface: c.ink,
      onSurfaceVariant: c.muted,
      surfaceContainerLowest: c.card,
      surfaceContainerLow: c.card,
      surfaceContainer: c.card,
      outline: c.line,
      outlineVariant: c.line,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
    );
    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control));
    OutlineInputBorder field([Color? color, double width = 0]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: color == null ? BorderSide.none : BorderSide(color: color, width: width),
        );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
      dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(backgroundColor: c.background, surfaceTintColor: Colors.transparent, foregroundColor: c.ink, elevation: 0),
      // Inputs sit in a well pressed into the surface; focus and errors draw
      // an outline, since the well alone is too faint to carry a state.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.well,
        contentPadding: const EdgeInsets.all(AppSpacing.l),
        border: field(),
        enabledBorder: field(),
        focusedBorder: field(c.primary, 2),
        errorBorder: field(c.bad, 1.5),
        focusedErrorBorder: field(c.bad, 2),
      ),
      // A button's textStyle replaces the ambient one whole, font family and
      // all, so it is set here once with Figtree rather than at each button.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: controlShape,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: controlShape, side: BorderSide(color: c.muted))),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.well,
          selectedBackgroundColor: c.primary,
          selectedForegroundColor: c.onPrimary,
          foregroundColor: c.ink,
          side: BorderSide.none,
        ),
      ),
      // A clear groove on the soft surface; no tick dots, the value is in words.
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.muted.withValues(alpha: 0.35),
        thumbColor: c.primary,
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      dialogTheme: DialogThemeData(backgroundColor: c.background, surfaceTintColor: Colors.transparent),
      datePickerTheme: DatePickerThemeData(backgroundColor: c.background, surfaceTintColor: Colors.transparent),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: c.background, fontSize: 14),
        actionTextColor: c.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.muted,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
      ),
    );
  }
}
