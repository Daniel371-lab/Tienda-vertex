import 'package:flutter/services.dart';

/// Validación y normalización de teléfonos paraguayos.
///
/// Formato de celulares: 09XX XXX XXX (11 dígitos con el 0 inicial)
/// Formato de fijos:     0XXX XXX XXX (9 dígitos, Asunción)
abstract final class PhoneValidator {
  /// Solo dígitos, sin espacios ni símbolos.
  static String digitsOnly(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '');

  /// Normaliza a formato WhatsApp: 595981123456
  static String toWhatsappFormat(String raw) {
    var digits = digitsOnly(raw);
    if (digits.isEmpty) return '';

    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!digits.startsWith('595')) digits = '595$digits';

    return digits;
  }

  /// Validación estricta para Paraguay.
  static bool isValid(String raw) {
    final normalized = toWhatsappFormat(raw);
    if (normalized.isEmpty || !normalized.startsWith('595')) return false;
    final local = normalized.substring(3);
    return local.length == 8 || local.length == 9;
  }

  /// Formatea para mostrar al usuario.
  /// Celular: 0981 123 456  → 4-3-3
  /// Fijo:    021 123 456   → 3-3-3
  static String formatForDisplay(String raw) {
    var digits = digitsOnly(raw);
    if (digits.isEmpty) return '';

    // Asegurar 0 inicial.
    if (!digits.startsWith('0')) {
      if (digits.startsWith('595')) {
        digits = '0${digits.substring(3)}';
      } else {
        digits = '0$digits';
      }
    }

    // Limitar a 10 dígitos máx (formato local).
    if (digits.length > 10) digits = digits.substring(0, 10);

    // Formato según longitud.
    // Celular (empieza con 09 y 10 dígitos): 0981 123 456 → 4-3-3
    // Fijo Asunción (empieza con 021 y 9 dígitos): 021 123 456 → 3-3-3
    if (digits.startsWith('09') && digits.length >= 3) {
      // Celular: 4-3-3
      if (digits.length <= 4) return digits;
      if (digits.length <= 7) {
        return '${digits.substring(0, 4)} ${digits.substring(4)}';
      }
      return '${digits.substring(0, 4)} '
          '${digits.substring(4, 7)} '
          '${digits.substring(7)}';
    }

    // Fijo: 3-3-3
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} '
        '${digits.substring(3, 6)} '
        '${digits.substring(6)}';
  }

  /// TextInputFormatter listo para usar en TextField.
  static TextInputFormatter get inputFormatter => _PhoneInputFormatter();
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = PhoneValidator.formatForDisplay(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}