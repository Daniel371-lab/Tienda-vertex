import 'package:flutter/material.dart';

/// Paleta oficial de Tienda Vertex.
/// Base crema para descanso visual, azul pizarra para texto,
/// azul real para acciones y CTA. Cero blanco puro en fondos.
abstract final class AppColors {
  // ── Base (Light) ─────────────────────────────────────────────
  static const Color scaffold   = Color(0xFFFAF9F6); // Crema Suave
  static const Color surface    = Color(0xFFFFFFFF); // Tarjetas/Modales
  static const Color surfaceAlt = Color(0xFFF4F3EF); // Superficie alterna

  // ── Texto ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E293B); // Azul Pizarra
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Acciones ─────────────────────────────────────────────────
  static const Color primary      = Color(0xFF2563EB); // Azul Real
  static const Color primaryDark  = Color(0xFF1D4ED8);
  static const Color primarySoft  = Color(0xFFE0F2FE); // Celeste Hielo
  static const Color whatsapp     = Color(0xFF25D366);

  // ── Estados ──────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);

  // ── Bordes / Divisiones ──────────────────────────────────────
  static const Color border  = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // ── Dark (reservado para cPanel) ────────────────────────────
  static const Color darkScaffold      = Color(0xFF0F172A);
  static const Color darkSurface       = Color(0xFF1E293B);
  static const Color darkBorder        = Color(0xFF334155);
  static const Color darkTextPrimary   = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  // ── Sombras ──────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}