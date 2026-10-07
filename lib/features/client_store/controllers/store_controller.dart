import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/niche_context.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../../services/firebase/firestore_service.dart';

class StoreState {
  const StoreState({
    this.categories = const [],
    this.products = const [],
    this.activeCategory,
    this.activeSubcategory,
    this.selectedSubcategoryId,
    this.lastDoc,
    this.hasMore = false,
    this.isLoadingCategories = false,
    this.isLoadingProducts = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Category> categories;
  final List<Product> products;
  final Category? activeCategory;
  final Subcategory? activeSubcategory;
  final String? selectedSubcategoryId;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  final bool isLoadingCategories;
  final bool isLoadingProducts;
  final bool isLoadingMore;
  final String? error;

  StoreState copyWith({
    List<Category>? categories,
    List<Product>? products,
    Category? activeCategory,
    Subcategory? activeSubcategory,
    String? selectedSubcategoryId,
    bool clearSelectedSubcategory = false,
    bool clearActiveCategory = false,
    bool clearActiveSubcategory = false,
    DocumentSnapshot? lastDoc,
    bool? hasMore,
    bool? isLoadingCategories,
    bool? isLoadingProducts,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return StoreState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      activeCategory: clearActiveCategory
          ? null
          : (activeCategory ?? this.activeCategory),
      activeSubcategory: clearActiveSubcategory
          ? null
          : (activeSubcategory ?? this.activeSubcategory),
      selectedSubcategoryId: clearSelectedSubcategory
          ? null
          : (selectedSubcategoryId ?? this.selectedSubcategoryId),
      lastDoc: lastDoc ?? this.lastDoc,
      hasMore: hasMore ?? this.hasMore,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<Product> get visibleProducts {
    if (selectedSubcategoryId == null) return products;
    return products
        .where((p) => p.subcategoryId == selectedSubcategoryId)
        .toList();
  }

  bool get hasProducts => visibleProducts.isNotEmpty;
}

class StoreController extends StateNotifier<StoreState> {
  StoreController({
    required FirestoreService firestore,
    required AnalyticsService analytics,
  })  : _fs = firestore,
        _analytics = analytics,
        super(const StoreState());

  final FirestoreService _fs;
  final AnalyticsService _analytics;

  Future<void> loadCategories() async {
    if (state.categories.isNotEmpty || state.isLoadingCategories) return;
    state = state.copyWith(isLoadingCategories: true, clearError: true);
    try {
      final cats = await _fs.fetchCategories();
      state = state.copyWith(categories: cats, isLoadingCategories: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        error: 'ERROR CATEGORÍAS: $e',
      );
    }
  }

  Future<void> applyNiche(NicheContext niche) async {
    if (niche.categorySlug == null) {
      await _loadGlobal();
      return;
    }

    final category = await _resolveCategory(niche.categorySlug!);
    if (category == null) {
      await _loadGlobal();
      return;
    }

    Subcategory? sub;
    if (niche.subcategorySlug != null) {
      try {
        sub = category.subcategories
            .firstWhere((s) => s.slug == niche.subcategorySlug);
      } catch (_) {
        sub = null;
      }
    }

    state = state.copyWith(
      activeCategory: category,
      activeSubcategory: sub,
      selectedSubcategoryId: sub?.id,
      products: const [],
      lastDoc: null,
      hasMore: false,
      isLoadingProducts: true,
      clearError: true,
    );

    await _loadProductsForCategory(category.id, sub?.id);
  }

  void selectSubcategory(String? subcategoryId) {
    if (subcategoryId == null) {
      state = state.copyWith(
        clearSelectedSubcategory: true,
        clearActiveSubcategory: true,
      );
    } else {
      final sub = state.activeCategory?.subcategories
          .where((s) => s.id == subcategoryId)
          .firstOrNull;
      state = state.copyWith(
        selectedSubcategoryId: subcategoryId,
        activeSubcategory: sub,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = state.activeCategory == null
          ? await _fs.fetchAllProducts(startAfter: state.lastDoc)
          : await _fs.fetchProducts(
              categoryId: state.activeCategory!.id,
              subcategoryId: state.activeSubcategory?.id,
              startAfter: state.lastDoc,
            );
      state = state.copyWith(
        products: [...state.products, ...page.products],
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'ERROR LOAD MORE: $e',
      );
    }
  }

  Future<Category?> _resolveCategory(String slug) async {
    final cached = state.categories.where((c) => c.slug == slug).firstOrNull;
    if (cached != null) return cached;
    final fetched = await _fs.findCategoryBySlug(slug);
    if (fetched != null) {
      state = state.copyWith(categories: [...state.categories, fetched]);
    }
    return fetched;
  }

  Future<void> _loadGlobal() async {
    state = state.copyWith(
      clearActiveCategory: true,
      clearActiveSubcategory: true,
      clearSelectedSubcategory: true,
      products: const [],
      lastDoc: null,
      hasMore: false,
      isLoadingProducts: true,
      clearError: true,
    );

    try {
      final page = await _fs.fetchAllProducts();
      state = state.copyWith(
        products: page.products,
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
        isLoadingProducts: false,
      );
      await _analytics.logHomeViewed();
    } catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        error: 'ERROR PRODUCTOS: $e',
      );
    }
  }

  Future<void> _loadProductsForCategory(
    String categoryId,
    String? subcategoryId,
  ) async {
    try {
      final page = await _fs.fetchProducts(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
      );
      state = state.copyWith(
        products: page.products,
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
        isLoadingProducts: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        error: 'ERROR PRODUCTOS: $e',
      );
    }
  }
}

final storeControllerProvider =
    StateNotifierProvider<StoreController, StoreState>((ref) {
  return StoreController(
    firestore: ref.watch(firestoreServiceProvider),
    analytics: ref.watch(analyticsServiceProvider),
  );
});