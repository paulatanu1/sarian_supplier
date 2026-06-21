import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _statuses = ['All', 'pending', 'confirmed', 'shipped', 'delivered'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  IconData _statusIcon(String s) => switch (s) {
        'pending' => Icons.hourglass_empty_rounded,
        'confirmed' => Icons.check_circle_outline,
        'shipped' => Icons.local_shipping_outlined,
        'delivered' => Icons.done_all,
        _ => Icons.cancel_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersStreamProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: _statuses
              .map((s) => Tab(text: s.toUpperCase()))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _statuses.map((status) {
          final filtered = status == 'All'
              ? allOrders
              : allOrders.where((o) => o.status == status).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(status),
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text('No ${status == 'All' ? '' : status} orders yet',
                      style: context.textTheme.bodyLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _OrderCard(
              order: filtered[i],
              onStatusChange: (newStatus) async {
                await ref
                    .read(ordersNotifierProvider.notifier)
                    .updateStatus(filtered[i].id, newStatus);
                if (context.mounted) {
                  context.showSnack('Status updated to $newStatus');
                }
              },
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final void Function(String) onStatusChange;

  const _OrderCard({required this.order, required this.onStatusChange});

  Color _statusColor(String s) => switch (s) {
        'pending' => AppColors.pending,
        'confirmed' => AppColors.confirmed,
        'shipped' => AppColors.shipped,
        'delivered' => AppColors.delivered,
        _ => AppColors.cancelled,
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(order.supplierName,
                      style: context.textTheme.titleMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.totalItems} items',
                style: context.textTheme.bodyMedium),
            Text('Ordered ${order.createdAt.timeAgo}',
                style: context.textTheme.bodyMedium),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: ${order.notes}',
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.totalAmount.inr,
                    style: context.textTheme.titleMedium
                        ?.copyWith(color: AppColors.primary)),
                if (order.status != 'delivered' &&
                    order.status != 'cancelled')
                  PopupMenuButton<String>(
                    onSelected: onStatusChange,
                    itemBuilder: (_) => [
                      if (order.status == 'pending')
                        const PopupMenuItem(
                            value: 'confirmed', child: Text('Mark Confirmed')),
                      if (order.status == 'confirmed')
                        const PopupMenuItem(
                            value: 'shipped', child: Text('Mark Shipped')),
                      if (order.status == 'shipped')
                        const PopupMenuItem(
                            value: 'delivered', child: Text('Mark Delivered')),
                      const PopupMenuItem(
                          value: 'cancelled', child: Text('Cancel Order')),
                    ],
                    child: const Row(
                      children: [
                        Text('Update Status',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
