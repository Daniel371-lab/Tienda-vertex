import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../models/paraguay_locations.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../client_store/controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';

const List<String> kSourceBanks = [
  'ueno bank', 'Banco Continental', 'Banco Itaú', 'Banco Atlas',
  'Banco Familiar', 'Banco Visión', 'Banco Sudameris', 'Banco Regional',
  'Banco GNB', 'Banco Basa', 'Banco FIC', 'Financiera Paraguayo Japonesa',
  'Tigo Money', 'Personal Pay', 'Billetera Zimple', 'Otro',
];

class CheckoutForm extends ConsumerStatefulWidget {
  const CheckoutForm({super.key});

  @override
  ConsumerState<CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends ConsumerState<CheckoutForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _neighborhoodCtrl;
  late final TextEditingController _street1Ctrl;
  late final TextEditingController _street2Ctrl;
  late final TextEditingController _referenceCtrl;
  late final TextEditingController _mapsCtrl;
  late final TextEditingController _holderCtrl;
  late final TextEditingController _couponCtrl;
  
  bool _isValidatingCoupon = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(checkoutControllerProvider);
    _nameCtrl = TextEditingController(text: s.fullName);
    _phoneCtrl = TextEditingController(text: s.phone);
    _neighborhoodCtrl = TextEditingController(text: s.neighborhood);
    _street1Ctrl = TextEditingController(text: s.street1);
    _street2Ctrl = TextEditingController(text: s.street2);
    _referenceCtrl = TextEditingController(text: s.reference);
    _mapsCtrl = TextEditingController(text: s.googleMapsLink);
    _holderCtrl = TextEditingController(text: s.holderName);
    _couponCtrl = TextEditingController(text: s.couponCode);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _street1Ctrl.dispose();
    _street2Ctrl.dispose();
    _referenceCtrl.dispose();
    _mapsCtrl.dispose();
    _holderCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutControllerProvider);
    final ctrl = ref.read(checkoutControllerProvider.notifier);

    final departments = ParaguayLocations.departments;
    final cities = ParaguayLocations.citiesOf(state.department);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          label: AppStrings.fieldFullName,
          child: TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: ctrl.setFullName,
            decoration: const InputDecoration(
              hintText: 'Ej: Julio Prieto',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
        ),
        _Field(
          label: AppStrings.fieldPhone,
          child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
              PhoneValidator.inputFormatter,
            ],
            onChanged: ctrl.setPhone,
            decoration: const InputDecoration(
              hintText: '0981 123 456',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
        ),
        _Field(
          label: AppStrings.fieldDepartment,
          child: DropdownButtonFormField<String>(
            value: state.department,
            isExpanded: true,
            items: departments
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: ctrl.setDepartment,
            decoration: const InputDecoration(
              hintText: 'Seleccionar departamento',
              prefixIcon: Icon(Icons.map_outlined, size: 20),
            ),
          ),
        ),
        _Field(
          label: AppStrings.fieldCity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('city_${state.department}'),
                value: state.city,
                isExpanded: true,
                items: cities.map((c) {
                  final hasPickup = ParaguayLocations.hasPickup(c);
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Row(
                      children: [
                        Expanded(child: Text(c)),
                        if (hasPickup) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: state.department == null ? null : ctrl.setCity,
                decoration: InputDecoration(
                  hintText: state.department == null
                      ? 'Elegí un departamento primero'
                      : 'Seleccionar ciudad',
                  prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                ),
              ),
              if (state.department != null && cities.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoMessage(),
              ],
            ],
          ),
        ),

        const Divider(height: 32),
        Text('Dirección de entrega', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),

        _Field(
          label: 'Barrio',
          child: TextField(
            controller: _neighborhoodCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: ctrl.setNeighborhood,
            decoration: const InputDecoration(
              hintText: 'Ej: Villa Morra',
              prefixIcon: Icon(Icons.location_city_rounded, size: 20),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'Calle Principal',
                child: TextField(
                  controller: _street1Ctrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: ctrl.setStreet1,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Av. Corrales',
                    prefixIcon: Icon(Icons.signpost_outlined, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                label: 'Calle Secundaria',
                child: TextField(
                  controller: _street2Ctrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: ctrl.setStreet2,
                  decoration: const InputDecoration(
                    hintText: 'Ej: casi Iturbe',
                    prefixIcon: Icon(Icons.signpost_outlined, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        _Field(
          label: '¿Es Casa o Trabajo?',
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Casa')),
                  selected: state.locationType == 'Casa',
                  onSelected: (_) => ctrl.setLocationType('Casa'),
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    color: state.locationType == 'Casa' ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: state.locationType == 'Casa' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Trabajo')),
                  selected: state.locationType == 'Trabajo',
                  onSelected: (_) => ctrl.setLocationType('Trabajo'),
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    color: state.locationType == 'Trabajo' ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: state.locationType == 'Trabajo' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        _Field(
          label: 'Referencia (opcional)',
          child: TextField(
            controller: _referenceCtrl,
            maxLines: 2,
            onChanged: ctrl.setReference,
            decoration: const InputDecoration(
              hintText: 'Nro de casa, color, a 1 cuadra de farmacia...',
              prefixIcon: Icon(Icons.info_outline_rounded, size: 20),
            ),
          ),
        ),
        _Field(
          label: 'Link de Google Maps (opcional)',
          child: TextField(
            controller: _mapsCtrl,
            onChanged: ctrl.setGoogleMapsLink,
            decoration: const InputDecoration(
              hintText: 'https://maps.app.goo.gl/...',
              prefixIcon: Icon(Icons.map_rounded, size: 20),
            ),
          ),
        ),

        const Divider(height: 32),

        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.account_balance_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Datos para identificar tu pago',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            'Usamos estos datos para reconocer tu transferencia al recibirla.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ),
        _Field(
          label: 'Nombre del titular de la cuenta',
          child: TextField(
            controller: _holderCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: ctrl.setHolderName,
            decoration: const InputDecoration(
              hintText: 'Como figura en tu cuenta bancaria',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
          ),
        ),
        _Field(
          label: 'Banco desde el que vas a transferir',
          child: DropdownButtonFormField<String>(
            value: state.sourceBank,
            isExpanded: true,
            items: kSourceBanks
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: ctrl.setSourceBank,
            decoration: const InputDecoration(
              hintText: 'Seleccionar banco',
              prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
            ),
          ),
        ),

        const Divider(height: 32),

        _Field(
          label: AppStrings.fieldCoupon,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _couponCtrl,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !state.hasCoupon,
                  onChanged: ctrl.setCouponCode,
                  decoration: const InputDecoration(
                    hintText: 'VERTEX10',
                    prefixIcon: Icon(Icons.local_offer_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: state.hasCoupon
                      ? () {
                          ctrl.removeCoupon();
                          _couponCtrl.clear();
                        }
                      : (_isValidatingCoupon ? null : _applyCoupon),
                  child: _isValidatingCoupon
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(state.hasCoupon ? 'Quitar' : AppStrings.applyCoupon),
                ),
              ),
            ],
          ),
        ),
        if (state.couponError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              state.couponError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        if (state.hasCoupon)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  '${AppStrings.couponApplied}: ${state.appliedCouponCode}',
                  style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _applyCoupon() async {
    final ctrl = ref.read(checkoutControllerProvider.notifier);
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);

    try {
      final fs = ref.read(firestoreServiceProvider);
      final cart = ref.read(cartControllerProvider);

      final coupon = await fs.findCouponByCode(code);
      if (coupon == null || !coupon.isUsable) {
        ctrl.rejectCoupon(AppStrings.couponInvalid);
        return;
      }
      final discount = coupon.calculateDiscount(cart.subtotal);
      if (discount <= 0) {
        ctrl.rejectCoupon('El cupón requiere un monto mínimo mayor.');
        return;
      }
      ctrl.applyCoupon(code: coupon.code, discountAmount: discount);
    } catch (_) {
      ctrl.rejectCoupon('Error al validar el cupón. Reintentá.');
    } finally {
      if (mounted) setState(() => _isValidatingCoupon = false);
    }
  }
}

class _InfoMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                children: const [
                  TextSpan(text: 'Las ciudades marcadas con el ícono '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                  ),
                  TextSpan(
                    text: ' en la lista tienen Punto de Entrega. '
                        'Si tu ciudad no está listada, escribinos por '
                        'WhatsApp y coordinamos el retiro en el punto '
                        'más cercano a tu ubicación.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}