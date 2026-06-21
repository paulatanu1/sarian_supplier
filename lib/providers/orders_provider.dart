import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/k.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../repositories/orders_repository.dart';
import 'auth_provider.dart';

final ordersRepoProvider = Provider((_) => OrdersRepository());

// ── User order streams ────────────────────────────────────────────────────
final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uid = ref.watch(appUserProvider).asData?.value?.id;
  if (uid == null) return const Stream.empty();
  return ref.read(ordersRepoProvider).userOrdersStream(uid);
});

// ── Admin order streams ───────────────────────────────────────────────────
final activeOrdersProvider = StreamProvider<List<OrderModel>>(
  (ref) => ref.read(ordersRepoProvider).ordersStreamByStatus(K.activeStatuses),
);

final upcomingOrdersProvider = StreamProvider<List<OrderModel>>(
  (ref) => ref.read(ordersRepoProvider).ordersStreamByStatus(K.upcomingStatuses),
);

final previousOrdersProvider = StreamProvider<List<OrderModel>>(
  (ref) => ref.read(ordersRepoProvider).ordersStreamByStatus(K.previousStatuses),
);

final allOrdersProvider = StreamProvider<List<OrderModel>>(
  (ref) => ref.read(ordersRepoProvider).allOrdersStream(),
);

// ── Orders Notifier ───────────────────────────────────────────────────────
class OrdersNotifier extends AsyncNotifier<void> {
  OrdersRepository get _repo => ref.read(ordersRepoProvider);

  @override
  Future<void> build() async {}

  Future<String> placeOrder({
    required List<CartItem> cartItems,
    String? notes,
  }) async {
    final user = ref.read(appUserProvider).asData?.value;
    if (user == null) throw Exception('Not authenticated');
    return _repo.placeOrder(user: user, cartItems: cartItems, notes: notes);
  }

  Future<void> updateStatus(String orderId, String status, {String? note}) =>
      _repo.updateStatus(orderId, status, note: note);
}

final ordersNotifierProvider =
    AsyncNotifierProvider<OrdersNotifier, void>(OrdersNotifier.new);

// ── Reports data ──────────────────────────────────────────────────────────
final reportOrdersProvider =
    FutureProvider.family<List<OrderModel>, DateRange>((ref, range) =>
        ref.read(ordersRepoProvider).fetchOrdersInRange(range.from, range.to));

class DateRange {
  final DateTime from;
  final DateTime to;
  const DateRange(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      other is DateRange && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);
}
