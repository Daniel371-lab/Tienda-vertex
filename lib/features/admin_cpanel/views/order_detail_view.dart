import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../models/order_model.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../controllers/admin_orders_controller.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailView extends ConsumerStatefulWidget {
  const OrderDetailView({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends ConsumerState<OrderDetailView> {
  Order? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await ref
          .read(firestoreServiceProvider)
          .findOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = o;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el pedido: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/admin/pedidos'),
          ),
          title: const Text('Pedido'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error ?? 'Pedido no encontrado'),
          ),
        ),
      );
    }

    final o = _order!;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/pedidos'),
        ),
        title: Text('#${o.shortId}'),
        actions: [
          IconButton(
            tooltip: 'Copiar ID completo',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: o.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID copiado'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: OrderStatusBadge(status: o.status)),
            const SizedBox(height: 20),

            // ── Acciones según estado ──────────────────────
            _StatusActions(
              order: o,
              onChangeStatus: _changeStatus,
              onCancel: () => _changeStatus(OrderStatus.cancelado),
            ),

            const SizedBox(height: 20),

            // ── Datos del cliente ──────────────────────────
            _Section(
              title: 'Cliente',
              icon: Icons.person_outline_rounded,
              children: [
                _Field(label: 'Nombre', value: o.customerName),
                _Field(
                  label: 'Teléfono',
                  value: PhoneValidator.formatForDisplay(o.phone),
                  onCopy: () => Clipboard.setData(
                    ClipboardData(text: o.phone),
                  ),
                ),
                _Field(
                  label: 'Entrega',
                  value: '${o.city}, ${o.department}',
                ),
                _Field(label: 'Dirección', value: o.address),
                if (o.holderName != null && o.holderName!.isNotEmpty)
                  _Field(label: 'Titular del pago', value: o.holderName!),
                if (o.sourceBank != null && o.sourceBank!.isNotEmpty)
                  _Field(label: 'Banco emisor', value: o.sourceBank!),
              ],
            ),

            const SizedBox(height: 16),

            // ── Ítems ──────────────────────────────────────
            _Section(
              title: 'Ítems (${o.itemCount})',
              icon: Icons.shopping_bag_outlined,
              children: [
                for (var i = 0; i < o.items.length; i++)
                  _OrderItemRow(
                    item: o.items[i],
                    isLast: i == o.items.length - 1,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Resumen de pago ────────────────────────────
            _Section(
              title: 'Pago',
              icon: Icons.receipt_outlined,
              children: [
                _SummaryRow(
                  label: 'Subtotal',
                  value: CurrencyFormatter.format(o.subtotal),
                ),
                if (o.discount > 0)
                  _SummaryRow(
                    label: 'Descuento ${o.couponCode ?? ""}',
                    value: '-${CurrencyFormatter.format(o.discount)}',
                    valueColor: AppColors.success,
                  ),
                const Divider(height: 16),
                _SummaryRow(
                  label: 'Total',
                  value: CurrencyFormatter.format(o.total),
                  bold: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Timeline ───────────────────────────────────
            _Section(
              title: 'Historial',
              icon: Icons.timeline_rounded,
              children: [
                _TimelineRow(
                  label: 'Creado',
                  date: o.createdAt,
                  isFirst: true,
                ),
                if (o.paidAt != null)
                  _TimelineRow(label: 'Pago confirmado', date: o.paidAt),
                _TimelineRow(
                  label: 'Última actualización',
                  date: o.updatedAt,
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Botones inferiores ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactViaWhatsapp(o),
                    icon: const Icon(Icons.chat_rounded,
                        size: 18, color: AppColors.whatsapp),
                    label: const Text(
                      'Abrir chat',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(o),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.danger),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Lógica de cambio de estado — AHORA EN EL STATE
  // ─────────────────────────────────────────────────────────

  Future<void> _changeStatus(OrderStatus newStatus) async {
    final o = _order;
    if (o == null) return;

    // Paso 1: confirmación.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Marcar como "${newStatus.label}"'),
        content: const Text(
          'Se guardará el nuevo estado y podrás enviar un mensaje '
          'al cliente por WhatsApp con la actualización.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Paso 2: actualizar en Firestore.
    final ctrl = ref.read(adminOrdersControllerProvider.notifier);
    final ok = await ctrl.updateStatus(
      orderId: o.id,
      newStatus: newStatus,
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el estado'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Paso 3: recargar el pedido local.
    await _load();
    if (!mounted) return;

    // Paso 4: preguntar si quiere avisar por WhatsApp.
    final sendWa = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Estado actualizado'),
        content: Text(
          '¿Querés avisarle al cliente por WhatsApp que su pedido '
          'ahora está "${newStatus.label}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Después'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('Enviar WhatsApp'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.whatsapp,
            ),
          ),
        ],
      ),
    );

    if (sendWa == true && mounted) {
      final wa = ref.read(whatsappServiceProvider);
      final updated = o.copyWith(status: newStatus);
      await wa.contactCustomerAboutStatus(
        order: updated,
        newStatus: newStatus,
      );
    }
  }

  Future<void> _contactViaWhatsapp(Order o) async {
    final wa = ref.read(whatsappServiceProvider);
    final message = wa.buildStatusMessage(
      o,
      o.status == OrderStatus.pendientePago
          ? OrderStatus.pagado
          : o.status,
    );
    final msg = message.isEmpty
        ? 'Hola ${o.customerName.split(' ').first} 👋'
        : message;

    await wa.openChat(phone: o.phone, message: msg);
  }

  Future<void> _confirmDelete(Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar pedido'),
        content: Text(
          '¿Eliminar el pedido #${o.shortId} definitivamente?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final result = await ref
        .read(adminOrdersControllerProvider.notifier)
        .deleteOrder(o.id);

    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido eliminado'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/admin/pedidos');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Acciones (ahora con callbacks del State)
// ─────────────────────────────────────────────────────────────

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.order,
    required this.onChangeStatus,
    required this.onCancel,
  });

  final Order order;
  final void Function(OrderStatus) onChangeStatus;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(order.status);
    final canCancel = order.status != OrderStatus.entregado &&
        order.status != OrderStatus.cancelado;

    return Column(
      children: [
        if (next != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onChangeStatus(next),
              icon: Icon(_iconFor(next)),
              label: Text(_labelFor(next)),
            ),
          ),
        if (canCancel) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined,
                  size: 18, color: AppColors.danger),
              label: const Text(
                'Cancelar pedido',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ),
        ],
      ],
    );
  }

  OrderStatus? _nextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.pendientePago:
        return OrderStatus.pagado;
      case OrderStatus.pagado:
        return OrderStatus.comprandoProveedor;
      case OrderStatus.comprandoProveedor:
        return OrderStatus.listoDespacho;
      case OrderStatus.listoDespacho:
        return OrderStatus.despachado;
      case OrderStatus.despachado:
        return OrderStatus.entregado;
      case OrderStatus.entregado:
      case OrderStatus.cancelado:
        return null;
    }
  }

  String _labelFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pagado:
        return 'Confirmar pago recibido';
      case OrderStatus.comprandoProveedor:
        return 'Marcar comprando al proveedor';
      case OrderStatus.listoDespacho:
        return 'Marcar listo para despachar';
      case OrderStatus.despachado:
        return 'Marcar despachado';
      case OrderStatus.entregado:
        return 'Marcar entregado';
      case OrderStatus.cancelado:
        return 'Cancelar';
      default:
        return s.label;
    }
  }

  IconData _iconFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pagado:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.comprandoProveedor:
        return Icons.shopping_cart_outlined;
      case OrderStatus.listoDespacho:
        return Icons.inventory_2_outlined;
      case OrderStatus.despachado:
        return Icons.local_shipping_outlined;
      case OrderStatus.entregado:
        return Icons.verified_outlined;
      default:
        return Icons.arrow_forward_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.onCopy,
  });
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onCopy != null)
            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, this.isLast = false});
  final OrderItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.quantity} × ${CurrencyFormatter.format(item.price)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.lineTotal),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color:
                  bold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    this.date,
    this.isFirst = false,
    this.isLast = false,
  });
  final String label;
  final DateTime? date;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 24,
                  color: AppColors.border,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (date != null)
                  Text(
                    DateHelpers.dateTime(date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}