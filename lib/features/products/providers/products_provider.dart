import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../models/product_model.dart';

final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  return FirebaseService.collection(AppConstants.productsCollection)
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(ProductModel.fromFirestore).toList());
});

final productsByCategoryProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, category) {
  return FirebaseService.collection(AppConstants.productsCollection)
      .where('category', isEqualTo: category)
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(ProductModel.fromFirestore).toList());
});

final productSearchProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final snap = await FirebaseService.collection(AppConstants.productsCollection)
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .startAt([query.toUpperCase()])
      .endAt(['${query.toUpperCase()}'])
      .limit(AppConstants.pageSize)
      .get();
  return snap.docs.map(ProductModel.fromFirestore).toList();
});

class ProductsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addProduct(ProductModel product) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.collection(AppConstants.productsCollection)
          .add(product.toMap());
    });
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseService.collection(AppConstants.productsCollection)
          .doc(id)
          .update(data);
    });
  }

  Future<void> updateStock(String id, int qty) async {
    await FirebaseService.collection(AppConstants.productsCollection)
        .doc(id)
        .update({'stockQty': qty, 'updatedAt': FieldValue.serverTimestamp()});
  }
}

final productsNotifierProvider =
    NotifierProvider<ProductsNotifier, AsyncValue<void>>(ProductsNotifier.new);
