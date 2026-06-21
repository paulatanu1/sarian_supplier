import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String composition;
  final String packSize;
  final String category;
  final String? imageUrl;
  final double mrp;
  final double tradePrice;
  final int stockQty;
  final bool isActive;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.composition,
    required this.packSize,
    required this.category,
    this.imageUrl,
    required this.mrp,
    required this.tradePrice,
    required this.stockQty,
    this.isActive = true,
    required this.updatedAt,
  });

  bool get inStock => stockQty > 0;

  double get margin => mrp > 0 ? ((mrp - tradePrice) / mrp) * 100 : 0;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: d['name'] ?? '',
      composition: d['composition'] ?? '',
      packSize: d['packSize'] ?? '',
      category: d['category'] ?? '',
      imageUrl: d['imageUrl'],
      mrp: (d['mrp'] ?? 0).toDouble(),
      tradePrice: (d['tradePrice'] ?? 0).toDouble(),
      stockQty: (d['stockQty'] ?? 0).toInt(),
      isActive: d['isActive'] ?? true,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'composition': composition,
        'packSize': packSize,
        'category': category,
        'imageUrl': imageUrl,
        'mrp': mrp,
        'tradePrice': tradePrice,
        'stockQty': stockQty,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
