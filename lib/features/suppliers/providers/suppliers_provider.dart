import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../models/supplier_model.dart';

final suppliersStreamProvider = StreamProvider<List<SupplierModel>>((ref) {
  return FirebaseService.collection(AppConstants.suppliersCollection)
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(SupplierModel.fromFirestore).toList());
});

class SuppliersNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String?> addSupplier(SupplierModel supplier) async {
    state = const AsyncValue.loading();
    String? id;
    state = await AsyncValue.guard(() async {
      final ref = await FirebaseService.collection(AppConstants.suppliersCollection)
          .add(supplier.toMap());
      id = ref.id;
    });
    return id;
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await FirebaseService.collection(AppConstants.suppliersCollection)
          .doc(id)
          .update(data);
    });
  }

  Future<void> deactivate(String id) async {
    await FirebaseService.collection(AppConstants.suppliersCollection)
        .doc(id)
        .update({'isActive': false});
  }
}

final suppliersNotifierProvider =
    NotifierProvider<SuppliersNotifier, AsyncValue<void>>(SuppliersNotifier.new);
