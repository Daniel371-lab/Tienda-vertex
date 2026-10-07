import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../models/order_model.dart';

/// Genera enlaces WhatsApp con mensajes estructurados.
class WhatsappService {
  const WhatsappService();

  /// Abre el chat con el número oficial de la tienda, precargando
  /// el mensaje con todos los datos del pedido.
  Future<bool> sendOrderToStore({
    required Order order,
    required String storeWhatsappNumber,
    String? couponCode,
    int? subtotal,
    int? discount,
  }) async {
    final normalized = PhoneValidator.toWhatsappFormat(storeWhatsappNumber);
    if (normalized.isEmpty) return false;

    final message = buildOrderMessage(
      order: order,
      couponCode: couponCode,
      subtotal: subtotal,
      discount: discount,
    );

    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Abre WhatsApp para contactar directamente a un cliente
  /// (uso desde el cPanel).
  Future<bool> contactCustomer(String phone, {String? message}) async {
    final normalized = PhoneValidator.toWhatsappFormat(phone);
    if (normalized.isEmpty) return false;

    final uri = Uri.parse(
      'https://wa.me/$normalized'
      '${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}',
    );

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Abre WhatsApp con un número específico y mensaje libre.
  Future<bool> openChat({
    required String phone,
    required String message,
  }) async {
    final normalized = PhoneValidator.toWhatsappFormat(phone);
    if (normalized.isEmpty) return false;

    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Construye el mensaje estructurado del pedido.
  String buildOrderMessage({
    required Order order,
    String? couponCode,
    int? subtotal,
    int? discount,
  }) {
    final buffer = StringBuffer()
      ..writeln('🛍️ *NUEVO PEDIDO - TIENDA VERTEX*')
      ..writeln()
      ..writeln('📦 Pedido: #${order.id.toUpperCase()}')
      ..writeln('👤 Cliente: ${order.customerName}')
      ..writeln('📱 Teléfono: ${PhoneValidator.formatForDisplay(order.phone)}')
      ..writeln('📍 Entrega: ${order.city}, ${order.department}')
      ..writeln('🏠 Dirección: ${order.address}')
      ..writeln()
      ..writeln('─────────────')
      ..writeln('*ÍTEMS:*');

    for (var i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      buffer.writeln(
        '${i + 1}. ${item.title}\n'
        '   ${item.quantity} × ${CurrencyFormatter.format(item.price)} = '
        '${CurrencyFormatter.format(item.lineTotal)}',
      );
    }

    buffer
      ..writeln()
      ..writeln('─────────────');

    final sub = subtotal ?? order.subtotal;
    final disc = discount ?? order.discount;

    if (sub > 0) {
      buffer.writeln('Subtotal:  ${CurrencyFormatter.format(sub)}');
    }
    if (disc > 0 && couponCode != null) {
      buffer.writeln(
        'Descuento: -${CurrencyFormatter.format(disc)} ($couponCode)',
      );
    }
    buffer
      ..writeln('*TOTAL:    ${CurrencyFormatter.format(order.total)}*')
      ..writeln()
      ..writeln('💳 Pago: Contra entrega')
      ..writeln('────────────────')
      ..writeln('Por favor confirmá el pedido respondiendo este mensaje.');

    return buffer.toString();
  }
}