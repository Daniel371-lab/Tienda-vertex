import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_validator.dart';
import '../../client_store/controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/checkout_form.dart';

/// Modal de checkout. Se abre desde el carrito.
/// En el Mensaje 2 se conecta con Firestore y WhatsApp.
class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutControllerProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final checkout = ref.watch(checkoutControllerProvider);

    final total = (cart.subtotal - checkout.discountAmount)
        .clamp(0, cart.subtotal);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
            // Handle visual
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

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Text(
                    AppStrings.checkoutTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CheckoutForm(),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: AppStrings.subtotal,
                      value: CurrencyFormatter.format(cart.subtotal),
                    ),
                    if (checkout.discountAmount > 0)
                      _SummaryRow(
                        label:
                            '${AppStrings.discount} (${checkout.appliedCouponCode})',
                        value:
                            '-${CurrencyFormatter.format(checkout.discountAmount)}',
                        valueColor: AppColors.success,
                      ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: AppStrings.total,
                      value: CurrencyFormatter.format(total),
                      bold: true,
                    ),
                    const SizedBox(height: 16),
                    if (checkout.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 18, color: AppColors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  checkout.error!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: checkout.isSubmitting
                            ? null
                            : () => _confirm(context),
                        icon: checkout.isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          checkout.isSubmitting
                              ? 'Enviando...'
                              : AppStrings.confirmOrder,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '💳 Pago contra entrega',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    final cart = ref.read(cartControllerProvider);
    final checkout = ref.read(checkoutControllerProvider);
    final ctrl = ref.read(checkoutControllerProvider.notifier);

    // Validaciones del lado cliente.
    if (cart.isEmpty) {
      ctrl.setError('El carrito está vacío.');
      return;
    }
    if (checkout.fullName.trim().length < 3) {
      ctrl.setError('Ingresá tu nombre completo.');
      return;
    }
    if (!PhoneValidator.isValid(checkout.phone)) {
      ctrl.setError('Ingresá un teléfono paraguayo válido.');
      return;
    }
    if (checkout.department == null || checkout.city == null) {
      ctrl.setError('Seleccioná departamento y ciudad.');
      return;
    }
    if (checkout.address.trim().length < 5) {
      ctrl.setError('Ingresá una dirección o referencia válida.');
      return;
    }

    // Stub: la lógica real (guardar en Firestore + WhatsApp)
    // se implementa en el Mensaje 2.
    ctrl.setError(
      'Listo para el siguiente paso. Conexión con Firestore y WhatsApp '
      'se agrega en el Mensaje 2.',
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}