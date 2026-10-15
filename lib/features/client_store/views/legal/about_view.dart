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
                'Tienda Vertex es una tienda online paraguaya dedicada a '
                'ofrecer productos de primera calidad, con envíos a todo el '
                'país y atención personalizada.',
          ),
          LegalParagraph(
            text:
                'Somos una tienda de paraguayos para paraguayos, así que '
                'ofrecemos precios competitivos. Cada producto pasa por una '
                'selección cuidadosa antes de formar parte de nuestro catálogo.',
          ),
          LegalBullet(text: 'Envíos a todo el país.'),
          LegalBullet(text: 'Atención personalizada por WhatsApp.'),
          LegalBullet(text: 'Envíos con seguimiento.'),
          LegalSection(text: 'Nuestro compromiso'),
          LegalParagraph(
            text:
                'Buscamos que comprar en Tienda Vertex sea simple, seguro y '
                'transparente. Si tenés alguna duda antes, durante o después de '
                'tu compra, podés contactarnos por WhatsApp y te vamos a '
                'responder a la brevedad.',
          ),
        ],
      ),
    );
  }
}