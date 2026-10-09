import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../models/coupon_model.dart';
import '../controllers/admin_coupons_controller.dart';

class CouponManagerView extends ConsumerStatefulWidget {
  const CouponManagerView({super.key});

  @override
  ConsumerState<CouponManagerView> createState() => _CouponManagerViewState();
}

class _CouponManagerViewState extends ConsumerState<CouponManagerView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCouponsControllerProvider);
    final ctrl = ref.read(adminCouponsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: state.isLoading && state.coupons.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.coupons.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: ctrl.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.coupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CouponTile(
                      coupon: state.coupons[i],
                      onEdit: () => _showForm(state.coupons[i]),
                      onToggleActive: () =>
                          ctrl.toggleActive(state.coupons[i]),
                      onDelete: () => _confirmDelete(state.coupons[i]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showForm(null),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo cupón',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _showForm(Coupon? existing) async {
    final result = await showModalBottomSheet<Coupon>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CouponFormSheet(existing: existing),
    );

    if (result == null || !mounted) return;

    final ok = await ref
        .read(adminCouponsControllerProvider.notifier)
        .saveCoupon(result);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Cupón creado'
              : 'Cupón actualizado'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(adminCouponsControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'No se pudo guardar'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Coupon c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar cupón "${c.code}"'),
        content: const Text(
          '¿Confirmás eliminar este cupón? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final result = await ref
        .read(adminCouponsControllerProvider.notifier)
        .deleteCoupon(c.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Cupón eliminado' : 'No se pudo eliminar'),
          backgroundColor:
              result ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({
    required this.coupon,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Coupon coupon;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      coupon.code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: coupon.isUsable
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.textMuted.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      coupon.isUsable ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: coupon.isUsable
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _description(coupon),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (coupon.maxUses > 0) ...[
                    Icon(Icons.people_outline_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${coupon.currentUses}/${coupon.maxUses} usos',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (coupon.validUntil != null) ...[
                    Icon(Icons.schedule_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Vence ${DateHelpers.short(coupon.validUntil)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (v) {
                      if (v == 'toggle') onToggleActive();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              coupon.isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(coupon.isActive
                                ? 'Desactivar'
                                : 'Activar'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _description(Coupon c) {
    final parts = <String>[];
    if (c.discountPercent > 0) {
      parts.add('${c.discountPercent}% de descuento');
    }
    if (c.discountAmount > 0) {
      parts.add('${CurrencyFormatter.format(c.discountAmount)} de descuento');
    }
    if (c.minPurchase > 0) {
      parts.add(
        'mínimo ${CurrencyFormatter.format(c.minPurchase)}',
      );
    }
    return parts.join(' · ');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_offer_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Sin cupones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Creá cupones de descuento para tus clientes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Formulario (bottom sheet)
// ─────────────────────────────────────────────────────────────

class _CouponFormSheet extends StatefulWidget {
  const _CouponFormSheet({this.existing});
  final Coupon? existing;

  @override
  State<_CouponFormSheet> createState() => _CouponFormSheetState();
}

class _CouponFormSheetState extends State<_CouponFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _percentCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();

  String _discountType = 'percent'; // 'percent' | 'amount'
  bool _isActive = true;
  DateTime? _validUntil;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _codeCtrl.text = e.code;
      _percentCtrl.text = e.discountPercent > 0 ? '${e.discountPercent}' : '';
      _amountCtrl.text = e.discountAmount > 0 ? '${e.discountAmount}' : '';
      _minCtrl.text = e.minPurchase > 0 ? '${e.minPurchase}' : '';
      _maxUsesCtrl.text = e.maxUses > 0 ? '${e.maxUses}' : '';
      _isActive = e.isActive;
      _validUntil = e.validUntil;
      _discountType = e.discountPercent > 0 ? 'percent' : 'amount';
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _percentCtrl.dispose();
    _amountCtrl.dispose();
    _minCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

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
                    isEditing ? 'Editar cupón' : 'Nuevo cupón',
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
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _label(context, 'Código'),
                    TextFormField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'VERTEX10',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 3) {
                          return 'Mínimo 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _label(context, 'Tipo de descuento'),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeOption(
                            label: 'Porcentaje',
                            icon: Icons.percent_rounded,
                            selected: _discountType == 'percent',
                            onTap: () => setState(
                                () => _discountType = 'percent'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeOption(
                            label: 'Monto fijo',
                            icon: Icons.attach_money_rounded,
                            selected: _discountType == 'amount',
                            onTap: () => setState(
                                () => _discountType = 'amount'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_discountType == 'percent') ...[
                      _label(context, 'Porcentaje (%)'),
                      TextFormField(
                        controller: _percentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '10'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0 || n > 100) {
                            return 'Entre 1 y 100';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      _label(context, 'Monto de descuento (₲)'),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '20000'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'Monto inválido';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    _label(context, 'Compra mínima (₲)'),
                    TextFormField(
                      controller: _minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Opcional',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label(context, 'Máximo de usos'),
                    TextFormField(
                      controller: _maxUsesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Opcional (vacío = ilimitado)',
                      ),
                    ),
                    const SizedBox(height: 20),

                    _label(context, 'Fecha de vencimiento'),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _validUntil == null
                                    ? 'Sin vencimiento'
                                    : DateHelpers.short(_validUntil),
                                style: TextStyle(
                                  color: _validUntil == null
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (_validUntil != null)
                              IconButton(
                                onPressed: () =>
                                    setState(() => _validUntil = null),
                                icon: const Icon(Icons.close_rounded,
                                    size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SwitchListTile(
                        title: const Text('Cupón activo'),
                        subtitle:
                            const Text('Los clientes pueden usarlo'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          isEditing ? 'Guardar cambios' : 'Crear cupón',
                        ),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _validUntil = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final coupon = Coupon(
      id: widget.existing?.id ?? '',
      code: _codeCtrl.text.trim().toUpperCase(),
      discountPercent: _discountType == 'percent'
          ? int.tryParse(_percentCtrl.text) ?? 0
          : 0,
      discountAmount: _discountType == 'amount'
          ? int.tryParse(_amountCtrl.text) ?? 0
          : 0,
      minPurchase: int.tryParse(_minCtrl.text) ?? 0,
      maxUses: int.tryParse(_maxUsesCtrl.text) ?? 0,
      currentUses: widget.existing?.currentUses ?? 0,
      isActive: _isActive,
      validUntil: _validUntil,
      createdAt: widget.existing?.createdAt,
    );

    Navigator.of(context).pop(coupon);
  }

  TextStyle? _labelStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium
      ?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(text, style: _labelStyle(context)),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}