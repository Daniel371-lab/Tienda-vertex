import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../models/settings_model.dart';
import '../../../services/firebase/firebase_providers.dart';

/// Pantalla que se muestra después de crear un pedido.
/// Indica al cliente los datos para transferir y la advertencia
/// de que el pedido se procesa una vez acreditado el pago.
class PaymentInfoView extends ConsumerWidget {
  const PaymentInfoView({
    super.key,
    required this.shortId,
    required this.amount,
    required this.settings,
  });

  final String shortId;
  final int amount;
  final StoreSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pedido registrado',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pedido #$shortId',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Monto a transferir
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Monto a transferir',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.format(amount),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Datos de pago
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Datos para transferir',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Titular',
                            value: settings.paymentHolderName,
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Banco',
                            value: settings.paymentBank,
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Cuenta',
                            value: settings.paymentAccount,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _copyPaymentData(context),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copiar datos'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Aviso importante
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'El pedido se procesa una vez acreditado el pago '
                              'en la cuenta indicada. Te notificaremos por '
                              'WhatsApp cuando lo confirmemos.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Envío de comprobante opcional
                    Text(
                      '¿Ya realizaste la transferencia?',
                      style: Theme.of(context).textTheme.labelLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enviar el comprobante acelera la verificación.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _sendReceipt(context, ref),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Enviar comprobante por WhatsApp'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.whatsapp,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyPaymentData(BuildContext context) {
    final text = 'Titular: ${settings.paymentHolderName}\n'
        'Banco: ${settings.paymentBank}\n'
        'Cuenta: ${settings.paymentAccount}\n'
        'Monto: ${CurrencyFormatter.format(amount)}\n'
        'Pedido: #$shortId';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos copiados'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendReceipt(BuildContext context, WidgetRef ref) async {
    final normalized = PhoneValidator.toWhatsappFormat(settings.whatsappNumber);
    if (normalized.isEmpty) return;

    final message = 'Hola, realicé el pedido #$shortId por '
        '${CurrencyFormatter.format(amount)}.\n\n'
        'Adjunto el comprobante de pago.';

    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}