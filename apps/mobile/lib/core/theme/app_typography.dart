import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final base = GoogleFonts.notoSansKrTextTheme();
    final color = brightness == Brightness.light ? AppColors.onSurface : Colors.white;
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 18, height: 1.5, color: color),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 16, height: 1.5, color: color),
      bodySmall: base.bodySmall?.copyWith(fontSize: 14, color: color.withValues(alpha: 0.75)),
      labelLarge: base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: color),
    );
  }
}
