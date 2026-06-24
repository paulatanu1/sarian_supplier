import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String shortName; // shown in the narrow sidebar
  final String icon;      // emoji or icon name
  final int    order;
  final bool   isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.icon,
    required this.order,
    required this.isActive,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['name'] ?? '';
    return CategoryModel(
      id:        doc.id,
      name:      name,
      shortName: d['shortName'] ?? name, // fall back to full name
      icon:      d['icon']      ?? '💊',
      order:     (d['order']    ?? 0).toInt(),
      isActive:  d['isActive']  ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':      name,
    'shortName': shortName,
    'icon':      icon,
    'order':     order,
    'isActive':  isActive,
  };
}

/// Default categories seeded into Firestore.
/// `name` is the full pharmaceutical group label; `shortName` is a 1-2 word
/// label used in the narrow left-side product browser sidebar.
const kDefaultCategories = [
  {'name': 'Antibacterials / Antibiotics',            'shortName': 'Anti-\nbiotics',    'icon': '🦠', 'order': 0},
  {'name': 'Antimicrobials / Anti-Fungals',           'shortName': 'Anti-\nFungal',     'icon': '🧫', 'order': 1},
  {'name': 'Antidiarrheals',                          'shortName': 'Anti-\nDiarrheal',  'icon': '💩', 'order': 2},
  {'name': 'G.I. Anti-Infectives / Anthelmintics',    'shortName': 'G.I. /\nWorms',     'icon': '🫃', 'order': 3},
  {'name': 'Analgesics / Anti-Inflammatory / Nsaids', 'shortName': 'Analgesic\nNSAIDs', 'icon': '💊', 'order': 4},
  {'name': 'Anti-Spasmodic',                          'shortName': 'Anti-\nSpasmodic',  'icon': '🌀', 'order': 5},
  {'name': 'Anti-Hypertensives / Cardiovascular',     'shortName': 'Cardio\n/ BP',      'icon': '❤️', 'order': 6},
  {'name': 'Anti-Diabetics',                          'shortName': 'Anti-\nDiabetic',   'icon': '🩸', 'order': 7},
  {'name': 'Vitamins / Minerals / Nutraceuticals',    'shortName': 'Vitamins\nMinerals','icon': '🌿', 'order': 8},
  {'name': 'Pediatric / Syrups & Suspensions',        'shortName': 'Pediatric\n/ Syrup','icon': '🍶', 'order': 9},
  {'name': 'Injections / Injectables',                'shortName': 'Injections',        'icon': '💉', 'order': 10},
  {'name': 'Ophthalmic / Otic / Nasal Drops',         'shortName': 'Eye/Ear\nDrops',    'icon': '💧', 'order': 11},
  {'name': 'Gynaecological / Obstetric',              'shortName': 'Gynec\n/ Obs',      'icon': '🌸', 'order': 12},
  {'name': 'Anti-Histamines / Anti-Allergics',        'shortName': 'Anti-\nAllergic',   'icon': '🛡️', 'order': 13},
  {'name': 'Ayurvedic / Herbal',                      'shortName': 'Ayurvedic\n/ Herbal','icon': '🌱', 'order': 14},
  {'name': 'Anti-Ulcerants / Antacids / Ppis',        'shortName': 'Acidity\n/ Ulcer',  'icon': '🫁', 'order': 15},
  {'name': 'Dermatological / Topical',                'shortName': 'Derma /\nTopical',  'icon': '🧴', 'order': 16},
  {'name': 'Respiratory / Anti-Asthmatics',           'shortName': 'Respir-\natory',    'icon': '🌬️', 'order': 17},
  {'name': 'General / Otc',                           'shortName': 'General\n/ OTC',    'icon': '🏥', 'order': 18},
];
