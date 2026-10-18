import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../app/constants/api_constants.dart';
import '../../models/blacklist_model.dart';
import '../../models/category_model.dart';
import '../../models/coupon_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/settings_model.dart';

class FirestoreService {
  FirestoreService(this._db);
  final FirebaseFirestore _db;

  static const int pageSize = 24;

  // ── CATEGORÍAS ────────────────────────────────────────────────

  Future<List<Category>> fetchCategories({bool includeInactive = false}) async {
    Query query = _db.collection(ApiConstants.colCategories);
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snap = await query.get();
    final list = snap.docs.map((d) => Category.fromFirestore(d)).toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  Future<Category?> findCategoryBySlug(String slug) async {
    final snap = await _db
        .collection(ApiConstants.colCategories)
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Category.fromFirestore(snap.docs.first);
  }

  Future<Category?> findCategoryById(String id) async {
    final doc = await _db.collection(ApiConstants.colCategories).doc(id).get();
    if (!doc.exists) return null;
    return Category.fromFirestore(doc);
  }

  // ── PRODUCTOS ─────────────────────────────────────────────────

  /// Busca productos en Firebase usando el campo searchTitle.
  /// Gasta lecturas solo de los productos que coinciden con la búsqueda.
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    
    final cleanQuery = Product.buildSearchTitle(query.trim());
    
    // Busca los que empiecen con la letra que escribió el cliente
    final snap = await _db
        .collection(ApiConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('searchTitle', isGreaterThanOrEqualTo: cleanQuery)
        .where('searchTitle', isLessThan: '$cleanQuery\uf8ff')
        .limit(pageSize)
        .get();
        
    return snap.docs.map((d) => Product.fromFirestore(d)).toList();
  }

  Future<List<Product>> fetchFeaturedGeneral({int limit = 10}) async {
    final snap = await _db
        .collection(ApiConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('isFeaturedGeneral', isEqualTo: true)
        .limit(limit)
        .get();
    final products = snap.docs.map((d) => Product.fromFirestore(d)).toList();
    products.sort((a, b) {
      final aD = a.createdAt ?? DateTime(1970);
      final bD = b.createdAt ?? DateTime(1970);
      return bD.compareTo(aD);
    });
    return products;
  }

  Future<List<Product>> fetchFeaturedByCategory({
    required String categoryId,
    int limit = 10,
  }) async {
    final snap = await _db
        .collection(ApiConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .where('isFeaturedInCategories', arrayContains: _slugOfCategoryCache[categoryId])
        .limit(limit)
        .get();
    return snap.docs.map((d) => Product.fromFirestore(d)).toList();
  }

  Future<ProductsPage> fetchAllByCategory({
    required String categoryId,
    DocumentSnapshot? startAfter,
    int limit = pageSize,
  }) async {
    Query query = _db
        .collection(ApiConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.limit(limit).get();
    final products = snap.docs.map((d) => Product.fromFirestore(d)).toList();
    products.sort((a, b) {
      final aD = a.createdAt ?? DateTime(1970);
      final bD = b.createdAt ?? DateTime(1970);
      return bD.compareTo(aD);
    });
    return ProductsPage(
      products: products,
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  Future<ProductsPage> fetchAllBySubcategory({
    required String categoryId,
    required String subcategoryId,
    DocumentSnapshot? startAfter,
    int limit = pageSize,
  }) async {
    Query query = _db
        .collection(ApiConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .where('subcategoryId', isEqualTo: subcategoryId);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.limit(limit).get();
    final products = snap.docs.map((d) => Product.fromFirestore(d)).toList();
    products.sort((a, b) {
      final aD = a.createdAt ?? DateTime(1970);
      final bD = b.createdAt ?? DateTime(1970);
      return bD.compareTo(aD);
    });
    return ProductsPage(
      products: products,
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  Future<Product?> findProductById(String id) async {
    final doc = await _db.collection(ApiConstants.colProducts).doc(id).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  Future<List<Product>> findProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }
    final results = <Product>[];
    for (final chunk in chunks) {
      final snap = await _db
          .collection(ApiConstants.colProducts)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map((d) => Product.fromFirestore(d)));
    }
    return results;
  }

  static final Map<String, String> _slugOfCategoryCache = {};

  static void registerCategorySlug(String categoryId, String slug) {
    _slugOfCategoryCache[categoryId] = slug;
  }

  // ── CUPONES ───────────────────────────────────────────────────

  Future<Coupon?> findCouponByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final snap = await _db
        .collection(ApiConstants.colCoupons)
        .where('code', isEqualTo: normalized)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Coupon.fromFirestore(snap.docs.first);
  }

  Future<void> incrementCouponUsage(String couponId) async {
    await _db.collection(ApiConstants.colCoupons).doc(couponId).update({
      'currentUses': FieldValue.increment(1),
    });
  }

  // ── PEDIDOS ───────────────────────────────────────────────────

  Future<String> createOrder(Order order) async {
    final ref = _db.collection(ApiConstants.colOrders).doc();
    final data = order.toMap();
    data['id'] = ref.id;
    data['status'] = OrderStatus.pendientePago.value;
    await ref.set(data);
    return ref.id;
  }

  Future<Order?> findOrderById(String id) async {
    final doc = await _db.collection(ApiConstants.colOrders).doc(id).get();
    if (!doc.exists) return null;
    return Order.fromFirestore(doc);
  }

  Future<List<Order>> fetchOrders({
    OrderStatus? status,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db.collection(ApiConstants.colOrders);
    if (status != null) query = query.where('status', isEqualTo: status.value);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.limit(limit).get();
    final orders = snap.docs.map((d) => Order.fromFirestore(d)).toList();
    orders.sort((a, b) {
      final aD = a.createdAt ?? DateTime(1970);
      final bD = b.createdAt ?? DateTime(1970);
      return bD.compareTo(aD);
    });
    return orders;
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    await _db.collection(ApiConstants.colOrders).doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── BLACKLIST ─────────────────────────────────────────────────

  Future<bool> isPhoneBlacklisted(String phone) async {
    final id = BlacklistEntry.buildId(phone);
    final doc = await _db.collection(ApiConstants.colBlacklist).doc(id).get();
    return doc.exists;
  }

  // ── SETTINGS ──────────────────────────────────────────────────

  Future<StoreSettings> fetchSettings() async {
    final doc = await _db
        .collection(ApiConstants.colSettings)
        .doc(ApiConstants.docSettings)
        .get();
    return StoreSettings.fromFirestore(doc);
  }
}

class ProductsPage {
  const ProductsPage({
    required this.products,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<Product> products;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
}