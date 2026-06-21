import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../models/order_model.dart';

final ordersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  return FirebaseService.collection(AppConstants.ordersCollection)
      .orderBy('createdAt', descending: true)
      .limit(AppConstants.pageSize)
      .snapshots()
      .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
});

final ordersByStatusProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, status) {
  return FirebaseService.collection(AppConstants.ordersCollection)
      .where('status', isEqualTo: status)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
});

final ordersBySupplierProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, supplierId) {
  return FirebaseService.collection(AppConstants.ordersCollection)
      .where('supplierId', isEqualTo: supplierId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
});

class OrdersNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String?> createOrder(OrderModel order) async {
    state = const AsyncValue.loading();
    String? orderId;
    state = await AsyncValue.guard(() async {
      final ref = await FirebaseService.collection(AppConstants.ordersCollection)
          .add(order.toMap());
      orderId = ref.id;
    });
    return orderId;
  }

  Future<void> updateStatus(String orderId, String status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == AppConstants.statusDelivered) {
        data['deliveredAt'] = FieldValue.serverTimestamp();
      }
      await FirebaseService.collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update(data);
    });
  }

  Future<void> cancelOrder(String orderId) =>
      updateStatus(orderId, AppConstants.statusCancelled);
}

final ordersNotifierProvider =
    NotifierProvider<OrdersNotifier, AsyncValue<void>>(OrdersNotifier.new);
