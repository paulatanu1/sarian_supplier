import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;   // emoji or icon name
  final int    order;
  final bool   isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.order,
    required this.isActive,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id:       doc.id,
      name:     d['name']     ?? '',
      icon:     d['icon']     ?? '💊',
      order:    (d['order']   ?? 0).toInt(),
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':     name,
    'icon':     icon,
    'order':    order,
    'isActive': isActive,
  };
}

/// Default categories seeded into Firestore.
const kDefaultCategories = [
  {'name': 'Antibiotics',      'icon': '🦠', 'order': 0},
  {'name': 'Pain Relief',      'icon': '💊', 'order': 1},
  {'name': 'Cardiac',          'icon': '❤️', 'order': 2},
  {'name': 'Diabetes',         'icon': '🩸', 'order': 3},
  {'name': 'Vitamins',         'icon': '🌿', 'order': 4},
  {'name': 'Syrups',           'icon': '🍶', 'order': 5},
  {'name': 'Injections',       'icon': '💉', 'order': 6},
  {'name': 'Drops',            'icon': '💧', 'order': 7},
  {'name': 'Gynec Range',      'icon': '🌸', 'order': 8},
  {'name': 'Anti-Allergics',   'icon': '🛡️', 'order': 9},
  {'name': 'Ayurvedic',        'icon': '🌱', 'order': 10},
  {'name': 'Digestive',        'icon': '🫁', 'order': 11},
  {'name': 'Eye & Ear',        'icon': '👁️', 'order': 12},
  {'name': 'Injectables',      'icon': '🔬', 'order': 13},
  {'name': 'Others',           'icon': '🏥', 'order': 14},
];
