import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formateo de moneda para Guaraníes paraguayos.
/// Ejemplo: 180000 → "₲ 180.000"
abstract final class CurrencyFormatter {
  static final NumberFormat _pyg = NumberFormat.decimalPattern('es_PY');

  /// Formatea un entero de guaraníes al estilo oficial: ₲ 180.000
  /// El guaraní no usa decimales.
  static String format(int amount, {String symbol = '₲'}) {
    final formatted = _pyg.format(amount);
    return '$symbol $formatted';
  }

  /// Variante sin símbolo, útil para inputs de edición.
  static String formatNumber(int amount) => _pyg.format(amount);

  /// Parsea un texto tipo "180.000" → 180000.
  static int parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// Formateador para TextField que agrega separadores en vivo.
  static final TextInputFormatterWithGroup separatorFormatter =
      TextInputFormatterWithGroup();
}

/// Formatter para TextField: agrupa dígitos con separador de miles.
class TextInputFormatterWithGroup extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    final number = int.tryParse(digits) ?? 0;
    final formatted = CurrencyFormatter.formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}