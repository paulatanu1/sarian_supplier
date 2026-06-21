import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/helpers.dart';

class CartItem {
  final String  productId;
  final String  productName;
  final String  composition;
  final String  company;
  final String  category;
  final String? imageUrl;
  final int     quantity;
  final double  price;       // tradePrice at time of adding
  final DateTime updatedAt;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.composition,
    required this.company,
    required this.category,
    this.imageUrl,
    required this.quantity,
    required this.price,
    required this.updatedAt,
  });

  double get subtotal => quantity * price;

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CartItem(
      productId:   doc.id,
      productName: d['productName'] ?? '',
      composition: d['composition'] ?? '',
      company:     d['company']     ?? '',
      category:    d['category']    ?? '',
      imageUrl:    d['imageUrl'],
      quantity:    (d['quantity']   ?? 1).toInt(),
      price:       (d['price']      ?? 0).toDouble(),
      updatedAt:   tsToDate(d['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'composition': composition,
    'company':     company,
    'category':    category,
    'imageUrl':    imageUrl,
    'quantity':    quantity,
    'price':       price,
    'updatedAt':   FieldValue.serverTimestamp(),
  };

  CartItem copyWith({int? quantity, double? price}) => CartItem(
    productId:   productId,
    productName: productName,
    composition: composition,
    company:     company,
    category:    category,
    imageUrl:    imageUrl,
    quantity:    quantity ?? this.quantity,
    price:       price    ?? this.price,
    updatedAt:   DateTime.now(),
  );
}
