import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/order_timeline.dart';
import '../../../core/widgets/product_avatar.dart';
import '../../../models/order_model.dart';
import '../../../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  static const _cancelStartHour = 5;   // 05:00 local
  static const _cancelEndHour   = 19;  // 19:00 local

  bool get _isInCancelWindow {
    final h = DateTime.now().hour;
    return h >= _cancelStartHour && h < _cancelEndHour;
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, String number) async {
    if (!_isInCancelWindow) {
      context.showSnack(
        'Cancellation allowed between 5:00 AM and 7:00 PM only.',
        isError: true,
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order $number?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(ordersNotifierProvider.notifier).updateStatus(orderId, 'cancelled');
      if (context.mounted) context.showSnack('Order cancelled');
    } catch (_) {
      if (context.mounted) context.showSnack('Failed to cancel order', isError: true);
    }
  }

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
        final canCancel   = order.status == 'pending';
        final inWindow    = _isInCancelWindow;

        return Scaffold(
          appBar: AppBar(
            title: Text(order.orderNumber),
            actions: [
              if (canCancel)
                TextButton(
                  onPressed: () => _cancelOrder(context, ref, order.orderNumber),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: inWindow ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(_statusIcon(order.status), color: statusColor, size: 32),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.status.toUpperCase(),
                        style: TextStyle(color: statusColor,
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(order.createdAt.displayTime,
                        style: context.textTheme.bodySmall),
                  ]),
                ]),
              ),

              // Cancel window hint — shown only for pending orders
              if (canCancel) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (inWindow ? AppColors.info : AppColors.warning)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(
                      inWindow ? Icons.info_outline : Icons.access_time_rounded,
                      size: 16,
                      color: inWindow ? AppColors.info : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        inWindow
                            ? 'You can cancel this order between 5:00 AM – 7:00 PM.'
                            : 'Cancellation closed. Available 5:00 AM – 7:00 PM only.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 16),

              // Shop info
              _Section(title: 'Shop Details', children: [
                _InfoRow(label: 'Shop',  value: order.shopName),
                _InfoRow(label: 'Owner', value: order.userName),
                _InfoRow(label: 'Phone', value: order.phone),
              ]),
              const SizedBox(height: 16),

              // Items
              _Section(
                title: 'Ordered Items (${order.totalItems})',
                children: order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    ProductAvatar(
                      imageUrl: item.imageUrl,
                      productName: item.productName,
                      company: item.company,
                      composition: item.composition,
                      size: 50,
                      radius: 8,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 2),
                      Text(item.composition, style: context.textTheme.bodySmall, maxLines: 1),
                      Text('Qty: ${item.quantity}',
                          style: context.textTheme.bodySmall),
                    ])),
                  ]),
                )).toList(),
              ),
              const SizedBox(height: 16),

              // Timeline
              if (order.statusHistory.isNotEmpty)
                _Section(
                  title: 'Order Timeline',
                  children: [OrderTimeline(events: order.statusHistory)],
                ),

              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Section(title: 'Notes', children: [
                  Text(order.notes!, style: context.textTheme.bodyMedium),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _statusIcon(String s) => switch (s) {
    'pending'    => Icons.hourglass_empty_rounded,
    'accepted'   => Icons.thumb_up_outlined,
    'processing' => Icons.settings_outlined,
    'dispatched' => Icons.local_shipping_outlined,
    'delivered'  => Icons.check_circle_outline,
    _            => Icons.cancel_outlined,
  };
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

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

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 56,
          child: Text(label, style: context.textTheme.bodySmall)),
      Text(' : ', style: context.textTheme.bodySmall),
      Expanded(child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );
}
