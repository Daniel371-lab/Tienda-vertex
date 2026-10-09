import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/order_model.dart';
import '../../../services/firebase/firebase_providers.dart';

class TopProduct {
  const TopProduct({
    required this.title,
    required this.totalSold,
    required this.revenue,
  });
  final String title;
  final int totalSold;
  final int revenue;
}

class DashboardData {
  const DashboardData({
    this.ordersToday = 0,
    this.revenueToday = 0,
    this.ordersPendingPayment = 0,
    this.ordersPendingDispatch = 0,
    this.revenueThisWeek = 0,
    this.topProducts = const [],
    this.last7Days = const [],
  });

  final int ordersToday;
  final int revenueToday;
  final int ordersPendingPayment;
  final int ordersPendingDispatch;
  final int revenueThisWeek;
  final List<TopProduct> topProducts;
  final List<int> last7Days;
}

class DashboardController extends StateNotifier<AsyncValue<DashboardData>> {
  DashboardController(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(firestoreInstanceProvider);
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOf7DaysAgo =
          startOfToday.subtract(const Duration(days: 6));

      final snap = await db
          .collection('orders')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOf7DaysAgo),
          )
          .get();

      final orders = snap.docs.map((d) => Order.fromFirestore(d)).toList();

      var ordersToday = 0;
      var revenueToday = 0;
      var pendingPayment = 0;
      var pendingDispatch = 0;
      var revenueWeek = 0;

      final dayBuckets = List<int>.filled(7, 0);
      final productCount = <String, int>{};
      final productRevenue = <String, int>{};

      for (final o in orders) {
        final date = o.createdAt;
        if (date == null) continue;

        final isToday = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        final countsAsRevenue = o.status != OrderStatus.cancelado;

        if (isToday) {
          ordersToday++;
          if (countsAsRevenue) revenueToday += o.total;
        }

        if (countsAsRevenue) revenueWeek += o.total;

        if (o.status == OrderStatus.pendientePago) pendingPayment++;
        if (o.status == OrderStatus.pagado ||
            o.status == OrderStatus.comprandoProveedor) {
          pendingDispatch++;
        }

        final diff = startOfToday.difference(
          DateTime(date.year, date.month, date.day),
        );
        final idx = 6 - diff.inDays;
        if (idx >= 0 && idx < 7 && countsAsRevenue) {
          dayBuckets[idx] += o.total;
        }

        if (countsAsRevenue) {
          for (final item in o.items) {
            productCount[item.title] =
                (productCount[item.title] ?? 0) + item.quantity;
            productRevenue[item.title] =
                (productRevenue[item.title] ?? 0) + item.lineTotal;
          }
        }
      }

      final top = productCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topProducts = top.take(5).map((e) {
        return TopProduct(
          title: e.key,
          totalSold: e.value,
          revenue: productRevenue[e.key] ?? 0,
        );
      }).toList();

      state = AsyncValue.data(DashboardData(
        ordersToday: ordersToday,
        revenueToday: revenueToday,
        ordersPendingPayment: pendingPayment,
        ordersPendingDispatch: pendingDispatch,
        revenueThisWeek: revenueWeek,
        topProducts: topProducts,
        last7Days: dayBuckets,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<DashboardData>>(
        (ref) => DashboardController(ref));