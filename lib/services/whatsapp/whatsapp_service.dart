import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../models/order_model.dart';

/// Genera enlaces WhatsApp con mensajes estructurados.
class WhatsappService {
  const WhatsappService();

  /// Abre el chat con el número oficial de la tienda.
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

  /// Abre WhatsApp con el cliente, con un mensaje según el nuevo estado.
  Future<bool> contactCustomerAboutStatus({
    required Order order,
    required OrderStatus newStatus,
  }) async {
    final normalized = PhoneValidator.toWhatsappFormat(order.phone);
    if (normalized.isEmpty) return false;

    final message = buildStatusMessage(order, newStatus);
    if (message.isEmpty) return false;

    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Abre WhatsApp con un mensaje libre hacia un número.
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

  /// Construye el mensaje con los datos completos del pedido.
  /// Se usa cuando el cliente envía el comprobante.
  String buildOrderMessage({
    required Order order,
    String? couponCode,
    int? subtotal,
    int? discount,
  }) {
    final buffer = StringBuffer()
      ..writeln('🛍️ *NUEVO PEDIDO - TIENDA VERTEX*')
      ..writeln()
      ..writeln('📦 Pedido: #${order.shortId}')
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
      ..writeln('────────────────')
      ..writeln('Adjunto el comprobante de pago.');

    return buffer.toString();
  }

  /// Construye el mensaje que se envía al cliente cuando cambia el estado.
  String buildStatusMessage(Order order, OrderStatus newStatus) {
    final name = order.customerName.split(' ').first;
    final id = order.shortId;

    switch (newStatus) {
      case OrderStatus.pagado:
        return 'Hola $name 👋\n\n'
            '✅ Confirmamos la recepción de tu pago del pedido #$id '
            'por ${CurrencyFormatter.format(order.total)}.\n\n'
            'Ya estamos procesando tu compra. Te avisaremos cuando '
            'esté en camino.\n\n'
            'Gracias por confiar en Tienda Vertex.';

      case OrderStatus.comprandoProveedor:
        return 'Hola $name 👋\n\n'
            '📦 Estamos adquiriendo tu producto en el proveedor.\n\n'
            'Pedido: #$id\n'
            'Te avisaremos apenas lo tengamos listo para despachar.';

      case OrderStatus.listoDespacho:
        return 'Hola $name 👋\n\n'
            '✅ Tu pedido #$id ya está listo y empacado.\n\n'
            'Lo despachamos en las próximas horas. Te enviamos el '
            'número de guía cuando lo tengamos.';

      case OrderStatus.despachado:
        return 'Hola $name 👋\n\n'
            '🚚 Tu pedido #$id ya fue despachado.\n\n'
            'Llega en 1 a 2 días hábiles. Te contactamos cuando '
            'esté en la zona de entrega.';

      case OrderStatus.entregado:
        return 'Hola $name 👋\n\n'
            '🎉 Tu pedido #$id fue entregado.\n\n'
            '¡Gracias por tu compra! Si tenés algún comentario o '
            'problema, respondé este mensaje.';

      case OrderStatus.cancelado:
        return 'Hola $name 👋\n\n'
            'Tu pedido #$id fue cancelado.\n\n'
            'Si realizaste un pago, procesaremos el reembolso en '
            'las próximas 48 horas hábiles.';

      case OrderStatus.pendientePago:
        return '';
    }
  }
}