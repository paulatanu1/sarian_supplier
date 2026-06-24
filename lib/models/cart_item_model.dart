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
  final DateTime updatedAt;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.composition,
    required this.company,
    required this.category,
    this.imageUrl,
    required this.quantity,
    required this.updatedAt,
  });

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
    'updatedAt':   FieldValue.serverTimestamp(),
  };

  CartItem copyWith({int? quantity}) => CartItem(
    productId:   productId,
    productName: productName,
    composition: composition,
    company:     company,
    category:    category,
    imageUrl:    imageUrl,
    quantity:    quantity ?? this.quantity,
    updatedAt:   DateTime.now(),
  );
}
