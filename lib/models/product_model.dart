import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.categoryIds, // <-- AHORA ES UNA LISTA
    required this.images,
    this.subcategoryIds = const [], // <-- AHORA ES UNA LISTA
    this.compareAtPrice,
    this.stock = 0,
    this.isFeatured = false,
    this.isFeaturedGeneral = false,
    this.isFeaturedInCategories = const [],
    this.isActive = true,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final int price;
  final int? compareAtPrice;
  final List<String> categoryIds;
  final List<String> subcategoryIds;
  final List<String> images;
  final int stock;
  final bool isFeatured;
  final bool isFeaturedGeneral;
  final List<String> isFeaturedInCategories;
  final bool isActive;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  static String buildSearchTitle(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n');
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product.fromMap(doc.id, data);
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    // Retrocompatibilidad: si el producto es viejo y tiene categoryId (String), lo pasamos a Lista.
    List<String> cats = [];
    if (map['categoryIds'] != null) {
      cats = (map['categoryIds'] as List).whereType<String>().toList();
    } else if (map['categoryId'] != null) {
      cats = [map['categoryId'] as String];
    }

    List<String> subs = [];
    if (map['subcategoryIds'] != null) {
      subs = (map['subcategoryIds'] as List).whereType<String>().toList();
    } else if (map['subcategoryId'] != null) {
      subs = [map['subcategoryId'] as String];
    }

    return Product(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      compareAtPrice: (map['compareAtPrice'] as num?)?.toInt(),
      categoryIds: cats,
      subcategoryIds: subs,
      images: (map['images'] as List?)?.whereType<String>().toList() ?? const [],
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      isFeatured: map['isFeatured'] as bool? ?? false,
      isFeaturedGeneral: map['isFeaturedGeneral'] as bool? ?? false,
      isFeaturedInCategories: (map['isFeaturedInCategories'] as List?)?.whereType<String>().toList() ?? const [],
      isActive: map['isActive'] as bool? ?? true,
      tags: (map['tags'] as List?)?.whereType<String>().toList() ?? const [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'price': price,
        'compareAtPrice': compareAtPrice,
        'categoryIds': categoryIds,
        'subcategoryIds': subcategoryIds,
        'images': images,
        'stock': stock,
        'isFeatured': isFeatured,
        'isFeaturedGeneral': isFeaturedGeneral,
        'isFeaturedInCategories': isFeaturedInCategories,
        'isActive': isActive,
        'tags': tags,
        'searchTitle': buildSearchTitle(title),
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Product copyWith({
    String? title,
    String? description,
    int? price,
    int? compareAtPrice,
    List<String>? categoryIds,
    List<String>? subcategoryIds,
    List<String>? images,
    int? stock,
    bool? isFeatured,
    bool? isFeaturedGeneral,
    List<String>? isFeaturedInCategories,
    bool? isActive,
    List<String>? tags,
  }) =>
      Product(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        price: price ?? this.price,
        compareAtPrice: compareAtPrice ?? this.compareAtPrice,
        categoryIds: categoryIds ?? this.categoryIds,
        subcategoryIds: subcategoryIds ?? this.subcategoryIds,
        images: images ?? this.images,
        stock: stock ?? this.stock,
        isFeatured: isFeatured ?? this.isFeatured,
        isFeaturedGeneral: isFeaturedGeneral ?? this.isFeaturedGeneral,
        isFeaturedInCategories: isFeaturedInCategories ?? this.isFeaturedInCategories,
        isActive: isActive ?? this.isActive,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}