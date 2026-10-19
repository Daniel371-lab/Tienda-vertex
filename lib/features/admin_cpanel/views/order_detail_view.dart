import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../models/order_model.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../controllers/admin_orders_controller.dart';
import '../utils/pdf_generator.dart';
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
  bool _generatingPdf = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await ref.read(firestoreServiceProvider).findOrderById(widget.orderId);
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

  Future<void> _printReceipt(Order o) async {
    setState(() => _generatingPdf = true);
    try {
      final pdfBytes = await PdfGenerator.generateReceipt(o);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Comprobante_${o.shortId}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
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
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? 'Pedido no encontrado'))),
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID copiado'), behavior: SnackBarBehavior.floating));
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

            _StatusActions(
              order: o,
              onChangeStatus: _changeStatus,
              onCancel: () => _changeStatus(OrderStatus.cancelado),
            ),

            const SizedBox(height: 20),

            _Section(
              title: 'Cliente y Entrega',
              icon: Icons.person_outline_rounded,
              children: [
                _Field(label: 'Nombre', value: o.customerName),
                _Field(
                  label: 'Teléfono',
                  value: PhoneValidator.formatForDisplay(o.phone),
                  onCopy: () => Clipboard.setData(ClipboardData(text: o.phone)),
                ),
                _Field(label: 'Tipo', value: o.locationType),
                _Field(label: 'Ciudad/Barrio', value: '${o.neighborhood}, ${o.city} (${o.department})'),
                _Field(label: 'Dirección', value: '${o.street1} ${o.street2 ?? ""}'),
                if (o.reference != null && o.reference!.isNotEmpty) _Field(label: 'Referencia', value: o.reference!),
                if (o.googleMapsLink != null && o.googleMapsLink!.isNotEmpty)
                  _Field(
                    label: 'Google Maps',
                    value: 'Copiar link',
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: o.googleMapsLink!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado'), behavior: SnackBarBehavior.floating));
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            _Section(
              title: 'Ítems (${o.itemCount})',
              icon: Icons.shopping_bag_outlined,
              children: [
                for (var i = 0; i < o.items.length; i++)
                  _OrderItemRow(item: o.items[i], isLast: i == o.items.length - 1),
              ],
            ),

            const SizedBox(height: 16),

            _Section(
              title: 'Pago y Costos',
              icon: Icons.receipt_outlined,
              children: [
                _SummaryRow(label: 'Ingreso (Cliente pagó)', value: CurrencyFormatter.format(o.total), bold: true),
                if (o.supplierCost > 0) _SummaryRow(label: 'Costo Proveedor', value: '-${CurrencyFormatter.format(o.supplierCost)}', valueColor: AppColors.danger),
                if (o.realShippingCost > 0) _SummaryRow(label: 'Costo Envío', value: '-${CurrencyFormatter.format(o.realShippingCost)}', valueColor: AppColors.danger),
                if (o.supplierCost > 0 || o.realShippingCost > 0) ...[
                  const Divider(height: 16),
                  _SummaryRow(
                    label: 'Ganancia Neta',
                    value: CurrencyFormatter.format(o.netProfit),
                    bold: true,
                    valueColor: o.netProfit >= 0 ? AppColors.success : AppColors.danger,
                  ),
                ]
              ],
            ),

            const SizedBox(height: 16),

            _Section(
              title: 'Historial',
              icon: Icons.timeline_rounded,
              children: [
                _TimelineRow(label: 'Creado', date: o.createdAt, isFirst: true),
                if (o.paidAt != null) _TimelineRow(label: 'Pago confirmado', date: o.paidAt),
                _TimelineRow(label: 'Última actualización', date: o.updatedAt, isLast: true),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconActionButton(
                  icon: Icons.chat_rounded,
                  color: AppColors.whatsapp,
                  tooltip: 'Abrir chat',
                  onPressed: () => _contactViaWhatsapp(o),
                ),
                const SizedBox(width: 20),
                _IconActionButton(
                  icon: Icons.print_rounded,
                  color: AppColors.primary,
                  tooltip: 'Generar Comprobante',
                  isLoading: _generatingPdf,
                  onPressed: () => _printReceipt(o),
                ),
                const SizedBox(width: 20),
                _IconActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  tooltip: 'Eliminar',
                  onPressed: () => _confirmDelete(o),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(OrderStatus newStatus) async {
    final o = _order;
    if (o == null) return;

    int? supplierCost;
    int? realShippingCost;

    if (newStatus == OrderStatus.comprandoProveedor) {
      supplierCost = await _showCostDialog(title: 'Costo del proveedor', hint: 'Monto pagado (₲)');
      if (supplierCost == null) return;
    }

    if (newStatus == OrderStatus.despachado) {
      realShippingCost = await _showCostDialog(title: 'Costo de envío', hint: 'Monto pagado al courier (₲)');
      if (realShippingCost == null) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Marcar como "${newStatus.label}"'),
        content: const Text('Se guardará el nuevo estado.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogCtx).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ctrl = ref.read(adminOrdersControllerProvider.notifier);
    final ok = await ctrl.updateStatus(orderId: o.id, newStatus: newStatus, supplierCost: supplierCost, realShippingCost: realShippingCost);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo actualizar'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
      return;
    }

    await _load();
    if (!mounted) return;

    final wa = ref.read(whatsappServiceProvider);
    final msg = wa.buildStatusMessage(o, newStatus);
    
    if (msg.isNotEmpty) {
      final sendWa = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Estado actualizado'),
          content: Text('¿Querés avisarle al cliente por WhatsApp que su pedido ahora está "${newStatus.label}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Después')),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('Enviar WhatsApp'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp),
            ),
          ],
        ),
      );

      if (sendWa == true && mounted) {
        final updated = o.copyWith(status: newStatus);
        await wa.contactCustomerAboutStatus(order: updated, newStatus: newStatus);
      }
    }
  }

  Future<int?> _showCostDialog({required String title, required String hint}) async {
    final ctrl = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(null), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(int.tryParse(ctrl.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _contactViaWhatsapp(Order o) async {
    final wa = ref.read(whatsappServiceProvider);
    final message = wa.buildStatusMessage(o, o.status == OrderStatus.pendientePago ? OrderStatus.pagado : o.status);
    final msg = message.isEmpty ? 'Hola ${o.customerName.split(' ').first} 👋' : message;
    await wa.openChat(phone: o.phone, message: msg);
  }

  Future<void> _confirmDelete(Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar pedido'),
        content: Text('¿Eliminar el pedido #${o.shortId} definitivamente?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final result = await ref.read(adminOrdersControllerProvider.notifier).deleteOrder(o.id);
    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido eliminado'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
      context.go('/admin/pedidos');
    }
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color.withOpacity(0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tooltip,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.order, required this.onChangeStatus, required this.onCancel});
  final Order order;
  final void Function(OrderStatus) onChangeStatus;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(order.status);
    final canCancel = order.status != OrderStatus.entregado && order.status != OrderStatus.cancelado;

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
              icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
              label: const Text('Cancelar pedido', style: TextStyle(color: AppColors.danger)),
            ),
          ),
        ],
      ],
    );
  }

  OrderStatus? _nextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.pendientePago: return OrderStatus.pagado;
      case OrderStatus.pagado: return OrderStatus.comprandoProveedor;
      case OrderStatus.comprandoProveedor: return OrderStatus.listoDespacho;
      case OrderStatus.listoDespacho: return OrderStatus.despachado;
      case OrderStatus.despachado: return OrderStatus.entregado;
      case OrderStatus.entregado:
      case OrderStatus.cancelado: return null;
    }
  }

  String _labelFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pagado: return 'Confirmar pago recibido';
      case OrderStatus.comprandoProveedor: return 'Comprando al proveedor';
      case OrderStatus.listoDespacho: return 'Listo para despachar';
      case OrderStatus.despachado: return 'Marcar despachado';
      case OrderStatus.entregado: return 'Marcar entregado';
      default: return s.label;
    }
  }

  IconData _iconFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pagado: return Icons.check_circle_outline_rounded;
      case OrderStatus.comprandoProveedor: return Icons.shopping_cart_outlined;
      case OrderStatus.listoDespacho: return Icons.inventory_2_outlined;
      case OrderStatus.despachado: return Icons.local_shipping_outlined;
      case OrderStatus.entregado: return Icons.verified_outlined;
      default: return Icons.arrow_forward_rounded;
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
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
              Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8)),
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
  const _Field({required this.label, required this.value, this.onCopy});
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
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          if (onCopy != null)
            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary)),
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
                Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 3),
                Text('${item.quantity} × ${CurrencyFormatter.format(item.price)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                
                // ── NUEVO: PROVEEDOR ──
                if (item.suggestedProvider != null && item.suggestedProvider!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 12, color: AppColors.primaryDark),
                        const SizedBox(width: 4),
                        Text(
                          'Proveedor: ${item.suggestedProvider}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
                // ── FIN NUEVO ──

              ],
            ),
          ),
          Text(CurrencyFormatter.format(item.lineTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? AppColors.textPrimary : AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, this.date, this.isFirst = false, this.isLast = false});
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
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              if (!isLast) Container(width: 2, height: 24, color: AppColors.border),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (date != null) Text(DateHelpers.dateTime(date), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}