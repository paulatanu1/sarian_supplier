import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final String packSize;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.packSize,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        packSize: m['packSize'] ?? '',
        quantity: (m['quantity'] ?? 0).toInt(),
        unitPrice: (m['unitPrice'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'packSize': packSize,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

class OrderModel {
  final String id;
  final String supplierId;
  final String supplierName;
  final List<OrderItem> items;
  final String status;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.status,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.deliveredAt,
  });

  int get totalItems => items.fold(0, (acc, i) => acc + i.quantity);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawItems = (d['items'] as List<dynamic>?) ?? [];
    return OrderModel(
      id: doc.id,
      supplierId: d['supplierId'] ?? '',
      supplierName: d['supplierName'] ?? '',
      items: rawItems.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)).toList(),
      status: d['status'] ?? 'pending',
      totalAmount: (d['totalAmount'] ?? 0).toDouble(),
      notes: d['notes'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (d['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'supplierId': supplierId,
        'supplierName': supplierName,
        'items': items.map((e) => e.toMap()).toList(),
        'status': status,
        'totalAmount': totalAmount,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      };

  OrderModel copyWith({String? status, DateTime? deliveredAt}) => OrderModel(
        id: id,
        supplierId: supplierId,
        supplierName: supplierName,
        items: items,
        status: status ?? this.status,
        totalAmount: totalAmount,
        notes: notes,
        createdAt: createdAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );
}
