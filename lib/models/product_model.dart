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
    required this.isActive,
    required this.updatedAt,
  });

  bool get inStock => true;

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
        isActive:    isActive    ?? this.isActive,
        updatedAt:   updatedAt,
      );
}
