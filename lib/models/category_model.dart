import 'package:cloud_firestore/cloud_firestore.dart';

class Subcategory {
  const Subcategory({
    required this.id,
    required this.name,
    required this.slug,
    this.orderIndex = 0,
  });

  final String id;
  final String name;
  final String slug;
  final int orderIndex;

  factory Subcategory.fromMap(Map<String, dynamic> map) => Subcategory(
        id:         map['id']         as String? ?? '',
        name:       map['name']       as String? ?? '',
        slug:       map['slug']       as String? ?? '',
        orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'slug': slug,
        'orderIndex': orderIndex,
      };

  Subcategory copyWith({String? name, String? slug, int? orderIndex}) =>
      Subcategory(
        id: id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        orderIndex: orderIndex ?? this.orderIndex,
      );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    this.heroImage,
    this.orderIndex = 0,
    this.isActive = true,
    this.subcategories = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String icon;
  final String? heroImage;
  final int orderIndex;
  final bool isActive;
  final List<Subcategory> subcategories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Category.fromMap(doc.id, data);
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    final rawSubs = (map['subcategories'] as List?) ?? const [];
    return Category(
      id: id,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
      heroImage: map['heroImage'] as String?,
      orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      subcategories: rawSubs
          .whereType<Map>()
          .map((e) => Subcategory.fromMap(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'slug': slug,
        'icon': icon,
        'heroImage': heroImage,
        'orderIndex': orderIndex,
        'isActive': isActive,
        'subcategories': subcategories.map((e) => e.toMap()).toList(),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Category copyWith({
    String? name,
    String? slug,
    String? icon,
    String? heroImage,
    int? orderIndex,
    bool? isActive,
    List<Subcategory>? subcategories,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        icon: icon ?? this.icon,
        heroImage: heroImage ?? this.heroImage,
        orderIndex: orderIndex ?? this.orderIndex,
        isActive: isActive ?? this.isActive,
        subcategories: subcategories ?? this.subcategories,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}