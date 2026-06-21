import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../models/order_model.dart';
import '../../../providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Previous'),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (ctx, _) => const OrderCardSkeleton(),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          final current  = orders.where((o) => ['pending','accepted','processing'].contains(o.status)).toList();
          final upcoming = orders.where((o) => o.status == 'dispatched').toList();
          final previous = orders.where((o) => ['delivered','cancelled'].contains(o.status)).toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _OrderList(orders: current,  emptyMsg: 'No current orders'),
              _OrderList(orders: upcoming, emptyMsg: 'No upcoming deliveries'),
              _OrderList(orders: previous, emptyMsg: 'No previous orders'),
            ],
          );
        },
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyMsg;
  const _OrderList({required this.orders, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(emptyMsg, style: context.textTheme.bodyLarge),
      ]));
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(order.status);
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            _StatusChip(status: order.status, color: color),
          ]),
          const SizedBox(height: 8),
          Text('${order.totalItems} item${order.totalItems == 1 ? '' : 's'}',
              style: context.textTheme.bodyMedium),
          Text(order.createdAt.displayTime, style: context.textTheme.bodySmall),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${order.notes}',
                style: context.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(order.totalAmount.inr,
                style: context.textTheme.titleMedium
                    ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            Row(children: [
              Text('View Details', style: TextStyle(color: AppColors.primary,
                  fontWeight: FontWeight.w600, fontSize: 13)),
              const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );
}
