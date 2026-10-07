import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pendienteConfirmacion('pendiente_confirmacion', 'Pendiente'),
  confirmado('confirmado', 'Confirmado'),
  despachadoDropi('despachado_dropi', 'Despachado'),
  entregado('entregado', 'Entregado'),
  cancelado('cancelado', 'Cancelado');

  const OrderStatus(this.value, this.label);
  final String value;
  final String label;

  static OrderStatus fromValue(String? v) => OrderStatus.values.firstWhere(
        (s) => s.value == v,
        orElse: () => OrderStatus.pendienteConfirmacion,
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
    this.dropiOrderId,
    this.dropiTrackingNumber,
    this.dropiStatus,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.whatsappConfirmedAt,
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
  final String? dropiOrderId;
  final String? dropiTrackingNumber;
  final String? dropiStatus;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? whatsappConfirmedAt;
  final String? confirmedByUid;

  int get itemCount =>
      items.fold(0, (sum, it) => sum + it.quantity);

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
        dropiOrderId: map['dropiOrderId'] as String?,
        dropiTrackingNumber: map['dropiTrackingNumber'] as String?,
        dropiStatus: map['dropiStatus'] as String?,
        notes: map['notes'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
        whatsappConfirmedAt:
            (map['whatsappConfirmedAt'] as Timestamp?)?.toDate(),
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
        'dropiOrderId': dropiOrderId,
        'dropiTrackingNumber': dropiTrackingNumber,
        'dropiStatus': dropiStatus,
        'notes': notes,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'whatsappConfirmedAt': whatsappConfirmedAt != null
            ? Timestamp.fromDate(whatsappConfirmedAt!)
            : null,
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
    String? dropiOrderId,
    String? dropiTrackingNumber,
    String? dropiStatus,
    String? notes,
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
        dropiOrderId: dropiOrderId ?? this.dropiOrderId,
        dropiTrackingNumber: dropiTrackingNumber ?? this.dropiTrackingNumber,
        dropiStatus: dropiStatus ?? this.dropiStatus,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
        whatsappConfirmedAt: whatsappConfirmedAt,
        confirmedByUid: confirmedByUid,
      );
}