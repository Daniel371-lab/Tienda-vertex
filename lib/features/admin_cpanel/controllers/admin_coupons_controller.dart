import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/coupon_model.dart';
import '../../../services/firebase/firebase_providers.dart';

class AdminCouponsState {
  const AdminCouponsState({
    this.coupons = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Coupon> coupons;
  final bool isLoading;
  final String? error;

  AdminCouponsState copyWith({
    List<Coupon>? coupons,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminCouponsState(
        coupons: coupons ?? this.coupons,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AdminCouponsController extends StateNotifier<AdminCouponsState> {
  AdminCouponsController(this._ref) : super(const AdminCouponsState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final db = _ref.read(firestoreInstanceProvider);
      final snap = await db.collection('coupons').get();
      final coupons = snap.docs
          .map((d) => Coupon.fromFirestore(d))
          .toList()
        ..sort((a, b) {
          final aD = a.createdAt ?? DateTime(1970);
          final bD = b.createdAt ?? DateTime(1970);
          return bD.compareTo(aD);
        });

      state = state.copyWith(coupons: coupons, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar cupones: $e',
      );
    }
  }

  Future<bool> saveCoupon(Coupon coupon) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);

      // Validar código único.
      final exists = await db
          .collection('coupons')
          .where('code', isEqualTo: coupon.code.toUpperCase())
          .get();

      final conflict = exists.docs.where((d) => d.id != coupon.id).isNotEmpty;
      if (conflict) {
        state = state.copyWith(
          error: 'Ya existe un cupón con el código "${coupon.code}".',
        );
        return false;
      }

      if (coupon.id.isEmpty) {
        final ref = db.collection('coupons').doc();
        await ref.set(coupon.toMap());
      } else {
        await db.collection('coupons').doc(coupon.id).update(
              coupon.toMap(),
            );
      }
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo guardar: $e');
      return false;
    }
  }

  Future<bool> toggleActive(Coupon c) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      await db.collection('coupons').doc(c.id).update({
        'isActive': !c.isActive,
      });
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCoupon(String id) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      await db.collection('coupons').doc(id).delete();
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo eliminar: $e');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final adminCouponsControllerProvider =
    StateNotifierProvider<AdminCouponsController, AdminCouponsState>((ref) {
  return AdminCouponsController(ref);
});