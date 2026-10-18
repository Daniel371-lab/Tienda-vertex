import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../models/order_model.dart';
import '../../../models/paraguay_locations.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../client_store/controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/checkout_form.dart';
import 'payment_info_view.dart';

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

    final shipping = ParaguayLocations.calculateShipping(
      department: checkout.department,
      subtotal: cart.subtotal,
    );

    final meetsMinimum = ParaguayLocations.meetsMinimum(
      department: checkout.department,
      subtotal: cart.subtotal,
    );

    final minimum = ParaguayLocations.minimumOrderFor(checkout.department);
    final missingAmount = minimum - cart.subtotal;

    final total = (cart.subtotal + shipping - checkout.discountAmount)
        .clamp(0, cart.subtotal + shipping);

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
                    onPressed: checkout.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CheckoutForm(),

                    if (!meetsMinimum) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Para envíos al interior el pedido mínimo es '
                                'de ${CurrencyFormatter.format(minimum)}. '
                                'Te faltan ${CurrencyFormatter.format(missingAmount)}.',
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: AppStrings.subtotal,
                      value: CurrencyFormatter.format(cart.subtotal),
                    ),
                    _SummaryRow(
                      label: 'Envío',
                      value: shipping == 0 ? 'Gratis' : CurrencyFormatter.format(shipping),
                      valueColor: shipping == 0 ? AppColors.success : null,
                    ),
                    if (checkout.discountAmount > 0)
                      _SummaryRow(
                        label: '${AppStrings.discount} (${checkout.appliedCouponCode})',
                        value: '-${CurrencyFormatter.format(checkout.discountAmount)}',
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
                              const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  checkout.error!,
                                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (checkout.isSubmitting || !meetsMinimum) ? null : () => _confirm(shipping),
                        icon: checkout.isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(checkout.isSubmitting ? 'Registrando...' : AppStrings.confirmOrder),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'El pedido se procesa una vez acreditado el pago.',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
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

  Future<void> _confirm(int shipping) async {
    final cart = ref.read(cartControllerProvider);
    final checkout = ref.read(checkoutControllerProvider);
    final ctrl = ref.read(checkoutControllerProvider.notifier);

    // Validaciones
    if (cart.isEmpty) return ctrl.setError('El carrito está vacío.');
    if (checkout.fullName.trim().length < 3) return ctrl.setError('Ingresá tu nombre completo.');
    if (!PhoneValidator.isValid(checkout.phone)) return ctrl.setError('Ingresá un teléfono válido.');
    if (checkout.department == null || checkout.city == null) return ctrl.setError('Seleccioná departamento y ciudad.');
    if (checkout.neighborhood.trim().isEmpty) return ctrl.setError('Ingresá tu barrio.');
    if (checkout.street1.trim().isEmpty) return ctrl.setError('Ingresá tu calle principal.');
    if (checkout.holderName.trim().length < 3) return ctrl.setError('Ingresá el titular de la cuenta.');
    if (checkout.sourceBank == null) return ctrl.setError('Seleccioná tu banco.');

    if (!ParaguayLocations.meetsMinimum(department: checkout.department, subtotal: cart.subtotal)) {
      return ctrl.setError('No cumplís con el mínimo para tu zona.');
    }

    ctrl.setSubmitting(true);

    try {
      final fs = ref.read(firestoreServiceProvider);
      final analytics = ref.read(analyticsServiceProvider);

      try {
        final isBlocked = await fs.isPhoneBlacklisted(checkout.phone);
        if (isBlocked) return ctrl.setError(AppStrings.genericError);
      } catch (_) {}

      final total = (cart.subtotal + shipping - checkout.discountAmount).clamp(0, cart.subtotal + shipping);

      final items = cart.items.map((it) => OrderItem(
                productId: it.productId,
                title: it.title,
                price: it.price,
                quantity: it.quantity,
                imageUrl: it.imageUrl,
              )).toList();

      final order = Order(
        id: '',
        customerName: checkout.fullName.trim(),
        phone: PhoneValidator.toWhatsappFormat(checkout.phone),
        department: checkout.department!,
        city: checkout.city!,
        neighborhood: checkout.neighborhood.trim(),
        street1: checkout.street1.trim(),
        street2: checkout.street2.trim().isEmpty ? null : checkout.street2.trim(),
        locationType: checkout.locationType,
        reference: checkout.reference.trim().isEmpty ? null : checkout.reference.trim(),
        googleMapsLink: checkout.googleMapsLink.trim().isEmpty ? null : checkout.googleMapsLink.trim(),
        items: items,
        subtotal: cart.subtotal,
        shippingCost: shipping,
        discount: checkout.discountAmount,
        couponCode: checkout.appliedCouponCode,
        total: total,
        status: OrderStatus.pendientePago,
        holderName: checkout.holderName.trim(),
        sourceBank: checkout.sourceBank,
      );

      final orderId = await fs.createOrder(order);

      if (checkout.appliedCouponCode != null) {
        try {
          final coupon = await fs.findCouponByCode(checkout.appliedCouponCode!);
          if (coupon != null) await fs.incrementCouponUsage(coupon.id);
        } catch (_) {}
      }

      final settings = await fs.fetchSettings();

      final finalOrder = order.copyWith(id: orderId);

      await analytics.logPurchase(finalOrder);
      await ref.read(cartControllerProvider.notifier).clear();
      ctrl.reset();

      if (!mounted) return;

      final nav = Navigator.of(context);
      nav.pop();

      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (_) => PaymentInfoView(
            shortId: finalOrder.shortId,
            amount: total,
            settings: settings,
          ),
        );
      });
    } catch (e) {
      ctrl.setError(AppStrings.genericError);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.valueColor});
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}