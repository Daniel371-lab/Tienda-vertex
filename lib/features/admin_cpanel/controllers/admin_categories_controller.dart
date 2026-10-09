import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../services/firebase/firebase_providers.dart';

class AdminCategoriesState {
  const AdminCategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Category> categories;
  final bool isLoading;
  final String? error;

  AdminCategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AdminCategoriesState(
        categories: categories ?? this.categories,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AdminCategoriesController extends StateNotifier<AdminCategoriesState> {
  AdminCategoriesController(this._ref) : super(const AdminCategoriesState()) {
    load();
  }

  final Ref _ref;

  // ── LECTURA ───────────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final db = _ref.read(firestoreInstanceProvider);
      final snap = await db.collection('categories').get();
      final cats = snap.docs
          .map((d) => Category.fromFirestore(d))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      state = state.copyWith(categories: cats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar categorías: $e',
      );
    }
  }

  // ── CREAR / EDITAR CATEGORÍA ──────────────────────────────

  Future<bool> createCategory({
    required String name,
    required String slug,
    required String icon,
    String? heroImage,
  }) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);

      final exists = await db
          .collection('categories')
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();
      if (exists.docs.isNotEmpty) {
        state = state.copyWith(
          error: 'Ya existe una categoría con el slug "$slug".',
        );
        return false;
      }

      final orderIndex = state.categories.isEmpty
          ? 1
          : state.categories
                  .map((c) => c.orderIndex)
                  .reduce((a, b) => a > b ? a : b) +
              1;

      final ref = db.collection('categories').doc();
      await ref.set({
        'name': name,
        'slug': slug,
        'icon': icon,
        'heroImage': heroImage,
        'orderIndex': orderIndex,
        'isActive': true,
        'subcategories': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo crear: $e');
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      await db.collection('categories').doc(category.id).update({
        'name': category.name,
        'slug': category.slug,
        'icon': category.icon,
        'heroImage': category.heroImage,
        'isActive': category.isActive,
        'subcategories': category.subcategories.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo actualizar: $e');
      return false;
    }
  }

  // ── ELIMINAR CATEGORÍA ────────────────────────────────────

  Future<int> countProductsInCategory(String categoryId) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);
      final snap = await db
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> deleteCategory({
    required Category category,
    String? reassignToCategoryId,
    bool archiveProducts = false,
  }) async {
    try {
      final db = _ref.read(firestoreInstanceProvider);

      final productsSnap = await db
          .collection('products')
          .where('categoryId', isEqualTo: category.id)
          .get();

      if (productsSnap.docs.isNotEmpty) {
        final batch = db.batch();
        for (final doc in productsSnap.docs) {
          if (reassignToCategoryId != null) {
            batch.update(doc.reference, {
              'categoryId': reassignToCategoryId,
              'subcategoryId': null,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else if (archiveProducts) {
            batch.update(doc.reference, {
              'isActive': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        await batch.commit();
      }

      await db.collection('categories').doc(category.id).delete();

      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo eliminar: $e');
      return false;
    }
  }

  // ── REORDENAR CATEGORÍAS ──────────────────────────────────

  Future<bool> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= state.categories.length ||
        newIndex < 0 ||
        newIndex > state.categories.length) {
      return false;
    }

    if (newIndex > oldIndex) newIndex -= 1;

    final list = [...state.categories];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    state = state.copyWith(categories: list);

    try {
      final db = _ref.read(firestoreInstanceProvider);
      final batch = db.batch();
      for (var i = 0; i < list.length; i++) {
        batch.update(
          db.collection('categories').doc(list[i].id),
          {'orderIndex': i + 1},
        );
      }
      await batch.commit();
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo reordenar: $e');
      await load();
      return false;
    }
  }

  // ── SUBCATEGORÍAS ─────────────────────────────────────────

  Future<bool> addSubcategory({
    required Category category,
    required String name,
    required String slug,
  }) async {
    final existing = category.subcategories
        .where((s) => s.slug == slug)
        .isNotEmpty;
    if (existing) {
      state = state.copyWith(
        error: 'Ya existe una subcategoría con ese slug.',
      );
      return false;
    }

    final newSub = Subcategory(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      slug: slug,
      orderIndex: category.subcategories.isEmpty
          ? 1
          : category.subcategories
                  .map((s) => s.orderIndex)
                  .reduce((a, b) => a > b ? a : b) +
              1,
    );

    final updated = category.copyWith(
      subcategories: [...category.subcategories, newSub],
    );

    return updateCategory(updated);
  }

  Future<bool> updateSubcategory({
    required Category category,
    required Subcategory subcategory,
  }) async {
    // Validar slug único dentro de la categoría (excluyendo la actual).
    final conflict = category.subcategories
        .where((s) => s.id != subcategory.id && s.slug == subcategory.slug)
        .isNotEmpty;
    if (conflict) {
      state = state.copyWith(
        error: 'Ya existe otra subcategoría con ese slug.',
      );
      return false;
    }

    final subs = category.subcategories
        .map((s) => s.id == subcategory.id ? subcategory : s)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return updateCategory(category.copyWith(subcategories: subs));
  }

  Future<bool> deleteSubcategory({
    required Category category,
    required String subcategoryId,
  }) async {
    final subs = category.subcategories
        .where((s) => s.id != subcategoryId)
        .toList();
    return updateCategory(category.copyWith(subcategories: subs));
  }

  /// Reordena subcategorías con drag & drop.
  Future<bool> reorderSubcategories({
    required Category category,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 ||
        oldIndex >= category.subcategories.length ||
        newIndex < 0 ||
        newIndex > category.subcategories.length) {
      return false;
    }

    if (newIndex > oldIndex) newIndex -= 1;

    final subs = [...category.subcategories];
    final item = subs.removeAt(oldIndex);
    subs.insert(newIndex, item);

    // Reasignamos orderIndex secuencialmente.
    final reindexed = <Subcategory>[];
    for (var i = 0; i < subs.length; i++) {
      reindexed.add(subs[i].copyWith(orderIndex: i + 1));
    }

    return updateCategory(category.copyWith(subcategories: reindexed));
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final adminCategoriesControllerProvider = StateNotifierProvider<
    AdminCategoriesController, AdminCategoriesState>((ref) {
  return AdminCategoriesController(ref);
});