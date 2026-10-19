import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pendientePago('pendiente_pago', 'Pendiente de pago'),
  pagado('pagado', 'Pagado'),
  comprandoProveedor('comprando_proveedor', 'Comprando al proveedor'),
  listoDespacho('listo_despacho', 'Listo para despachar'),
  despachado('despachado', 'Despachado'),
  entregado('entregado', 'Entregado'),
  cancelado('cancelado', 'Cancelado');

  const OrderStatus(this.value, this.label);
  final String value;
  final String label;

  static OrderStatus fromValue(String? v) => OrderStatus.values.firstWhere(
        (s) => s.value == v,
        orElse: () => OrderStatus.pendientePago,
      );
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.suggestedProvider, // <-- NUEVO CAMPO
  });

  final String productId;
  final String title;
  final int price;
  final int quantity;
  final String? imageUrl;
  final String? suggestedProvider; // <-- NUEVO CAMPO

  int get lineTotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: map['imageUrl'] as String?,
        suggestedProvider: map['suggestedProvider'] as String?, // <-- NUEVO CAMPO
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'suggestedProvider': suggestedProvider, // <-- NUEVO CAMPO
      };
}

class Order {
  const Order({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.department,
    required this.city,
    required this.neighborhood,
    required this.street1,
    required this.locationType,
    required this.items,
    required this.total,
    required this.status,
    this.street2,
    this.reference,
    this.googleMapsLink,
    this.subtotal = 0,
    this.shippingCost = 0,
    this.discount = 0,
    this.couponCode,
    this.holderName,
    this.sourceBank,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.confirmedByUid,
    this.supplierCost = 0,
    this.realShippingCost = 0,
  });

  final String id;
  final String customerName;
  final String phone;
  final String department;
  final String city;
  final String neighborhood;
  final String street1;
  final String? street2;
  final String locationType;
  final String? reference;
  final String? googleMapsLink;
  
  final List<OrderItem> items;
  final int subtotal;
  final int shippingCost;
  final int discount;
  final String? couponCode;
  final int total;
  final OrderStatus status;
  final String? holderName;
  final String? sourceBank;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final String? confirmedByUid;
  final int supplierCost;
  final int realShippingCost;

  int get itemCount => items.fold(0, (sum, it) => sum + it.quantity);

  int get netProfit => total - supplierCost - realShippingCost;

  String get shortId =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Order.fromMap(doc.id, data);
  }

  factory Order.fromMap(String id, Map<String, dynamic> map) => Order(
        id: id,
        customerName: map['customerName'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        department: map['department'] as String? ?? '',
        city: map['city'] as String? ?? '',
        neighborhood: map['neighborhood'] as String? ?? '',
        street1: map['street1'] as String? ?? '',
        street2: map['street2'] as String?,
        locationType: map['locationType'] as String? ?? 'Casa',
        reference: map['reference'] as String?,
        googleMapsLink: map['googleMapsLink'] as String?,
        items: ((map['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
        shippingCost: (map['shippingCost'] as num?)?.toInt() ?? 0,
        discount: (map['discount'] as num?)?.toInt() ?? 0,
        couponCode: map['couponCode'] as String?,
        total: (map['total'] as num?)?.toInt() ?? 0,
        status: OrderStatus.fromValue(map['status'] as String?),
        holderName: map['holderName'] as String?,
        sourceBank: map['sourceBank'] as String?,
        notes: map['notes'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
        paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
        confirmedByUid: map['confirmedByUid'] as String?,
        supplierCost: (map['supplierCost'] as num?)?.toInt() ?? 0,
        realShippingCost: (map['realShippingCost'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'customerName': customerName,
        'phone': phone,
        'department': department,
        'city': city,
        'neighborhood': neighborhood,
        'street1': street1,
        'street2': street2,
        'locationType': locationType,
        'reference': reference,
        'googleMapsLink': googleMapsLink,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'shippingCost': shippingCost,
        'discount': discount,
        'couponCode': couponCode,
        'total': total,
        'status': status.value,
        'holderName': holderName,
        'sourceBank': sourceBank,
        'notes': notes,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
        'confirmedByUid': confirmedByUid,
        'supplierCost': supplierCost,
        'realShippingCost': realShippingCost,
      };

  Order copyWith({
    String? customerName,
    String? phone,
    String? department,
    String? city,
    String? neighborhood,
    String? street1,
    String? street2,
    String? locationType,
    String? reference,
    String? googleMapsLink,
    List<OrderItem>? items,
    int? subtotal,
    int? shippingCost,
    int? discount,
    String? couponCode,
    int? total,
    OrderStatus? status,
    String? holderName,
    String? sourceBank,
    String? notes,
    DateTime? paidAt,
    String? confirmedByUid,
    int? supplierCost,
    int? realShippingCost,
  }) =>
      Order(
        id: id,
        customerName: customerName ?? this.customerName,
        phone: phone ?? this.phone,
        department: department ?? this.department,
        city: city ?? this.city,
        neighborhood: neighborhood ?? this.neighborhood,
        street1: street1 ?? this.street1,
        street2: street2 ?? this.street2,
        locationType: locationType ?? this.locationType,
        reference: reference ?? this.reference,
        googleMapsLink: googleMapsLink ?? this.googleMapsLink,
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        shippingCost: shippingCost ?? this.shippingCost,
        discount: discount ?? this.discount,
        couponCode: couponCode ?? this.couponCode,
        total: total ?? this.total,
        status: status ?? this.status,
        holderName: holderName ?? this.holderName,
        sourceBank: sourceBank ?? this.sourceBank,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
        paidAt: paidAt ?? this.paidAt,
        confirmedByUid: confirmedByUid ?? this.confirmedByUid,
        supplierCost: supplierCost ?? this.supplierCost,
        realShippingCost: realShippingCost ?? this.realShippingCost,
      );
}