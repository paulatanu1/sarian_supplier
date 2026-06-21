import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../repositories/cart_repository.dart';
import 'auth_provider.dart';

final cartRepoProvider = Provider((_) => CartRepository());

final cartProvider = StreamProvider<List<CartItem>>((ref) {
  final uid = ref.watch(appUserProvider).asData?.value?.id;
  if (uid == null) return const Stream.empty();
  return ref.read(cartRepoProvider).cartStream(uid);
});

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider).asData?.value ?? [];
  return cart.fold(0, (s, i) => s + i.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider).asData?.value ?? [];
  return cart.fold(0.0, (s, i) => s + i.subtotal);
});

final isInCartProvider = Provider.family<bool, String>((ref, productId) {
  final cart = ref.watch(cartProvider).asData?.value ?? [];
  return cart.any((i) => i.productId == productId);
});

final cartItemQtyProvider = Provider.family<int, String>((ref, productId) {
  final cart = ref.watch(cartProvider).asData?.value ?? [];
  try {
    return cart.firstWhere((i) => i.productId == productId).quantity;
  } catch (_) {
    return 0;
  }
});

class CartNotifier extends AsyncNotifier<void> {
  CartRepository get _repo => ref.read(cartRepoProvider);
  String? get _uid => ref.read(appUserProvider).asData?.value?.id;

  @override
  Future<void> build() async {}

  Future<void> add(ProductModel product) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.addToCart(uid, product);
  }

  Future<void> updateQty(String productId, int qty) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.updateQuantity(uid, productId, qty);
  }

  Future<void> remove(String productId) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.removeItem(uid, productId);
  }

  Future<void> clear() async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.clearCart(uid);
  }
}

final cartNotifierProvider =
    AsyncNotifierProvider<CartNotifier, void>(CartNotifier.new);
