import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.isActive,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.minPurchase = 0,
    this.maxUses = 0,
    this.currentUses = 0,
    this.validFrom,
    this.validUntil,
    this.createdAt,
  });

  final String id;
  final String code;
  final int discountPercent;
  final int discountAmount;
  final int minPurchase;
  final int maxUses;
  final int currentUses;
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? createdAt;

  bool get isExpired =>
      validUntil != null && DateTime.now().isAfter(validUntil!);

  bool get isNotYetValid =>
      validFrom != null && DateTime.now().isBefore(validFrom!);

  bool get isExhausted => maxUses > 0 && currentUses >= maxUses;

  bool get isUsable =>
      isActive && !isExpired && !isNotYetValid && !isExhausted;

  /// Calcula el descuento a aplicar sobre un subtotal.
  int calculateDiscount(int subtotal) {
    if (subtotal < minPurchase) return 0;
    if (discountPercent > 0) return (subtotal * discountPercent / 100).round();
    return discountAmount.clamp(0, subtotal);
  }

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Coupon.fromMap(doc.id, data);
  }

  factory Coupon.fromMap(String id, Map<String, dynamic> map) => Coupon(
        id: id,
        code: (map['code'] as String? ?? '').toUpperCase(),
        discountPercent: (map['discountPercent'] as num?)?.toInt() ?? 0,
        discountAmount: (map['discountAmount'] as num?)?.toInt() ?? 0,
        minPurchase: (map['minPurchase'] as num?)?.toInt() ?? 0,
        maxUses: (map['maxUses'] as num?)?.toInt() ?? 0,
        currentUses: (map['currentUses'] as num?)?.toInt() ?? 0,
        isActive: map['isActive'] as bool? ?? true,
        validFrom: (map['validFrom'] as Timestamp?)?.toDate(),
        validUntil: (map['validUntil'] as Timestamp?)?.toDate(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'code': code.toUpperCase(),
        'discountPercent': discountPercent,
        'discountAmount': discountAmount,
        'minPurchase': minPurchase,
        'maxUses': maxUses,
        'currentUses': currentUses,
        'isActive': isActive,
        'validFrom':
            validFrom != null ? Timestamp.fromDate(validFrom!) : null,
        'validUntil':
            validUntil != null ? Timestamp.fromDate(validUntil!) : null,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}