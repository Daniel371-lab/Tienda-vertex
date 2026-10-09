import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/order_model.dart';
import '../../../services/firebase/firebase_providers.dart';

class AdminOrdersState {
  const AdminOrdersState({
    this.orders = const [],
    this.statusFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<Order> orders;
  final OrderStatus? statusFilter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<Order> get filteredOrders {
    var list = orders;
    if (statusFilter != null) {
      list = list.where((o) => o.status == statusFilter).toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) {
        return o.customerName.toLowerCase().contains(q) ||
            o.phone.contains(q) ||
            o.shortId.toLowerCase().contains(q) ||
            o.city.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  Map<OrderStatus, int> get countByStatus {
    final map = <OrderStatus, int>{};
    for (final s in OrderStatus.values) {
      map[s] = orders.where((o) => o.status == s).length;
    }
    return map;
  }

  AdminOrdersState copyWith({
    List<Order>? orders,
    OrderStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminOrdersState(
        orders: orders ?? this.orders,
        statusFilter:
            clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
        searchQuery: searchQuery ?? this.searchQuery,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AdminOrdersController extends StateNotifier<AdminOrdersState> {
  AdminOrdersController(this._ref) : super(const AdminOrdersState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final db = _ref.read(firestoreInstanceProvider);
      final snap = await db.collection('orders').limit(200).get();

      final orders = snap.docs
          .map((d) => Order.fromFirestore(d))
          .toList()
        ..sort((a, b) {
          final aD = a.createdAt ?? DateTime(1970);
          final bD = b.createdAt ?? DateTime(1970);
          return bD.compareTo(aD);
        });

      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar pedidos: $e',
      );
    }
  }

  void setStatusFilter(OrderStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  Future<bool> updateStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      final update = <String, dynamic>{
        'status': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == OrderStatus.pagado) {
        update['paidAt'] = FieldValue.serverTimestamp();
      }

      await db.collection('orders').doc(orderId).update(update);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo actualizar: $e');
      return false;
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      await db.collection('orders').doc(orderId).delete();
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo eliminar: $e');
      return false;
    }
  }
}

final adminOrdersControllerProvider =
    StateNotifierProvider<AdminOrdersController, AdminOrdersState>((ref) {
  return AdminOrdersController(ref);
});