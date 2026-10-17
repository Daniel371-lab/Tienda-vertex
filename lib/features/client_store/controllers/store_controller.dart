import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../../../services/firebase/firestore_service.dart';

enum HomeMode {
  general,
  explore,
  specialized,
  subcategory,
}

class StoreState {
  const StoreState({
    this.mode = HomeMode.general,
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

  final HomeMode mode;
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

  bool get showSearchAndFilters => 
      mode == HomeMode.explore || mode == HomeMode.subcategory;

  bool get showSubcategoriesInDrawer =>
      mode == HomeMode.specialized || mode == HomeMode.subcategory;

  List<Product> get visibleProducts {
    if (selectedSubcategoryId == null) return products;
    return products
        .where((p) => p.subcategoryId == selectedSubcategoryId)
        .toList();
  }

  bool get hasProducts => visibleProducts.isNotEmpty;

  StoreState copyWith({
    HomeMode? mode,
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
      mode: mode ?? this.mode,
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
      for (final c in cats) {
        FirestoreService.registerCategorySlug(c.id, c.slug);
      }
      state = state.copyWith(categories: cats, isLoadingCategories: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        error: 'No pudimos cargar las categorías.',
      );
    }
  }

  Future<void> applyMode({
    required HomeMode mode,
    String? categorySlug,
    String? exploreCategorySlug,
    String? subcategorySlug,
  }) async {
    state = state.copyWith(
      mode: mode,
      products: const [],
      lastDoc: null,
      hasMore: false,
      isLoadingProducts: true,
      clearError: true,
    );

    switch (mode) {
      case HomeMode.general:
        await _loadGeneral();
        break;
      case HomeMode.explore:
        await _loadExplore(exploreCategorySlug, subcategorySlug);
        break;
      case HomeMode.specialized:
        await _loadSpecialized(categorySlug);
        break;
      case HomeMode.subcategory:
        await _loadSubcategory(categorySlug, subcategorySlug);
        break;
    }
  }

  /// Carga productos para la vista de búsqueda según el contexto.
  Future<void> loadSearchContext({
    String? categorySlug,
    String? subcategorySlug,
  }) async {
    state = state.copyWith(
      isLoadingProducts: true,
      clearError: true,
      products: const [],
    );

    try {
      if (categorySlug == null) {
        // Búsqueda general: todos los productos
        final products = await _fs.fetchAllActiveProducts();
        state = state.copyWith(
          products: products,
          isLoadingProducts: false,
        );
        return;
      }

      // Búsqueda en categoría
      final category = await _resolveCategory(categorySlug);
      if (category == null) {
        final products = await _fs.fetchAllActiveProducts();
        state = state.copyWith(products: products, isLoadingProducts: false);
        return;
      }

      if (subcategorySlug == null) {
        // Toda la categoría
        final page = await _fs.fetchAllByCategory(categoryId: category.id);
        state = state.copyWith(
          products: page.products,
          isLoadingProducts: false,
        );
        return;
      }

      // Subcategoría específica
      Subcategory? sub;
      try {
        sub = category.subcategories.firstWhere((s) => s.slug == subcategorySlug);
      } catch (_) {
        sub = null;
      }

      if (sub == null) {
        final page = await _fs.fetchAllByCategory(categoryId: category.id);
        state = state.copyWith(
          products: page.products,
          isLoadingProducts: false,
        );
        return;
      }

      final page = await _fs.fetchAllBySubcategory(
        categoryId: category.id,
        subcategoryId: sub.id,
      );
      state = state.copyWith(
        products: page.products,
        isLoadingProducts: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        error: 'Error al buscar productos.',
      );
    }
  }

  Future<void> _loadGeneral() async {
    state = state.copyWith(
      clearActiveCategory: true,
      clearActiveSubcategory: true,
    );
    try {
      final products = await _fs.fetchFeaturedGeneral(limit: 10);
      state = state.copyWith(products: products, isLoadingProducts: false);
      await _analytics.logHomeViewed();
    } catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        error: 'No pudimos cargar los productos.',
      );
    }
  }

