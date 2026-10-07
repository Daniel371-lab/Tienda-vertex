import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.images,
    this.compareAtPrice,
    this.subcategoryId,
    this.stock = 0,
    this.isFeatured = false,
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
  final String categoryId;
  final String? subcategoryId;
  final List<String> images;
  final int stock;
  final bool isFeatured;
  final bool isActive;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasDiscount =>
      compareAtPrice != null && compareAtPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product.fromMap(doc.id, data);
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
        id: id,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        compareAtPrice: (map['compareAtPrice'] as num?)?.toInt(),
        categoryId: map['categoryId'] as String? ?? '',
        subcategoryId: map['subcategoryId'] as String?,
        images: (map['images'] as List?)?.whereType<String>().toList() ?? const [],
        stock: (map['stock'] as num?)?.toInt() ?? 0,
        isFeatured: map['isFeatured'] as bool? ?? false,
        isActive: map['isActive'] as bool? ?? true,
        tags: (map['tags'] as List?)?.whereType<String>().toList() ?? const [],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'price': price,
        'compareAtPrice': compareAtPrice,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'images': images,
        'stock': stock,
        'isFeatured': isFeatured,
        'isActive': isActive,
        'tags': tags,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Product copyWith({
    String? title,
    String? description,
    int? price,
    int? compareAtPrice,
    String? categoryId,
    String? subcategoryId,
    List<String>? images,
    int? stock,
    bool? isFeatured,
    bool? isActive,
    List<String>? tags,
  }) =>
      Product(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        price: price ?? this.price,
        compareAtPrice: compareAtPrice ?? this.compareAtPrice,
        categoryId: categoryId ?? this.categoryId,
        subcategoryId: subcategoryId ?? this.subcategoryId,
        images: images ?? this.images,
        stock: stock ?? this.stock,
        isFeatured: isFeatured ?? this.isFeatured,
        isActive: isActive ?? this.isActive,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}