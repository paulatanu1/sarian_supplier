import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/helpers.dart';

class OrderItem {
  final String productId;
  final String productName;
  final String composition;
  final String company;
  final String? imageUrl;
  final int    quantity;
  final double price;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.composition,
    required this.company,
    this.imageUrl,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    productId:   m['productId']   ?? '',
    productName: m['productName'] ?? '',
    composition: m['composition'] ?? '',
    company:     m['company']     ?? '',
    imageUrl:    m['imageUrl'],
    quantity:    (m['quantity']   ?? 1).toInt(),
    price:       (m['price']      ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'productId':   productId,
    'productName': productName,
    'composition': composition,
    'company':     company,
    'imageUrl':    imageUrl,
    'quantity':    quantity,
    'price':       price,
  };
}

class StatusEvent {
  final String   status;
  final DateTime timestamp;
  final String?  note;

  const StatusEvent({required this.status, required this.timestamp, this.note});

  factory StatusEvent.fromMap(Map<String, dynamic> m) => StatusEvent(
    status:    m['status']    ?? '',
    timestamp: tsToDate(m['timestamp']) ?? DateTime.now(),
    note:      m['note'],
  );

  Map<String, dynamic> toMap() => {
    'status':    status,
    'timestamp': Timestamp.fromDate(timestamp),
    'note':      note,
  };
}

class OrderModel {
  final String      id;
  final String      orderNumber;
  final String      userId;
  final String      userName;
  final String      shopName;
  final String      phone;
  final List<OrderItem>   items;
  final String      status;
  final double      totalAmount;
  final String?     notes;
  final List<StatusEvent> statusHistory;
  final DateTime    createdAt;
  final DateTime?   updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.shopName,
    required this.phone,
    required this.items,
    required this.status,
    required this.totalAmount,
    this.notes,
    required this.statusHistory,
    required this.createdAt,
    this.updatedAt,
  });

  int get totalItems => items.fold(0, (s, i) => s + i.quantity);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawItems   = (d['items']         as List<dynamic>?) ?? [];
    final rawHistory = (d['statusHistory'] as List<dynamic>?) ?? [];
    return OrderModel(
      id:            doc.id,
      orderNumber:   d['orderNumber']  ?? '',
      userId:        d['userId']       ?? '',
      userName:      d['userName']     ?? '',
      shopName:      d['shopName']     ?? '',
      phone:         d['phone']        ?? '',
      items:         rawItems.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)).toList(),
      status:        d['status']       ?? 'pending',
      totalAmount:   (d['totalAmount'] ?? 0).toDouble(),
      notes:         d['notes'],
      statusHistory: rawHistory.map((e) => StatusEvent.fromMap(e as Map<String, dynamic>)).toList(),
      createdAt:     tsToDate(d['createdAt']) ?? DateTime.now(),
      updatedAt:     tsToDate(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'orderNumber':   orderNumber,
    'userId':        userId,
    'userName':      userName,
    'shopName':      shopName,
    'phone':         phone,
    'items':         items.map((e) => e.toMap()).toList(),
    'status':        status,
    'totalAmount':   totalAmount,
    'notes':         notes,
    'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
    'createdAt':     FieldValue.serverTimestamp(),
    'updatedAt':     FieldValue.serverTimestamp(),
  };

  OrderModel copyWith({String? status, List<StatusEvent>? statusHistory}) => OrderModel(
    id:            id,
    orderNumber:   orderNumber,
    userId:        userId,
    userName:      userName,
    shopName:      shopName,
    phone:         phone,
    items:         items,
    status:        status        ?? this.status,
    totalAmount:   totalAmount,
    notes:         notes,
    statusHistory: statusHistory ?? this.statusHistory,
    createdAt:     createdAt,
    updatedAt:     DateTime.now(),
  );
}
