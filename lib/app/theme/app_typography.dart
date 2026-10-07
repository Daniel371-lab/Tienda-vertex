import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jerarquía tipográfica oficial:
///   · Títulos → Plus Jakarta Sans (w700 / w600)
///   · Cuerpo, precios y formularios → Inter (w400 / w500)
abstract final class AppTypography {
  static TextTheme get textTheme => TextTheme(
        // ── Encabezados (Plus Jakarta Sans) ──────────────────────
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 40, fontWeight: FontWeight.w700, height: 1.15,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700, height: 1.2,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w700, height: 1.2,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, height: 1.25,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w600, height: 1.3,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, height: 1.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, height: 1.35,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
        ),

        // ── Cuerpo y Precios (Inter) ─────────────────────────────
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, height: 1.45,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3,
        ),
      );
}