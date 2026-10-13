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

          FaqItem(
            question: '¿Cómo hago un pedido?',
            answer:
                'Agregá los productos que quieras al carrito, tocá "Finalizar '
                'compra", completá tus datos y confirmá el pedido. Vas a ver '
                'los datos de transferencia en pantalla.',
          ),
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
                'Después de transferir, podés enviarnos el comprobante por '
                'WhatsApp o esperar a que verifiquemos la acreditación en '
                'nuestra cuenta. Te avisamos por WhatsApp cuando esté '
                'confirmado.',
          ),
          FaqItem(
            question: '¿Cuánto tarda en llegar mi pedido?',
            answer:
                'Los tiempos estimados son de 1 a 3 días hábiles para Gran '
                'Asunción y de 3 a 7 días hábiles para el interior del país, '
                'contados desde la confirmación del pago.',
          ),
          FaqItem(
            question: '¿Hacen envíos al interior del país?',
            answer:
                'Sí, enviamos a la mayoría de las ciudades del Paraguay. Si '
                'tu ciudad no aparece en la lista del checkout, escribinos '
                'por WhatsApp para coordinar el envío o el retiro en un '
                'punto cercano.',
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
            question: '¿Puedo retirar en persona?',
            answer:
                'Sí, en algunas ciudades contamos con puntos de retiro. En el '
                'checkout vas a ver marcadas las ciudades con punto de '
                'entrega disponible.',
          ),
          FaqItem(
            question: '¿Puedo cancelar mi pedido?',
            answer:
                'Sí. Si todavía no lo despachamos, escribinos por WhatsApp '
                'con tu número de pedido y lo cancelamos. Si ya está '
                'despachado, podés solicitar una devolución al recibirlo.',
          ),
          FaqItem(
            question: '¿Qué hago si mi producto llega dañado?',
            answer:
                'Contactanos por WhatsApp dentro de las 48 horas de recibido '
                'el pedido, adjuntando fotos del producto y del empaque. Te '
                'damos una solución inmediata.',
          ),
          FaqItem(
            question: '¿Cómo sé que mi pago fue recibido?',
            answer:
                'Una vez que verificamos la acreditación en nuestra cuenta, te '
                'enviamos un mensaje por WhatsApp confirmando la recepción del '
                'pago y el inicio del proceso del pedido.',
          ),
          FaqItem(
            question: '¿Puedo cambiar mi dirección de entrega?',
            answer:
                'Sí, siempre que el pedido no haya sido despachado. Escribinos '
                'por WhatsApp con la nueva dirección y la actualizamos.',
          ),
        ],
      ),
    );
  }
}