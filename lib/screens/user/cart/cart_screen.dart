import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/product_avatar.dart';
import '../../../models/cart_item_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/orders_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider).asData?.value ?? [];
    if (cart.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text('Place order for ${cart.fold(0, (s, i) => s + i.quantity)} items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final orderId = await ref.read(ordersNotifierProvider.notifier)
          .placeOrder(cartItems: cart, notes: _notesCtrl.text.trim());
      await ref.read(cartNotifierProvider.notifier).clear();
      if (!mounted) return;
      context.showSnack('Order placed successfully!');
      context.go('/orders/$orderId');
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final cart      = cartAsync.asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart${cart.isEmpty ? '' : ' (${cart.length})'}'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Remove all items from cart?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (ok == true) ref.read(cartNotifierProvider.notifier).clear();
              },
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 80, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text('Your cart is empty', style: context.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Add products to get started',
                    style: context.textTheme.bodyMedium),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/products'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Browse Products'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
                ),
              ]),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...cart.map((item) => _CartItem(
                            item: item,
                            onQtyChange: (q) => ref
                                .read(cartNotifierProvider.notifier)
                                .updateQty(item.productId, q),
                            onRemove: () => ref
                                .read(cartNotifierProvider.notifier)
                                .remove(item.productId),
                          )),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Order Notes (optional)',
                          hintText: 'Special instructions for this order…',
                          prefixIcon: Icon(Icons.note_outlined),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom order summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(children: [
                    Text('${cart.fold(0, (s, i) => s + i.quantity)} items in cart',
                        style: context.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/products'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 8)),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Continue Shopping'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _placeOrder,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          child: const Text('Place Order'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ],
            ),
    );
  }
}

class _CartItem extends StatelessWidget {
  final CartItem item;
  final void Function(int) onQtyChange;
  final VoidCallback onRemove;
  const _CartItem({required this.item, required this.onQtyChange, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        ProductAvatar(
          imageUrl: item.imageUrl,
          productName: item.productName,
          company: item.company,
          composition: item.composition,
          size: 60,
          radius: 10,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(item.composition,
              style: context.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        Column(children: [
          Row(children: [
            _CircleBtn(icon: Icons.remove, onTap: () => onQtyChange(item.quantity - 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            _CircleBtn(icon: Icons.add, onTap: () => onQtyChange(item.quantity + 1)),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
          ),
        ]),
      ]),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary),
      ),
      child: Icon(icon, size: 14, color: AppColors.primary),
    ),
  );
}
