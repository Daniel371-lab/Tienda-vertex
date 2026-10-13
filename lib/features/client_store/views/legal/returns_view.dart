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
          LegalTitle(text: 'Políticas de devolución'),
          LegalParagraph(
            text:
                'Queremos que tu experiencia de compra sea satisfactoria. Si '
                'por algún motivo no estás conforme con tu producto, te '
                'explicamos cómo proceder.',
          ),
          LegalSection(text: 'Plazo para solicitar un cambio'),
          LegalParagraph(
            text:
                'Tenés hasta 7 días corridos desde la recepción del pedido '
                'para solicitar un cambio o devolución.',
          ),
          LegalSection(text: 'Condiciones'),
          LegalBullet(
            text: 'El producto debe estar sin uso y en perfecto estado.',
          ),
          LegalBullet(
            text: 'Debe conservar su empaque original, etiquetas y accesorios.',
          ),
          LegalBullet(
            text: 'Tenés que presentar el comprobante de compra.',
          ),
          LegalSection(text: 'Casos no cubiertos'),
          LegalBullet(
            text: 'Productos dañados por mal uso o negligencia.',
          ),
          LegalBullet(
            text: 'Productos personalizados o hechos a medida.',
          ),
          LegalBullet(
            text: 'Productos que hayan sido abiertos o usados.',
          ),
          LegalBullet(
            text: 'Daños causados durante el transporte por parte del courier.',
          ),
          LegalSection(text: 'Producto dañado o incorrecto'),
          LegalParagraph(
            text:
                'Si recibiste un producto dañado o distinto al que pediste, '
                'contactanos por WhatsApp dentro de las 48 horas siguientes '
                'a la entrega. Te vamos a dar una solución inmediata.',
          ),
          LegalSection(text: 'Cómo iniciar una devolución'),
          LegalParagraph(
            text:
                'Escribinos por WhatsApp indicando el número de pedido y el '
                'motivo. Te vamos a guiar en el proceso y coordinar el retiro '
                'o el envío del producto.',
          ),
          LegalSection(text: 'Reembolsos'),
          LegalParagraph(
            text:
                'Una vez recibido y verificado el producto, procesamos el '
                'reembolso en un plazo de hasta 5 días hábiles. El reembolso '
                'se realiza por el mismo medio de pago que utilizaste.',
          ),
        ],
      ),
    );
  }
}