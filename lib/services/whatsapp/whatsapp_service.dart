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
  ///
  /// Los textos son desde la perspectiva del cliente:
  /// la tienda es el vendedor y no se mencionan proveedores,
  /// transportadoras específicas ni números de guía.
  String buildStatusMessage(Order order, OrderStatus newStatus) {
    final name = order.customerName.split(' ').first;
    final id = order.shortId;

    switch (newStatus) {
      case OrderStatus.pagado:
        return 'Hola $name 👋\n\n'
            '✅ Confirmamos la recepción de tu pago del pedido #$id '
            'por ${CurrencyFormatter.format(order.total)}.\n\n'
            'Estamos preparando tu compra. Te avisamos cuando esté en camino.\n\n'
            'Gracias por confiar en Tienda Vertex.';

      case OrderStatus.comprandoProveedor:
        // Este estado es interno. Al cliente se le comunica como
        // "preparando tu pedido" sin más detalle.
        return 'Hola $name 👋\n\n'
            '📦 Estamos preparando tu pedido #$id.\n\n'
            'Te avisamos en cuanto esté listo para el envío.';

      case OrderStatus.listoDespacho:
        return 'Hola $name 👋\n\n'
            '✅ Tu pedido #$id ya está listo y empacado.\n\n'
            'En las próximas horas lo enviamos a tu dirección. '
            'Te avisamos cuando salga.';

      case OrderStatus.despachado:
        return 'Hola $name 👋\n\n'
            '🚚 Tu pedido #$id ya está en camino.\n\n'
            'En breve lo recibís en ${order.city}. Si necesitamos '
            'contactarte para coordinar la entrega, lo haremos por este medio.\n\n'
            'Gracias por tu paciencia.';

      case OrderStatus.entregado:
        return 'Hola $name 👋\n\n'
            '🎉 Tu pedido #$id fue entregado.\n\n'
            '¡Gracias por tu compra! Si tenés algún comentario, duda o '
            'problema, respondé este mensaje.';

      case OrderStatus.cancelado:
        return 'Hola $name 👋\n\n'
            'Tu pedido #$id fue cancelado.\n\n'
            'Si ya realizaste un pago, procesaremos el reembolso en '
            'las próximas 48 horas hábiles.\n\n'
            'Cualquier consulta, quedamos a disposición.';

      case OrderStatus.pendientePago:
        // Este mensaje no se envía nunca al cliente desde este flujo.
        return '';
    }
  }
}