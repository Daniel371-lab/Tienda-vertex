import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../models/paraguay_locations.dart';
import '../controllers/checkout_controller.dart';

/// Formulario de datos del cliente para el checkout.
/// Guest checkout: sin registro, sin contraseña, sin email.
class CheckoutForm extends ConsumerStatefulWidget {
  const CheckoutForm({super.key});

  @override
  ConsumerState<CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends ConsumerState<CheckoutForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _couponCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(checkoutControllerProvider);
    _nameCtrl = TextEditingController(text: s.fullName);
    _phoneCtrl = TextEditingController(text: s.phone);
    _addressCtrl = TextEditingController(text: s.address);
    _couponCtrl = TextEditingController(text: s.couponCode);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
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
        // Honeypot invisible — los bots lo llenan, los humanos no.
        _HoneypotField(),

        _Field(
          label: AppStrings.fieldFullName,
          child: TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: ctrl.setFullName,
            decoration: const InputDecoration(
              hintText: 'Ej: Juan Pérez',
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
          child: DropdownButtonFormField<String>(
            value: state.city,
            isExpanded: true,
            items: cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: state.department == null ? null : ctrl.setCity,
            decoration: InputDecoration(
              hintText: state.department == null
                  ? 'Elegí un departamento primero'
                  : 'Seleccionar ciudad',
              prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
            ),
          ),
        ),

        _Field(
          label: AppStrings.fieldAddress,
          child: TextField(
            controller: _addressCtrl,
            maxLines: 2,
            onChanged: ctrl.setAddress,
            decoration: const InputDecoration(
              hintText: 'Calle, número, referencia...',
              prefixIcon: Icon(Icons.home_outlined, size: 20),
            ),
          ),
        ),

        _Field(
          label: AppStrings.fieldCoupon,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _couponCtrl,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: ctrl.setCouponCode,
                  decoration: const InputDecoration(
                    hintText: 'VERTEX10',
                    prefixIcon:
                        Icon(Icons.local_offer_outlined, size: 20),
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
                      : () => _applyCoupon(),
                  child: Text(
                    state.hasCoupon ? 'Quitar' : AppStrings.applyCoupon,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (state.couponError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.couponError!,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12,
              ),
            ),
          ),

        if (state.hasCoupon)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  '${AppStrings.couponApplied}: ${state.appliedCouponCode}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _applyCoupon() async {
    // Stub — la lógica real de validación se implementa en el Mensaje 2.
    final ctrl = ref.read(checkoutControllerProvider.notifier);
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    // Placeholder: solo aplicamos visualmente. La validación real
    // con Firestore se agrega en el siguiente mensaje.
    ctrl.applyCoupon(code: code.toUpperCase(), discountAmount: 0);
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

/// Campo invisible que solo los bots llenan. Si tiene contenido, se bloquea.
class _HoneypotField extends StatefulWidget {
  @override
  State<_HoneypotField> createState() => _HoneypotFieldState();
}

class _HoneypotFieldState extends State<_HoneypotField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fuera de pantalla, inaccesible visualmente, pero presente en el DOM.
    return SizedBox(
      height: 0,
      child: Opacity(
        opacity: 0,
        child: IgnorePointer(
          child: TextField(
            controller: _ctrl,
            autofocus: false,
            decoration: const InputDecoration(
              labelText: 'Website',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}