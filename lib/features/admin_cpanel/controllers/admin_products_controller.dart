import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase/firebase_providers.dart';

class AdminProductsState {
  const AdminProductsState({
    this.products = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.showOnlyActive = false,
    this.isLoading = false,
    this.error,
  });

  final List<Product> products;
  final List<Category> categories;
  final String searchQuery;
  final String? selectedCategoryId;
  final bool showOnlyActive;
  final bool isLoading;
  final String? error;

  List<Product> get filteredProducts {
    var list = products;
    if (selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == selectedCategoryId).toList();
    }
    if (showOnlyActive) {
      list = list.where((p) => p.isActive).toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  AdminProductsState copyWith({
    List<Product>? products,
    List<Category>? categories,
    String? searchQuery,
    String? selectedCategoryId,
    bool? showOnlyActive,
    bool? isLoading,
    String? error,
    bool clearCategory = false,
    bool clearError = false,
  }) =>
      AdminProductsState(
        products: products ?? this.products,
        categories: categories ?? this.categories,
        searchQuery: searchQuery ?? this.searchQuery,
        selectedCategoryId: clearCategory
            ? null
            : (selectedCategoryId ?? this.selectedCategoryId),
        showOnlyActive: showOnlyActive ?? this.showOnlyActive,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AdminProductsController extends StateNotifier<AdminProductsState> {
  AdminProductsController(this._ref) : super(const AdminProductsState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final fs = _ref.read(firestoreServiceProvider);
      final db = _ref.read(firestoreInstanceProvider);

      // Categorías
      final cats = await fs.fetchCategories(includeInactive: true);

      // Productos (todos, sin filtrar por isActive)
      final snap = await db
          .collection('products')
          .limit(200)
          .get();
      final products = snap.docs
          .map((d) => Product.fromFirestore(d))
          .toList()
        ..sort((a, b) {
          final aD = a.createdAt ?? DateTime(1970);
          final bD = b.createdAt ?? DateTime(1970);
          return bD.compareTo(aD);
        });

      state = state.copyWith(
        products: products,
        categories: cats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar productos: $e',
      );
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void setCategory(String? id) {
    if (id == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: id);
    }
  }

  void toggleOnlyActive() =>
      state = state.copyWith(showOnlyActive: !state.showOnlyActive);

  Future<bool> toggleActive(Product p) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      await db.collection('products').doc(p.id).update({
        'isActive': !p.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFeatured(Product p) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      await db.collection('products').doc(p.id).update({
        'isFeatured': !p.isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(Product p) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      await db.collection('products').doc(p.id).delete();
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveProduct(Product product) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);

      if (product.id.isEmpty) {
        // Crear
        final ref = db.collection('products').doc();
        await ref.set(product.toMap());
      } else {
        // Actualizar
        await db.collection('products').doc(product.id).update(
              product.toMap(),
            );
      }
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminProductsControllerProvider =
    StateNotifierProvider<AdminProductsController, AdminProductsState>((ref) {
  return AdminProductsController(ref);
});