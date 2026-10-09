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
  });

  final String productId;
  final String title;
  final int price;
  final int quantity;
  final String? imageUrl;

  int get lineTotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: map['imageUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };
}

class Order {
  const Order({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.department,
    required this.city,
    required this.address,
    required this.items,
    required this.total,
    required this.status,
    this.subtotal = 0,
    this.discount = 0,
    this.couponCode,
    this.holderName,
    this.sourceBank,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.confirmedByUid,
  });

  final String id;
  final String customerName;
  final String phone;
  final String department;
  final String city;
  final String address;
  final List<OrderItem> items;
  final int subtotal;
  final int discount;
  final String? couponCode;
  final int total;
  final OrderStatus status;

  /// Nombre del titular de la cuenta bancaria desde la que transfirió.
  final String? holderName;

  /// Banco desde el que realizó la transferencia.
  final String? sourceBank;

  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final String? confirmedByUid;

  int get itemCount => items.fold(0, (sum, it) => sum + it.quantity);

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
        address: map['address'] as String? ?? '',
        items: ((map['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
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
      );

  Map<String, dynamic> toMap() => {
        'customerName': customerName,
        'phone': phone,
        'department': department,
        'city': city,
        'address': address,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
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
      };

  Order copyWith({
    String? customerName,
    String? phone,
    String? department,
    String? city,
    String? address,
    List<OrderItem>? items,
    int? subtotal,
    int? discount,
    String? couponCode,
    int? total,
    OrderStatus? status,
    String? holderName,
    String? sourceBank,
    String? notes,
    DateTime? paidAt,
    String? confirmedByUid,
  }) =>
      Order(
        id: id,
        customerName: customerName ?? this.customerName,
        phone: phone ?? this.phone,
        department: department ?? this.department,
        city: city ?? this.city,
        address: address ?? this.address,
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
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
      );
}