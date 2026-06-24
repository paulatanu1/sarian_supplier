import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/k.dart';
import '../core/services/fcm_service.dart';
import '../core/utils/helpers.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class OrdersRepository {
  final _db = FirebaseFirestore.instance;

  // ── User streams ──────────────────────────────────────────────────────
  Stream<List<OrderModel>> userOrdersStream(String uid) => _db
      .collection(K.orders)
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  // ── Admin streams ─────────────────────────────────────────────────────
  Stream<List<OrderModel>> ordersStreamByStatus(List<String> statuses) => _db
      .collection(K.orders)
      .where('status', whereIn: statuses)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  Stream<List<OrderModel>> allOrdersStream() => _db
      .collection(K.orders)
      .orderBy('createdAt', descending: true)
      .limit(K.pageSize)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromFirestore).toList());

  // ── Place order ───────────────────────────────────────────────────────
  Future<String> placeOrder({
    required AppUser user,
    required List<CartItem> cartItems,
    String? notes,
  }) async {
    final orderNumber = generateOrderNumber();

    final order = OrderModel(
      id:          '',
      orderNumber: orderNumber,
      userId:      user.id,
      userName:    user.name,
      shopName:    user.shopName,
      phone:       user.phone,
      items:       cartItems.map((c) => OrderItem(
        productId:   c.productId,
        productName: c.productName,
        composition: c.composition,
        company:     c.company,
        imageUrl:    c.imageUrl,
        quantity:    c.quantity,
      )).toList(),
      status:        K.sPending,
      notes:         notes,
      statusHistory: [StatusEvent(status: K.sPending, timestamp: DateTime.now())],
      createdAt:     DateTime.now(),
    );

    final ref = await _db.collection(K.orders).add(order.toMap());

    // Notify admins — best-effort, don't block order success if FCM fails
    try {
      await FcmService.notifyAdmins(
        title: '🛒 New Order Received',
        body:  '${user.shopName} placed order $orderNumber (${cartItems.length} items)',
        data:  {'orderId': ref.id, 'type': 'new_order'},
      );
    } catch (_) {
      // Notification is a side effect — order has already been created successfully.
    }

    return ref.id;
  }

  // ── Update status (admin) ─────────────────────────────────────────────
  Future<void> updateStatus(String orderId, String newStatus, {String? note}) async {
    final doc = await _db.collection(K.orders).doc(orderId).get();
    final order = OrderModel.fromFirestore(doc);

    final event = StatusEvent(
      status:    newStatus,
      timestamp: DateTime.now(),
      note:      note,
    );

    final history = [...order.statusHistory, event];

    await _db.collection(K.orders).doc(orderId).update({
      'status':        newStatus,
      'statusHistory': history.map((e) => e.toMap()).toList(),
      'updatedAt':     FieldValue.serverTimestamp(),
    });

    // Notify user — best-effort
    try {
      await FcmService.notifyUser(
        uid:   order.userId,
        title: _statusTitle(newStatus),
        body:  'Your order ${order.orderNumber} has been ${_statusLabel(newStatus)}.',
        data:  {'orderId': orderId, 'type': 'status_update'},
      );
    } catch (_) {}
  }

  // ── Reports helpers ───────────────────────────────────────────────────
  Future<List<OrderModel>> fetchOrdersInRange(DateTime from, DateTime to) async {
    final snap = await _db.collection(K.orders)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo:    Timestamp.fromDate(to))
        .get();
    return snap.docs.map(OrderModel.fromFirestore).toList();
  }

  String _statusTitle(String s) => switch (s) {
    K.sAccepted   => '✅ Order Accepted',
    K.sProcessing => '⚙️ Order Processing',
    K.sDispatched => '🚚 Order Dispatched',
    K.sDelivered  => '🎉 Order Delivered',
    K.sCancelled  => '❌ Order Cancelled',
    _             => 'Order Update',
  };

  String _statusLabel(String s) => switch (s) {
    K.sAccepted   => 'accepted',
    K.sProcessing => 'being processed',
    K.sDispatched => 'dispatched',
    K.sDelivered  => 'delivered',
    K.sCancelled  => 'cancelled',
    _             => 'updated',
  };
}
