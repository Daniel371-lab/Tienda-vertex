import 'package:flutter/foundation.dart';

/// Contexto del nicho activo, derivado 100% de la URL.
/// La URL es la única fuente de verdad — esto garantiza que
/// compartir un link restaure el mismo estado visual.
@immutable
class NicheContext {
  const NicheContext({
    this.categorySlug,
    this.subcategorySlug,
    this.searchQuery,
    this.productId,
  });

  final String? categorySlug;
  final String? subcategorySlug;
  final String? searchQuery;
  final String? productId;

  /// Ruta raíz — muestra todos los productos de todos los nichos.
  bool get isGlobal => categorySlug == null && searchQuery == null && productId == null;

  /// Estamos dentro de un nicho específico pero sin subcategoría.
  bool get isNiche => categorySlug != null && subcategorySlug == null;

  /// Estamos dentro de un nicho con subcategoría activa.
  bool get isSubcategory => subcategorySlug != null;

  /// Estamos viendo el detalle de un producto.
  bool get isProductDetail => productId != null;

  /// Estamos en una búsqueda.
  bool get isSearch => searchQuery != null && searchQuery!.isNotEmpty;

  NicheContext copyWith({
    String? categorySlug,
    String? subcategorySlug,
    String? searchQuery,
    String? productId,
    bool clearCategory = false,
    bool clearSubcategory = false,
    bool clearSearch = false,
    bool clearProduct = false,
  }) {
    return NicheContext(
      categorySlug:    clearCategory    ? null : (categorySlug    ?? this.categorySlug),
      subcategorySlug: clearSubcategory ? null : (subcategorySlug ?? this.subcategorySlug),
      searchQuery:     clearSearch      ? null : (searchQuery     ?? this.searchQuery),
      productId:       clearProduct     ? null : (productId       ?? this.productId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NicheContext &&
          runtimeType == other.runtimeType &&
          categorySlug == other.categorySlug &&
          subcategorySlug == other.subcategorySlug &&
          searchQuery == other.searchQuery &&
          productId == other.productId;

  @override
  int get hashCode =>
      Object.hash(categorySlug, subcategorySlug, searchQuery, productId);

  @override
  String toString() =>
      'NicheContext(cat: $categorySlug, sub: $subcategorySlug, '
      'q: $searchQuery, prod: $productId)';
}