import 'dart:developer' as dev;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/k.dart';
import '../core/data/sample_products.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductsRepository {
  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // ── Categories ────────────────────────────────────────────────────────
  Stream<List<CategoryModel>> categoriesStream() => _db
      .collection(K.categories)
      .where('isActive', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(CategoryModel.fromFirestore).toList());

  Future<void> seedCategoriesIfEmpty() async {
    try {
      final snap = await _db.collection(K.categories).limit(1).get();
      if (snap.docs.isNotEmpty) {
        dev.log('seedCategories: already populated (${snap.docs.length}+)',
            name: 'categories');
        return;
      }
      dev.log('seedCategories: collection empty, seeding ${kDefaultCategories.length} defaults',
          name: 'categories');
      final batch = _db.batch();
      for (final c in kDefaultCategories) {
        final ref = _db.collection(K.categories).doc();
        batch.set(ref, {...c, 'isActive': true});
      }
      await batch.commit();
      dev.log('seedCategories: ✓ committed ${kDefaultCategories.length} docs',
          name: 'categories');
    } catch (e, st) {
      dev.log('seedCategories: ✗ failed — $e', name: 'categories',
          error: e, stackTrace: st);
    }
  }

  /// Admin-only: wipes the `categories` collection and re-seeds from
  /// [kDefaultCategories]. Returns the number of categories written.
  /// Use when the local default list has been updated and the Firestore
  /// data needs to be brought in sync.
  Future<int> resyncCategories() async {
    final existing = await _db.collection(K.categories).get();
    // Delete in batches to respect the 500-op batch limit.
    for (var i = 0; i < existing.docs.length; i += 400) {
      final chunk = existing.docs.sublist(
          i, i + 400 > existing.docs.length ? existing.docs.length : i + 400);
      final batch = _db.batch();
      for (final d in chunk) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    // Re-seed.
    final batch = _db.batch();
    for (final c in kDefaultCategories) {
      final ref = _db.collection(K.categories).doc();
      batch.set(ref, {...c, 'isActive': true});
    }
    await batch.commit();
    dev.log('resyncCategories: ✓ wrote ${kDefaultCategories.length} categories',
        name: 'categories');
    return kDefaultCategories.length;
  }

  // ── Products ──────────────────────────────────────────────────────────
  Stream<List<ProductModel>> productsStream({String? category}) {
    var q = _db.collection(K.products).where('isActive', isEqualTo: true);
    if (category != null && category.isNotEmpty && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    return q.orderBy('name').snapshots()
        .map((s) => s.docs.map(ProductModel.fromFirestore).toList());
  }

  Stream<List<ProductModel>> allProductsAdminStream() => _db
      .collection(K.products)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromFirestore).toList());

  Stream<ProductModel?> productByIdStream(String id) =>
      _db.collection(K.products).doc(id).snapshots().map(
            (doc) => doc.exists ? ProductModel.fromFirestore(doc) : null,
          );

  Future<List<ProductModel>> searchProducts(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snap = await _db.collection(K.products)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .map(ProductModel.fromFirestore)
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.composition.toLowerCase().contains(q) ||
            p.company.toLowerCase().contains(q))
        .toList();
  }

  Future<String?> uploadImage(String productId, File file) async {
    final ref = _storage.ref('products/$productId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> addProduct(ProductModel p, {File? image}) async {
    final ref = _db.collection(K.products).doc();
    String? imageUrl;
    if (image != null) imageUrl = await uploadImage(ref.id, image);
    await ref.set(p.copyWith(imageUrl: imageUrl).toMap());
    return ref.id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data, {File? image}) async {
    if (image != null) {
      final url = await uploadImage(id, image);
      data['imageUrl'] = url;
    }
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(K.products).doc(id).update(data);
  }

  Future<void> deleteProduct(String id) =>
      _db.collection(K.products).doc(id).update({'isActive': false, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> toggleProduct(String id, bool active) =>
      _db.collection(K.products).doc(id).update({'isActive': active, 'updatedAt': FieldValue.serverTimestamp()});

  /// Bulk-inserts the [kSampleProducts] catalogue. Idempotent on `name` —
  /// products already present (case-insensitive name match) are skipped.
  /// Returns (added, skipped).
  Future<(int added, int skipped)> seedSampleProducts() async {
    final existingSnap = await _db.collection(K.products).get();
    final existingNames = existingSnap.docs
        .map((d) => (d.data()['name'] as String? ?? '').trim().toLowerCase())
        .toSet();

    final toAdd = kSampleProducts.where(
      (p) => !existingNames.contains(p['name']!.trim().toLowerCase()),
    ).toList();

    if (toAdd.isEmpty) return (0, kSampleProducts.length);

    // Firestore batch max = 500 ops; chunk for safety.
    int added = 0;
    for (var i = 0; i < toAdd.length; i += 400) {
      final chunk = toAdd.sublist(i, i + 400 > toAdd.length ? toAdd.length : i + 400);
      final batch = _db.batch();
      for (final p in chunk) {
        final ref = _db.collection(K.products).doc();
        batch.set(ref, {
          'name':        p['name'],
          'composition': p['composition'],
          'company':     'Sarian Healthcare',
          'category':    p['category'],
          'description': '',
          'imageUrl':    null,
          'isActive':    true,
          'updatedAt':   FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      added += chunk.length;
    }
    return (added, kSampleProducts.length - added);
  }
}
