import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/coupon_model.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase/firebase_providers.dart';

// ─────────────────────────────────────────────────────────────
// Item del carrito
// ─────────────────────────────────────────────────────────────

class CartItem {
  const CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.categoryId,
  });

  final String productId;
  final String title;
  final int price;
  final int quantity;
  final String imageUrl;
  final String? categoryId;

  int get lineTotal => price * quantity;

  CartItem copyWith({int? quantity, int? price, String? imageUrl}) => CartItem(
        productId: productId,
        title: title,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl ?? this.imageUrl,
        categoryId: categoryId,
      );

  factory CartItem.fromProduct(Product product, {int quantity = 1}) =>
      CartItem(
        productId: product.id,
        title: product.title,
        price: product.price,
        quantity: quantity,
        imageUrl: product.mainImage,
        categoryId: product.categoryId,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'categoryId': categoryId,
      };

  factory CartItem.fromJson(Map<String, dynamic> map) => CartItem(
        productId: map['productId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: map['imageUrl'] as String? ?? '',
        categoryId: map['categoryId'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────
// Estado del carrito
// ─────────────────────────────────────────────────────────────

class CartState {
  const CartState({
    this.items = const [],
    this.coupon,
    this.discountAmount = 0,
    this.isHydrated = false,
  });

  final List<CartItem> items;
  final Coupon? coupon;
  final int discountAmount;
  final bool isHydrated;

  int get itemCount => items.fold(0, (s, it) => s + it.quantity);

  int get subtotal => items.fold(0, (s, it) => s + it.lineTotal);

  int get total => (subtotal - discountAmount).clamp(0, subtotal);

  bool get isEmpty => items.isEmpty;

  bool get hasCoupon => coupon != null;

  CartState copyWith({
    List<CartItem>? items,
    Coupon? coupon,
    int? discountAmount,
    bool? isHydrated,
    bool clearCoupon = false,
  }) =>
      CartState(
        items: items ?? this.items,
        coupon: clearCoupon ? null : (coupon ?? this.coupon),
        discountAmount:
            clearCoupon ? 0 : (discountAmount ?? this.discountAmount),
        isHydrated: isHydrated ?? this.isHydrated,
      );
}

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

class CartController extends StateNotifier<CartState> {
  CartController(this._ref) : super(const CartState()) {
    _hydrate();
  }

  final Ref _ref;
  static const String _storageKey = 'cart_v1';
  static const String _timestampKey = 'cart_updated_at';
  static const Duration _ttl = Duration(days: 7);

  // ── Persistencia ──────────────────────────────────────────

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_timestampKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Expirar carrito si superó el TTL.
    if (ts != null && now - ts > _ttl.inMilliseconds) {
      await prefs.remove(_storageKey);
      await prefs.remove(_timestampKey);
      state = state.copyWith(isHydrated: true);
      return;
    }

    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      state = state.copyWith(isHydrated: true);
      return;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final itemsList = (map['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Validar contra Firestore que sigan activos con stock.
      final validated = await _validateAgainstFirestore(itemsList);

      state = state.copyWith(items: validated, isHydrated: true);
    } catch (_) {
      state = state.copyWith(isHydrated: true);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'items': state.items.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(map));
    await prefs.setInt(
      _timestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Revalida cada ítem contra la base: producto activo y stock suficiente.
  Future<List<CartItem>> _validateAgainstFirestore(List<CartItem> items) async {
    if (items.isEmpty) return [];

    final fs = _ref.read(firestoreServiceProvider);
    final ids = items.map((e) => e.productId).toList();
    final products = await fs.findProductsByIds(ids);
    final map = {for (final p in products) p.id: p};

    final validated = <CartItem>[];
    for (final item in items) {
      final product = map[item.productId];
      if (product == null) continue; // producto eliminado
      if (!product.isActive) continue; // desactivado
      if (product.stock <= 0) continue; // sin stock
      final qty = item.quantity.clamp(1, product.stock);
      validated.add(
        item.copyWith(
          quantity: qty,
          price: product.price,
          imageUrl: product.mainImage,
        ),
      );
    }
    return validated;
  }

  // ── Operaciones ───────────────────────────────────────────

  Future<void> addProduct(Product product, {int quantity = 1}) async {
    if (product.stock <= 0) return;

    final items = [...state.items];
    final idx = items.indexWhere((e) => e.productId == product.id);

    if (idx >= 0) {
      final existing = items[idx];
      final newQty = (existing.quantity + quantity).clamp(1, product.stock);
      items[idx] = existing.copyWith(quantity: newQty, price: product.price);
    } else {
      items.add(
        CartItem.fromProduct(
          product,
          quantity: quantity.clamp(1, product.stock),
        ),
      );
    }

    state = state.copyWith(items: items);
    await _persist();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeProduct(productId);
      return;
    }
    final items = state.items
        .map((e) => e.productId == productId ? e.copyWith(quantity: quantity) : e)
        .toList();
    state = state.copyWith(items: items);
    await _persist();
  }

  Future<void> removeProduct(String productId) async {
    final items =
        state.items.where((e) => e.productId != productId).toList();
    state = state.copyWith(items: items);
    await _persist();
  }

  Future<void> clear() async {
    state = const CartState(isHydrated: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_timestampKey);
  }

  // ── Cupón ─────────────────────────────────────────────────

  /// Aplica un cupón. Devuelve true si fue válido.
  Future<bool> applyCoupon(String code) async {
    final fs = _ref.read(firestoreServiceProvider);
    final coupon = await fs.findCouponByCode(code);
    if (coupon == null || !coupon.isUsable) return false;

    final discount = coupon.calculateDiscount(state.subtotal);
    if (discount <= 0) return false;

    state = state.copyWith(coupon: coupon, discountAmount: discount);
    await _persist();
    return true;
  }

  Future<void> removeCoupon() async {
    state = state.copyWith(clearCoupon: true);
    await _persist();
  }

  /// Recalcula el descuento si el subtotal cambió.
  void recalculateDiscount() {
    if (state.coupon == null) return;
    final discount = state.coupon!.calculateDiscount(state.subtotal);
    state = state.copyWith(discountAmount: discount);
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) {
  return CartController(ref);
});

/// Contador liviano para el badge del header.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartControllerProvider).itemCount;
});