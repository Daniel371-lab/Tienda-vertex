import 'package:flutter/material.dart';

import 'legal_content.dart';

class FaqView extends StatelessWidget {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Preguntas frecuentes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegalTitle(text: 'Preguntas frecuentes'),
          LegalParagraph(
            text:
                'Acá encontrás las respuestas a las consultas más comunes. '
                'Si tu duda no está en la lista, escribinos por WhatsApp.',
          ),

          // ── PEDIDOS ────────────────────────────────────────
          LegalSection(text: 'Pedidos'),

          FaqItem(
            question: '¿Cómo hago un pedido?',
            answer:
                'Agregá los productos que quieras al carrito, tocá '
                '"Finalizar compra", completá tus datos y confirmá. En '
                'pantalla vas a ver los datos para la transferencia.',
          ),
          FaqItem(
            question: '¿Puedo modificar mi pedido?',
            answer:
                'Sí. Una vez confirmado, tenés hasta 2 horas para escribirnos '
                'por WhatsApp y modificar lo que necesites. Pasado ese plazo, '
                'el pedido ya se procesa con los datos originales.',
          ),
          FaqItem(
            question: '¿Puedo cancelar mi pedido?',
            answer:
                'Sí. Si todavía no lo despachamos, escribinos por WhatsApp '
                'con tu número de pedido y lo cancelamos. Si ya está '
                'despachado, podés solicitar una devolución al recibirlo.',
          ),

          // ── PAGOS ──────────────────────────────────────────
          LegalSection(text: 'Pagos'),

          FaqItem(
            question: '¿Qué medios de pago aceptan?',
            answer:
                'Por el momento aceptamos transferencias bancarias y pagos '
                'con billeteras electrónicas. Próximamente sumaremos otros '
                'medios de pago.',
          ),
          FaqItem(
            question: '¿Cómo confirmo mi pago?',
            answer:
                'Después de transferir, envianos el comprobante por WhatsApp. '
                'Una vez verificada la acreditación en nuestra cuenta, te '
                'avisamos y empezamos a procesar tu pedido.',
          ),
          FaqItem(
            question: '¿Puede transferir otra persona en mi nombre?',
            answer:
                'Sí, sin problema. Solo asegurate de que el comprobante '
                'incluya el número de tu pedido para que podamos '
                'identificarlo.',
          ),

          // ── ENVÍOS ─────────────────────────────────────────
          LegalSection(text: 'Envíos'),

          FaqItem(
            question: '¿Hacen envíos a todo el país?',
            answer:
                'Sí, enviamos a la mayoría de las ciudades del Paraguay. En '
                'el checkout vas a ver las localidades disponibles. Si tu '
                'ciudad no aparece, escribinos por WhatsApp y vemos cómo '
                'hacerlo llegar.',
          ),
          FaqItem(
            question: '¿Cuánto cuesta el envío?',
            answer:
                'Gran Asunción: ₲ 20.000. Cordillera y Paraguarí: ₲ 30.000. '
                'Resto del interior: ₲ 35.000.',
          ),
          FaqItem(
            question: '¿Hay envío gratis?',
            answer:
                'Sí, en compras desde ₲ 500.000 el envío es gratuito a todo '
                'el país.',
          ),
          FaqItem(
            question: '¿Hay un monto mínimo de compra?',
            answer:
                'Para envíos fuera de Asunción y Central, el pedido mínimo es '
                'de ₲ 300.000. En Gran Asunción no hay mínimo.',
          ),
          FaqItem(
            question: '¿Cuánto tarda en llegar mi pedido?',
            answer:
                'Gran Asunción: 3 a 5 días hábiles. Interior del país: 4 a 7 '
                'días hábiles. Los plazos se cuentan desde la confirmación '
                'del pago.',
          ),
          FaqItem(
            question: '¿Cómo sé que mi pedido fue enviado?',
            answer:
                'Cuando despachamos tu pedido, te avisamos por WhatsApp con '
                'los datos de seguimiento.',
          ),
          FaqItem(
            question: '¿Qué pasa si no estoy cuando llega el envío?',
            answer:
                'El envío se intenta entregar en el domicilio. Si no hay '
                'nadie, se deja un aviso para coordinar una nueva visita o '
                'el retiro en la sucursal más cercana.',
          ),

          // ── PRODUCTOS ──────────────────────────────────────
          LegalSection(text: 'Productos'),

          FaqItem(
            question: '¿Los productos tienen garantía?',
            answer:
                'Todos nuestros productos cuentan con garantía por fallas de '
                'fábrica. Tenés 48 horas desde la recepción del pedido para '
                'reportar cualquier problema.',
          ),

          // ── DEVOLUCIONES ───────────────────────────────────
          LegalSection(text: 'Devoluciones'),

          FaqItem(
            question: '¿Puedo devolver un producto?',
            answer:
                'Aceptamos devoluciones únicamente en caso de producto dañado, '
                'producto incorrecto o extravío durante el envío. No aceptamos '
                'devoluciones por cambio de opinión. Para más detalle, mirá '
                'nuestra Política de devoluciones.',
          ),
          FaqItem(
            question: '¿Qué hago si mi producto llega dañado?',
            answer:
                'Escribinos por WhatsApp dentro de las 48 horas posteriores a '
                'la recepción, adjuntando fotos o videos del producto y del '
                'empaque. Te damos una solución inmediata.',
          ),
          FaqItem(
            question: '¿Qué pasa si rechazo el pedido al momento de la entrega?',
            answer:
                'Si rechazás el pedido sin una causa justificada, se te '
                'reintegra el monto del producto menos el costo del envío de '
                'retorno. El reembolso se procesa por el mismo medio de pago '
                'que utilizaste.',
          ),
        ],
      ),
    );
  }
}