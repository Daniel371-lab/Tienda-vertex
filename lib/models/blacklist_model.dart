import 'package:cloud_firestore/cloud_firestore.dart';

class BlacklistEntry {
  const BlacklistEntry({
    required this.id,
    required this.phone,
    required this.reason,
    this.createdAt,
    this.createdByUid,
  });

  final String id;
  final String phone;
  final String reason;
  final DateTime? createdAt;
  final String? createdByUid;

  factory BlacklistEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BlacklistEntry(
      id: doc.id,
      phone: data['phone'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdByUid: data['createdByUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'reason': reason,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'createdByUid': createdByUid,
      };

  /// ID determinístico basado en el teléfono normalizado.
  /// Evita duplicados y permite consulta directa por phone.
  static String buildId(String phone) =>
      'bl_${phone.replaceAll(RegExp(r'[^0-9]'), '')}';
}