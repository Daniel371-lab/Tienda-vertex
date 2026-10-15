import 'package:flutter/material.dart';

import 'legal_content.dart';

class ShippingTermsView extends StatelessWidget {
  const ShippingTermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Términos de envío',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegalTitle(text: 'Términos de envío'),
          LegalParagraph(
            text:
                'Acá encontrás toda la información sobre el envío de tu '
                'pedido: cobertura, costos, tiempos y modalidades de entrega.',
          ),

          // ── Cobertura ───────────────────────────────────────
          LegalSection(text: 'Zonas de cobertura'),
          LegalParagraph(
            text:
                'Realizamos envíos a la mayoría de las ciudades del Paraguay. '
                'En el checkout vas a ver las localidades disponibles. Si tu '
                'ciudad no aparece en la lista, escribinos por WhatsApp y '
                'coordinamos el retiro en el punto más cercano a tu ubicación.',
          ),

          // ── Costos ──────────────────────────────────────────
          LegalSection(text: 'Costos de envío'),
          LegalBullet(text: 'Gran Asunción: ₲ 20.000.'),
          LegalBullet(text: 'Cordillera y Paraguarí: ₲ 30.000.'),
          LegalBullet(text: 'Resto del interior: ₲ 35.000.'),
          LegalBullet(text: 'Envío gratis en compras desde ₲ 500.000.'),

          // ── Mínimo ──────────────────────────────────────────
          LegalSection(text: 'Mínimo de compra'),
          LegalParagraph(
            text:
                'Para envíos fuera de Asunción y Central, el pedido mínimo es '
                'de ₲ 300.000. Esto nos permite mantener las tarifas de envío '
                'bajas para todos nuestros clientes.',
          ),

          // ── Tiempos ─────────────────────────────────────────
          LegalSection(text: 'Tiempos de entrega'),
          LegalParagraph(
            text:
                'Los tiempos estimados se cuentan desde que confirmamos el '
                'pago de tu pedido:',
          ),
          LegalBullet(text: 'Gran Asunción: 3 a 5 días hábiles.'),
          LegalBullet(text: 'Interior del país: 4 a 7 días hábiles.'),
          LegalParagraph(
            text:
                'Los plazos pueden extenderse por feriados, condiciones '
                'climáticas o causas ajenas a nosotros.',
          ),

          // ── Seguimiento ─────────────────────────────────────
          LegalSection(text: 'Seguimiento'),
          LegalParagraph(
            text:
                'Una vez despachado tu pedido, te enviamos los datos de '
                'seguimiento por WhatsApp para que puedas estar al tanto de '
                'la entrega en todo momento.',
          ),
        ],
      ),
    );
  }
}