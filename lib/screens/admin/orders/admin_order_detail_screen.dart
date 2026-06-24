import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/order_timeline.dart';
import '../../../core/widgets/product_avatar.dart';
import '../../../models/order_model.dart';
import '../../../providers/orders_provider.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  static const _nextStatus = {
    'pending':    'accepted',
    'accepted':   'processing',
    'processing': 'dispatched',
    'dispatched': 'delivered',
  };
  static const _nextLabel = {
    'pending':    'Accept Order',
    'accepted':   'Start Processing',
    'processing': 'Mark Dispatched',
    'dispatched': 'Mark Delivered',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('Order not found')));
        }

        final order = OrderModel.fromFirestore(snap.data!);
        final statusColor = AppColors.statusColor(order.status);
        final canUpdate   = _nextStatus.containsKey(order.status);

        return Scaffold(
          appBar: AppBar(
            title: Text(order.orderNumber),
            actions: [
              if (order.status != 'cancelled' && order.status != 'delivered')
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Cancel Order'),
                        content: Text('Cancel order ${order.orderNumber}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogCtx, false),
                              child: const Text('No')),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: const Text('Yes, Cancel',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(ordersNotifierProvider.notifier)
                          .updateStatus(orderId, 'cancelled');
                      if (context.mounted) {
                        context.showSnack('Order cancelled');
                        context.pop();
                      }
                    }
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status + action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Status', style: context.textTheme.bodySmall),
                    Text(order.status.toUpperCase(),
                        style: TextStyle(color: statusColor,
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(order.updatedAt?.displayTime ?? order.createdAt.displayTime,
                        style: context.textTheme.bodySmall),
                  ]),
                  const Spacer(),
                  if (canUpdate)
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(ordersNotifierProvider.notifier)
                            .updateStatus(orderId, _nextStatus[order.status]!);
                        if (context.mounted) {
                          context.showSnack('Status updated to ${_nextStatus[order.status]}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10)),
                      child: Text(_nextLabel[order.status]!,
                          style: const TextStyle(fontSize: 12)),
                    ),
                ]),
              ),
              const SizedBox(height: 16),

              // Shop info
              _Card(title: 'Shop Details', children: [
                _Row('Shop',  order.shopName),
                _Row('Owner', order.userName),
                _Row('Phone', order.phone),
              ]),
              const SizedBox(height: 12),

              // Items
              _Card(title: 'Items (${order.totalItems})', children: [
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    ProductAvatar(
                      imageUrl: item.imageUrl,
                      productName: item.productName,
                      company: item.company,
                      composition: item.composition,
                      size: 52, radius: 8,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 2),
                      Text(item.composition, style: context.textTheme.bodySmall, maxLines: 1),
                      Text('${item.company}  •  Qty: ${item.quantity}',
                          style: context.textTheme.bodySmall),
                    ])),
                  ]),
                )),
              ]),
              const SizedBox(height: 12),

              // Timeline
              if (order.statusHistory.isNotEmpty)
                _Card(title: 'Order Timeline', children: [
                  OrderTimeline(events: order.statusHistory),
                ]),

              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Card(title: 'Notes', children: [
                  Text(order.notes!, style: context.textTheme.bodyMedium),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: context.textTheme.titleSmall),
      const SizedBox(height: 12),
      ...children,
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 52, child: Text(label, style: context.textTheme.bodySmall)),
      Text(' : ', style: context.textTheme.bodySmall),
      Expanded(child: Text(value.isEmpty ? '—' : value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );
}
