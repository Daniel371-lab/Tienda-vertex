import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(dashboardControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardControllerProvider.notifier).load(),
      child: asyncData.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error al cargar el panel:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _KpiGrid(data: data),
            const SizedBox(height: 20),
            _WeekChart(buckets: data.last7Days),
            const SizedBox(height: 20),
            _TopProducts(products: data.topProducts),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width > 600 ? 3 : 2;

    final kpis = [
      _Kpi(
        icon: Icons.receipt_long_outlined,
        label: 'Pedidos hoy',
        value: '${data.ordersToday}',
        color: AppColors.primary,
      ),
      _Kpi(
        icon: Icons.attach_money_rounded,
        label: 'Ingresos hoy',
        value: CurrencyFormatter.format(data.revenueToday),
        color: AppColors.success,
      ),
      _Kpi(
        icon: Icons.hourglass_empty_rounded,
        label: 'Pendientes de pago',
        value: '${data.ordersPendingPayment}',
        color: AppColors.warning,
      ),
      _Kpi(
        icon: Icons.inventory_2_outlined,
        label: 'Por despachar',
        value: '${data.ordersPendingDispatch}',
        color: AppColors.primaryDark,
      ),
      _Kpi(
        icon: Icons.calendar_today_outlined,
        label: 'Ingresos 7 días',
        value: CurrencyFormatter.format(data.revenueThisWeek),
        color: AppColors.textPrimary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => _KpiCard(kpi: kpis[i]),
    );
  }
}

class _Kpi {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});
  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kpi.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi.icon, size: 16, color: kpi.color),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  kpi.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kpi.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.buckets});
  final List<int> buckets;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.fold<int>(0, (a, b) => a > b ? a : b);
    final days = ['-6d', '-5d', '-4d', '-3d', '-2d', 'Ayer', 'Hoy'];

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
          Text(
            'Ingresos últimos 7 días',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final value = buckets[i];
                final factor = maxValue == 0 ? 0.0 : value / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          child: Text(
                            value == 0
                                ? ''
                                : CurrencyFormatter.format(value)
                                    .replaceAll('₲ ', ''),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 90 * factor + 4,
                          decoration: BoxDecoration(
                            color: i == 6
                                ? AppColors.primary
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.products});
  final List<TopProduct> products;

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
          Text(
            'Productos más vendidos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Sin ventas registradas',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            for (var i = 0; i < products.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? AppColors.primary
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i == 0
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        products[i].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${products[i].totalSold} u.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < products.length - 1)
                const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}