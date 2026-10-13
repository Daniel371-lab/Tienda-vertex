import 'package:flutter/material.dart';

import 'legal_content.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Sobre nosotros',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegalTitle(text: 'Sobre nosotros'),
          LegalParagraph(
            text:
                'Tienda Vertex es una tienda online paraguaya dedicada a ofrecer '
                'productos seleccionados de distintas categorías, con envíos a '
                'todo el país y atención personalizada.',
          ),
          LegalSection(text: 'Nuestra propuesta'),
          LegalParagraph(
            text:
                'Trabajamos con proveedores de confianza para ofrecer productos '
                'de calidad a precios competitivos. Cada producto pasa por una '
                'selección cuidadosa antes de formar parte de nuestro catálogo.',
          ),
          LegalBullet(text: 'Envíos a todo Paraguay.'),
          LegalBullet(text: 'Atención personalizada por WhatsApp.'),
          LegalBullet(
            text: 'Seguimiento de cada pedido hasta la entrega.',
          ),
          LegalSection(text: 'Nuestro compromiso'),
          LegalParagraph(
            text:
                'Buscamos que comprar en Tienda Vertex sea simple, seguro y '
                'transparente. Si tenés alguna duda antes, durante o después de '
                'tu compra, podés contactarnos por WhatsApp y te vamos a responder '
                'a la brevedad.',
          ),
        ],
      ),
    );
  }
}