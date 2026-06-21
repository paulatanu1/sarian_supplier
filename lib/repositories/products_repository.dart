import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/k.dart';
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
    final snap = await _db.collection(K.categories).limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final c in kDefaultCategories) {
      final ref = _db.collection(K.categories).doc();
      batch.set(ref, {...c, 'isActive': true});
    }
    await batch.commit();
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
}
