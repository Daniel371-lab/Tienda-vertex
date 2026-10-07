import 'package:flutter/services.dart';

/// Validación y normalización de teléfonos paraguayos.
///
/// Formatos aceptados:
///   · 0981 123 456   (celular local con 0)
///   · 981 123 456    (celular sin 0)
///   · +595 981 123 456
///   · 595981123456   (formato canónico para WhatsApp)
abstract final class PhoneValidator {
  /// Solo dígitos, sin espacios ni símbolos.
  static String digitsOnly(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '');

  /// Normaliza a formato WhatsApp: 595981123456
  /// Retorna string vacío si no se puede normalizar.
  static String toWhatsappFormat(String raw) {
    var digits = digitsOnly(raw);
    if (digits.isEmpty) return '';

    // Quitar 0 inicial (formato local paraguayo)
    if (digits.startsWith('0')) digits = digits.substring(1);

    // Si no empieza con 595, agregarlo
    if (!digits.startsWith('595')) digits = '595$digits';

    return digits;
  }

  /// Validación estricta para Paraguay.
  /// Celulares: 9 dígitos tras el 595 (ej: 981 123 456).
  /// Fijos Asunción: 8 dígitos tras el 595 (ej: 21 123 456).
  static bool isValid(String raw) {
    final normalized = toWhatsappFormat(raw);
    if (normalized.isEmpty || !normalized.startsWith('595')) return false;
    final local = normalized.substring(3);
    return local.length == 8 || local.length == 9;
  }

  /// Formatea para mostrar al usuario: 0981 123 456
  static String formatForDisplay(String raw) {
    var digits = digitsOnly(raw);
    if (digits.isEmpty) return '';

    // Asegurar que empiece con 0 (formato local)
    if (!digits.startsWith('0')) {
      if (digits.startsWith('595')) {
        digits = '0${digits.substring(3)}';
      } else {
        digits = '0$digits';
      }
    }

    // Agrupar: 0XXX XXX XXX
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
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