  Future<void> _loadExplore(String? categorySlug, String? subcategorySlug) async {
    if (categorySlug == null) {
      await _loadGeneral();
      return;
    }
    final category = await _resolveCategory(categorySlug);
    if (category == null) {
      await _loadGeneral();
      return;
    }
    
    Subcategory? sub;
    if (subcategorySlug != null) {
      try {
        sub = category.subcategories.firstWhere((s) => s.slug == subcategorySlug);
      } catch (_) {
        sub = null;
      }
    }

    state = state.copyWith(
      activeCategory: category,
      activeSubcategory: sub,
      selectedSubcategoryId: sub?.id,
    );

    try {
      final page = await _fs.fetchAllByCategory(categoryId: category.id);
      state = state.copyWith(
        products: page.products,
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
        isLoadingProducts: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        error: 'No pudimos cargar los productos.',
      );
    }
  }

  Future<void> _loadSpecialized(String? categorySlug) async {
    if (categorySlug == null) {
      await _loadGeneral();
      return;
    }
    final category = await _resolveCategory(categorySlug);
    if (category == null) {
      await _loadGeneral();
      return;
    }
    state = state.copyWith(
      activeCategory: category,
      clearActiveSubcategory: true,
      clearSelectedSubcategory: true,
    );
    try {
      final products = await _fs.fetchFeaturedByCategory(
        categoryId: category.id,
        limit: 10,
      );
      state = state.copyWith(products: products, isLoadingProducts: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        error: 'No pudimos cargar los productos.',
      );
    }
  }

  Future<void> _loadSubcategory(
    String? categorySlug,
    String? subcategorySlug,
  ) async {
    if (categorySlug == null) {
      await _loadGeneral();
      return;
    }
    final category = await _resolveCategory(categorySlug);
    if (category == null) {
      await _loadGeneral();
      return;
    }

    if (subcategorySlug == 'todos') {
      state = state.copyWith(
        activeCategory: category,
        clearActiveSubcategory: true,
        clearSelectedSubcategory: true,
      );
      try {
        final page = await _fs.fetchAllByCategory(categoryId: category.id);
        state = state.copyWith(
          products: page.products,
          lastDoc: page.lastDoc,
          hasMore: page.hasMore,
          isLoadingProducts: false,
        );
      } catch (e) {
        state = state.copyWith(
          isLoadingProducts: false,
          error: 'No pudimos cargar los productos.',
        );
      }
      return;
    }

    Subcategory? sub;
    if (subcategorySlug != null) {
      try {
        sub = category.subcategories.firstWhere((s) => s.slug == subcategorySlug);
      } catch (_) {
        sub = null;
      }
    }
    state = state.copyWith(
      activeCategory: category,
      activeSubcategory: sub,
      selectedSubcategoryId: sub?.id,
    );
    try {
      final page = await _fs.fetchAllBySubcategory(
        categoryId: category.id,
        subcategoryId: sub?.id ?? '',
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
        error: 'No pudimos cargar los productos.',
      );
    }
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
    if (state.activeCategory == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final ProductsPage page;
      if (state.mode == HomeMode.subcategory && state.activeSubcategory != null) {
        page = await _fs.fetchAllBySubcategory(
          categoryId: state.activeCategory!.id,
          subcategoryId: state.activeSubcategory!.id,
          startAfter: state.lastDoc,
        );
      } else {
        page = await _fs.fetchAllByCategory(
          categoryId: state.activeCategory!.id,
          startAfter: state.lastDoc,
        );
      }
      state = state.copyWith(
        products: [...state.products, ...page.products],
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<Category?> _resolveCategory(String slug) async {
    final cached = state.categories.where((c) => c.slug == slug).firstOrNull;
    if (cached != null) return cached;
    final fetched = await _fs.findCategoryBySlug(slug);
    if (fetched != null) {
      FirestoreService.registerCategorySlug(fetched.id, fetched.slug);
      state = state.copyWith(categories: [...state.categories, fetched]);
    }
    return fetched;
  }
}

final storeControllerProvider =
    StateNotifierProvider<StoreController, StoreState>((ref) {
  return StoreController(
    firestore: ref.watch(firestoreServiceProvider),
    analytics: ref.watch(analyticsServiceProvider),
  );
});