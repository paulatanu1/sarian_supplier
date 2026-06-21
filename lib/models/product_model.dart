import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/helpers.dart';

class ProductModel {
  final String  id;
  final String  name;
  final String  composition;
  final String  company;
  final String  category;
  final String  description;
  final String? imageUrl;
  final double  mrp;
  final double  tradePrice;
  final int     stockQty;
  final bool    isActive;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.composition,
    required this.company,
    required this.category,
    required this.description,
    this.imageUrl,
    required this.mrp,
    required this.tradePrice,
    required this.stockQty,
    required this.isActive,
    required this.updatedAt,
  });

  bool get inStock => stockQty > 0;
  double get margin => mrp > 0 ? ((mrp - tradePrice) / mrp) * 100 : 0;
  String get packSize => '';          // kept for migration compatibility

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id:          doc.id,
      name:        d['name']        ?? '',
      composition: d['composition'] ?? '',
      company:     d['company']     ?? 'Sarian Healthcare',
      category:    d['category']    ?? '',
      description: d['description'] ?? '',
      imageUrl:    d['imageUrl'],
      mrp:         (d['mrp']        ?? 0).toDouble(),
      tradePrice:  (d['tradePrice'] ?? 0).toDouble(),
      stockQty:    (d['stockQty']   ?? 0).toInt(),
      isActive:    d['isActive']    ?? true,
      updatedAt:   tsToDate(d['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name':        name,
    'composition': composition,
    'company':     company,
    'category':    category,
    'description': description,
    'imageUrl':    imageUrl,
    'mrp':         mrp,
    'tradePrice':  tradePrice,
    'stockQty':    stockQty,
    'isActive':    isActive,
    'updatedAt':   FieldValue.serverTimestamp(),
  };

  ProductModel copyWith({
    String?  name,
    String?  composition,
    String?  company,
    String?  category,
    String?  description,
    String?  imageUrl,
    double?  mrp,
    double?  tradePrice,
    int?     stockQty,
    bool?    isActive,
  }) =>
      ProductModel(
        id:          id,
        name:        name        ?? this.name,
        composition: composition ?? this.composition,
        company:     company     ?? this.company,
        category:    category    ?? this.category,
        description: description ?? this.description,
        imageUrl:    imageUrl    ?? this.imageUrl,
        mrp:         mrp         ?? this.mrp,
        tradePrice:  tradePrice  ?? this.tradePrice,
        stockQty:    stockQty    ?? this.stockQty,
        isActive:    isActive    ?? this.isActive,
        updatedAt:   updatedAt,
      );
}
