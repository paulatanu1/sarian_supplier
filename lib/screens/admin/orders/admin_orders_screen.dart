import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../models/order_model.dart';
import '../../../providers/orders_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final active   = ref.watch(activeOrdersProvider);
    final upcoming = ref.watch(upcomingOrdersProvider);
    final previous = ref.watch(previousOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Current${_badgeText(active.asData?.value)}'),
            Tab(text: 'Upcoming${_badgeText(upcoming.asData?.value)}'),
            const Tab(text: 'Previous'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OrderList(async: active),
          _OrderList(async: upcoming),
          _OrderList(async: previous),
        ],
      ),
    );
  }

  String _badgeText(List? l) => (l?.isNotEmpty ?? false) ? ' (${l!.length})' : '';
}

class _OrderList extends ConsumerWidget {
  final AsyncValue<List<OrderModel>> async;
  const _OrderList({required this.async});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (ctx, _) => const OrderCardSkeleton(),
      ),
      error: (e, _) => const Center(child: Text('Unable to load orders. Please try again.')),
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_rounded, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No orders in this category'),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (_, i) => _AdminOrderCard(order: orders[i], ref: ref),
        );
      },
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final WidgetRef ref;
  const _AdminOrderCard({required this.order, required this.ref});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(order.status);

    return GestureDetector(
      onTap: () => context.push('/admin/orders/${order.id}'),
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.orderNumber,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(order.shopName,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium),
              Text(order.createdAt.timeAgo, style: context.textTheme.bodySmall),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(order.status.toUpperCase(),
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.bold, color: color)),
            ),
          ]),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${order.totalItems} items',
                  style: context.textTheme.bodyMedium),
              _NextActionBtn(order: order, ref: ref),
            ],
          ),
        ]),
      ),
    );
  }
}

class _NextActionBtn extends StatelessWidget {
  final OrderModel order;
  final WidgetRef ref;
  const _NextActionBtn({required this.order, required this.ref});

  @override
  Widget build(BuildContext context) {
    final (label, next) = switch (order.status) {
      'pending'    => ('Accept',   'accepted'),
      'accepted'   => ('Process',  'processing'),
      'processing' => ('Dispatch', 'dispatched'),
      'dispatched' => ('Deliver',  'delivered'),
      _            => ('', ''),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () async {
          await ref.read(ordersNotifierProvider.notifier)
              .updateStatus(order.id, next);
          if (context.mounted) {
            context.showSnack('Order $next');
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
