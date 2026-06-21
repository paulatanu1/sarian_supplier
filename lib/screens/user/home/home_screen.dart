import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/orders_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(appUserProvider).asData?.value;
    final orders    = ref.watch(userOrdersProvider).asData?.value ?? [];
    final cartCount = ref.watch(cartCountProvider);

    final pending   = orders.where((o) => o.status == 'pending').length;
    final delivered = orders.where((o) => o.status == 'delivered').length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Hello, ${user?.name.split(' ').first ?? '...'} 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(user?.shopName ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(label: 'Total Orders',   value: '${orders.length}',
                          icon: Icons.shopping_bag_outlined, color: AppColors.info,
                          onTap: () => context.go('/orders')),
                      _StatCard(label: 'Pending',        value: '$pending',
                          icon: Icons.hourglass_empty_rounded, color: AppColors.warning,
                          onTap: () => context.go('/orders')),
                      _StatCard(label: 'Delivered',      value: '$delivered',
                          icon: Icons.check_circle_outline, color: AppColors.success,
                          onTap: () => context.go('/orders')),
                      _StatCard(label: 'Cart Items',     value: '$cartCount',
                          icon: Icons.shopping_cart_outlined, color: AppColors.accent,
                          onTap: () => context.go('/cart')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick actions
                  Text('Quick Actions', style: context.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(children: [
                    _QuickBtn(
                      icon: Icons.inventory_2_outlined,
                      label: 'Browse\nProducts',
                      onTap: () => context.go('/products'),
                    ),
                    const SizedBox(width: 12),
                    _QuickBtn(
                      icon: Icons.receipt_long_outlined,
                      label: 'My\nOrders',
                      onTap: () => context.go('/orders'),
                    ),
                    const SizedBox(width: 12),
                    _QuickBtn(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      onTap: () => context.go('/reports'),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Recent orders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Orders', style: context.textTheme.titleMedium),
                      TextButton(
                        onPressed: () => context.go('/orders'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (orders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 56, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text('No orders yet', style: context.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.go('/products'),
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(140, 44)),
                            child: const Text('Browse Products'),
                          ),
                        ]),
                      ),
                    )
                  else
                    ...orders.take(5).map((o) => _OrderRow(
                          orderNumber: o.orderNumber,
                          status: o.status,
                          date: o.createdAt.display,
                          items: o.totalItems,
                          onTap: () => context.push('/orders/${o.id}'),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Icon(icon, color: color, size: 26),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold, color: color)),
            Text(label, style: context.textTheme.bodySmall),
          ]),
        ]),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
        ]),
      ),
    ),
  );
}

class _OrderRow extends StatelessWidget {
  final String orderNumber, status, date;
  final int items;
  final VoidCallback onTap;
  const _OrderRow({required this.orderNumber, required this.status,
      required this.date, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 3),
            Text('$items item${items == 1 ? '' : 's'} • $date',
                style: context.textTheme.bodySmall),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status.toUpperCase(),
                style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}
