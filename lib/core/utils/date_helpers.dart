import 'package:intl/intl.dart';

/// Formateo de fechas para pedidos, dashboard y auditoría.
/// Español paraguayo (es_PY).
abstract final class DateHelpers {
  static final DateFormat _full = DateFormat("d 'de' MMMM 'de' y", 'es_PY');
  static final DateFormat _short = DateFormat('dd/MM/yyyy', 'es_PY');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy · HH:mm', 'es_PY');
  static final DateFormat _timeOnly = DateFormat('HH:mm', 'es_PY');

  static String full(DateTime? date) =>
      date == null ? '—' : _full.format(date);

  static String short(DateTime? date) =>
      date == null ? '—' : _short.format(date);

  static String dateTime(DateTime? date) =>
      date == null ? '—' : _dateTime.format(date);

  static String timeOnly(DateTime? date) =>
      date == null ? '—' : _timeOnly.format(date);

  /// "Hace 5 minutos", "Hoy 14:30", "Ayer 09:15", "dd/MM/yyyy"
  static String relative(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24 && now.day == date.day) {
      return 'Hoy ${timeOnly(date)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Ayer ${timeOnly(date)}';
    }
    return short(date);
  }
}