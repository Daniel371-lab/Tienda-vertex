import 'package:cloud_firestore/cloud_firestore.dart';

class StoreSettings {
  const StoreSettings({
    required this.whatsappNumber,
    required this.contactEmail,
    required this.address,
    required this.currencySymbol,
    this.shippingInfo = '',
    this.dropiProxyUrl = '',
    this.updatedAt,
  });

  final String whatsappNumber;
  final String contactEmail;
  final String address;
  final String currencySymbol;
  final String shippingInfo;
  final String dropiProxyUrl;
  final DateTime? updatedAt;

  static const StoreSettings fallback = StoreSettings(
    whatsappNumber: '595981000000',
    contactEmail: 'contacto@tiendavertex.com',
    address: 'Luque · Asunción, Paraguay',
    currencySymbol: '₲',
  );

  factory StoreSettings.fromFirestore(DocumentSnapshot? doc) {
    if (doc == null || !doc.exists) return fallback;
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StoreSettings.fromMap(data);
  }

  factory StoreSettings.fromMap(Map<String, dynamic> map) => StoreSettings(
        whatsappNumber: map['whatsappNumber'] as String? ?? fallback.whatsappNumber,
        contactEmail: map['contactEmail'] as String? ?? fallback.contactEmail,
        address: map['address'] as String? ?? fallback.address,
        currencySymbol: map['currencySymbol'] as String? ?? fallback.currencySymbol,
        shippingInfo: map['shippingInfo'] as String? ?? '',
        dropiProxyUrl: map['dropiProxyUrl'] as String? ?? '',
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'whatsappNumber': whatsappNumber,
        'contactEmail': contactEmail,
        'address': address,
        'currencySymbol': currencySymbol,
        'shippingInfo': shippingInfo,
        'dropiProxyUrl': dropiProxyUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  StoreSettings copyWith({
    String? whatsappNumber,
    String? contactEmail,
    String? address,
    String? currencySymbol,
    String? shippingInfo,
    String? dropiProxyUrl,
  }) =>
      StoreSettings(
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
        contactEmail: contactEmail ?? this.contactEmail,
        address: address ?? this.address,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        shippingInfo: shippingInfo ?? this.shippingInfo,
        dropiProxyUrl: dropiProxyUrl ?? this.dropiProxyUrl,
        updatedAt: updatedAt,
      );
}