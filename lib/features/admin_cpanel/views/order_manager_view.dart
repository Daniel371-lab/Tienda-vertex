import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../models/order_model.dart';
import '../controllers/admin_orders_controller.dart';
import '../widgets/order_status_badge.dart';

class OrderManagerView extends ConsumerStatefulWidget {
  const OrderManagerView({super.key});

  @override
  ConsumerState<OrderManagerView> createState() => _OrderManagerViewState();
}

class _OrderManagerViewState extends ConsumerState<OrderManagerView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOrdersControllerProvider);
    final ctrl = ref.read(adminOrdersControllerProvider.notifier);
    final orders = state.filteredOrders;
    final counts = state.countByStatus;

    return Column(
      children: [
        // ── Filtros ──────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: ctrl.setSearch,
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente, teléfono o #ID...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            ctrl.setSearch('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatusChip(
                      label: 'Todos',
                      count: state.orders.length,
                      selected: state.statusFilter == null,
                      onTap: () => ctrl.setStatusFilter(null),
                    ),
                    for (final s in OrderStatus.values)
                      _StatusChip(
                        label: s.label,
                        count: counts[s] ?? 0,
                        selected: state.statusFilter == s,
                        onTap: () => ctrl.setStatusFilter(s),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── DEBUG: contador ─────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.yellow,
          padding: const EdgeInsets.all(8),
          child: Text(
            'DEBUG · isLoading: ${state.isLoading} · '
            'orders: ${state.orders.length} · '
            'filtered: ${orders.length} · '
            'error: ${state.error ?? "ninguno"}',
            style: const TextStyle(fontSize: 11, color: Colors.black),
          ),
        ),

        // ── Lista ────────────────────────────────────────
        Expanded(
          child: Container(
            color: Colors.green.withOpacity(0.2),
            child: orders.isEmpty
                ? const Center(
                    child: Text(
                      'No hay pedidos (lista vacía)',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (_, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrderTile(
                          order: orders[i],
                          onTap: () => context
                              .go('/admin/pedidos/${orders[i].id}'),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                Expanded(
                  child: Text(
                    '#${order.shortId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                OrderStatusBadge(status: order.status, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.customerName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${order.city}, ${order.department}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${order.itemCount} ítem${order.itemCount == 1 ? "" : "s"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('·',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Text(
                  DateHelpers.relative(order.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  CurrencyFormatter.format(order.total),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}