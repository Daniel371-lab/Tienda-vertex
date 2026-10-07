import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../app/constants/api_constants.dart';
import '../../models/blacklist_model.dart';
import '../../models/category_model.dart';
import '../../models/coupon_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/settings_model.dart';

/// Capa única de acceso a Firestore.
///
/// Optimizada para Spark:
///   · Paginación obligatoria en listados.
///   · Sin listeners persistentes — se usan Futures para catálogo.
///   · Búsquedas client-side sobre datos ya cargados.
class FirestoreService {
  FirestoreService(this._db);
  final FirebaseFirestore _db;

  static const int pageSize = 24;

  // ─────────────────────────────────────────────────────────────
  // CATEGORÍAS
  // ─────────────────────────────────────────────────────────────

  /// Lee todas las categorías activas ordenadas por `orderIndex`.
  /// Se cachea en el controller — no se debe llamar en cada build.
  Future<List<Category>> fetchCategories({bool includeInactive = false}) async {
    Query query = _db.collection(ApiConstants.colCategories);
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }
    query = query.orderBy('orderIndex');

    final snap = await query.get();
    return snap.docs
        .map((doc) => Category.fromFirestore(doc))
        .toList();
  }

  /// Busca una categoría por su slug.
  Future<Category?> findCategoryBySlug(String slug) async {
    final snap = await _db
        .collection(ApiConstants.colCategories)
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Category.fromFirestore(snap.docs.first);
  }

  /// Busca una categoría por su ID.
  Future<Category?> findCategoryById(String id) async {
    final doc = await _db.collection(ApiConstants.colCategories).doc(id).get();
    if (!doc.exists) return null;
    return Category.fromFirestore(doc);
  }

  // ─────────────────────────────────────────────────────────────
  // PRODUCTOS
  // ─────────────────────────────────────────────────────────────

  /// Productos por categoría (y opcionalmente subcategoría).
  /// Paginado para no agotar el límite de Spark.
  Future<ProductsPage> fetchProducts({
    required String categoryId,
    String? subcategoryId,
    DocumentSnapshot? startAfter,
    int limit = pageSize,
  }) async {
    Query query = _db
        .collection(ApiConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId);

    if (subcategoryId != null && subcategoryId.isNotEmpty) {
      query = query.where('subcategoryId', isEqualTo: subcategoryId);
    }

    query = query.orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.limit(limit).get();
    return ProductsPage(
      products: snap.docs.map((d) => Product.fromFirestore(d)).toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  /// Todos los productos activos (vista global `/`).
  Future<ProductsPage> fetchAllProducts({
    DocumentSnapshot? startAfter,
    int limit = pageSize,
  }) async {
    Query query = _db
        .collection(ApiConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.limit(limit).get();
    return ProductsPage(
      products: snap.docs.map((d) => Product.fromFirestore(d)).toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  /// Productos destacados (para portada global).
  Future<List<Product>> fetchFeatured({int limit = 12}) async {
    final snap = await _db
        .collection(ApiConstants.colProducts)
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Product.fromFirestore(d)).toList();
  }

  /// Obtiene un producto por ID.
  Future<Product?> findProductById(String id) async {
    final doc = await _db.collection(ApiConstants.colProducts).doc(id).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  /// Obtiene varios productos por IDs (para validar carrito).
  /// Firestore limita `whereIn` a 10 elementos por query.
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

  // ─────────────────────────────────────────────────────────────
  // CUPONES
  // ─────────────────────────────────────────────────────────────

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

  /// Incrementa atómicamente el contador de uso del cupón.
  Future<void> incrementCouponUsage(String couponId) async {
    await _db.collection(ApiConstants.colCoupons).doc(couponId).update({
      'currentUses': FieldValue.increment(1),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // PEDIDOS
  // ─────────────────────────────────────────────────────────────

  /// Crea un pedido y devuelve el ID generado.
  Future<String> createOrder(Order order) async {
    final ref = _db.collection(ApiConstants.colOrders).doc();
    final data = order.toMap();
    // El ID se inyecta como campo para facilitar queries desde el cliente.
    data['id'] = ref.id;
    // Estado inicial fijo por seguridad del flujo.
    data['status'] = OrderStatus.pendienteConfirmacion.value;
    await ref.set(data);
    return ref.id;
  }

  Future<Order?> findOrderById(String id) async {
    final doc = await _db.collection(ApiConstants.colOrders).doc(id).get();
    if (!doc.exists) return null;
    return Order.fromFirestore(doc);
  }

  /// Lista pedidos filtrados por estado (cPanel).
  Future<List<Order>> fetchOrders({
    OrderStatus? status,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db.collection(ApiConstants.colOrders);
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }
    query = query.orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.limit(limit).get();
    return snap.docs.map((d) => Order.fromFirestore(d)).toList();
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    await _db.collection(ApiConstants.colOrders).doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // BLACKLIST
  // ─────────────────────────────────────────────────────────────

  /// Verifica si un teléfono está en la lista negra.
  /// Se usa ID determinístico para lectura directa (1 lectura, no query).
  Future<bool> isPhoneBlacklisted(String phone) async {
    final id = BlacklistEntry.buildId(phone);
    final doc = await _db.collection(ApiConstants.colBlacklist).doc(id).get();
    return doc.exists;
  }

  // ─────────────────────────────────────────────────────────────
  // SETTINGS
  // ─────────────────────────────────────────────────────────────

  Future<StoreSettings> fetchSettings() async {
    final doc = await _db
        .collection(ApiConstants.colSettings)
        .doc(ApiConstants.docSettings)
        .get();
    return StoreSettings.fromFirestore(doc);
  }
}

/// Resultado paginado de productos.
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