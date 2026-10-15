import 'package:flutter/material.dart';

import 'legal_content.dart';

class ReturnsView extends StatelessWidget {
  const ReturnsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Políticas de devolución',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegalTitle(text: 'Políticas de devolución y garantía'),
          LegalParagraph(
            text:
                'En Tienda Vertex trabajamos para que cada pedido llegue en '
                'perfectas condiciones. Si algo no salió como esperabas, te '
                'damos una solución rápida y transparente.',
          ),

          LegalSection(text: 'Cuándo aplica una devolución'),
          LegalParagraph(
            text:
                'Aceptamos devoluciones y nos hacemos cargo de los costos de '
                'envío asociados en los siguientes casos:',
          ),
          LegalBullet(
            text:
                'El producto llegó dañado, roto o con una falla de fábrica '
                'comprobable.',
          ),
          LegalBullet(
            text:
                'Recibiste un producto incorrecto distinto al que pediste.',
          ),
          LegalBullet(
            text:
                'El paquete sufrió un extravío total durante el trayecto '
                'a destino.',
          ),
          LegalParagraph(
            text:
                'Frente a cualquiera de estos inconvenientes, podrás elegir '
                'entre el cambio por un producto nuevo o el reembolso '
                'completo de tu dinero.',
          ),

          LegalSection(text: 'Cuándo no aplica'),
          LegalParagraph(
            text: 'No aceptamos devoluciones en los siguientes casos:',
          ),
          LegalBullet(
            text:
                'Cambio de opinión o arrepentimiento una vez realizado o '
                'despachado el pedido.',
          ),
          LegalBullet(
            text:
                'Productos que hayan sido usados o muestren signos de '
                'manipulación.',
          ),
          LegalBullet(
            text:
                'Daños causados por mal uso, golpes o negligencia del cliente.',
          ),
          LegalBullet(
            text: 'Productos personalizados o fabricados a pedido.',
          ),
          LegalBullet(
            text:
                'Pedidos rechazados al momento de la entrega sin '
                'justificación válida.',
          ),

          LegalSection(text: 'Plazo para reclamar'),
          LegalParagraph(
            text:
                'Tenés 48 horas desde que recibís el pedido para reportar '
                'cualquier problema o falla con el producto. Pasado este plazo '
                'de 48 horas, el pedido se considera aceptado en conformidad y '
                'no podremos procesar el reclamo.',
          ),

          LegalSection(text: 'Cómo hacer un reclamo'),
          LegalParagraph(
            text:
                'Escribinos por WhatsApp con tu número de pedido, contanos qué '
                'pasó y adjuntá fotos o videos del producto y del empaque. Te '
                'respondemos a la brevedad para evaluar el caso y coordinar el '
                'proceso.',
          ),

          LegalSection(text: 'Reembolsos'),
          LegalParagraph(
            text:
                'Una vez que recibimos y verificamos el producto devuelto en '
                'nuestro depósito, procesamos el reembolso en un plazo de '
                'hasta 5 días hábiles. El dinero se reintegra a través del '
                'mismo medio de pago utilizado o vía transferencia bancaria.',
          ),

          LegalSection(text: 'Pedidos rechazados o no entregados'),
          LegalParagraph(
            text:
                'Si el pedido es rechazado en puerta al momento de la entrega '
                'sin una causa justificada o el paquete vuelve al depósito por '
                'no poder ubicar al destinatario, se le reintegra al cliente el '
                'monto del producto menos el costo del envío de retorno. El '
                'reembolso se procesa por el mismo medio de pago que utilizó.',
          ),
        ],
      ),
    );
  }
}