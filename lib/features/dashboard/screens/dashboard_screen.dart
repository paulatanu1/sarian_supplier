import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final orders = ref.watch(ordersStreamProvider).asData?.value ?? [];
    final products = ref.watch(productsStreamProvider).asData?.value ?? [];
    final suppliers = ref.watch(suppliersStreamProvider).asData?.value ?? [];

    final pending = orders.where((o) => o.status == 'pending').length;
    final delivered = orders.where((o) => o.status == 'delivered').length;
    final totalRevenue = orders
        .where((o) => o.status == 'delivered')
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sarian Supplier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersStreamProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.name.split(' ').first ?? 'User'} 👋',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateTime.now().formatted,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.local_pharmacy, color: Colors.white54, size: 48),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats grid
            Text('Overview', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  label: 'Total Orders',
                  value: '${orders.length}',
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.info,
                  onTap: () => context.push('/orders'),
                ),
                _StatCard(
                  label: 'Pending',
                  value: '$pending',
                  icon: Icons.hourglass_empty_rounded,
                  color: AppColors.warning,
                  onTap: () => context.push('/orders'),
                ),
                _StatCard(
                  label: 'Products',
                  value: '${products.length}',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  onTap: () => context.push('/products'),
                ),
                _StatCard(
                  label: 'Suppliers',
                  value: '${suppliers.length}',
                  icon: Icons.business_outlined,
                  color: AppColors.accent,
                  onTap: () => context.push('/suppliers'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Revenue card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee, color: AppColors.success, size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Revenue', style: context.textTheme.bodyMedium),
                      Text(
                        totalRevenue.inr,
                        style: context.textTheme.headlineMedium
                            ?.copyWith(color: AppColors.success),
                      ),
                      Text(
                        '$delivered orders delivered',
                        style: context.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick actions
            Text('Quick Actions', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    label: 'New Order',
                    icon: Icons.add_shopping_cart,
                    onTap: () => context.push('/orders/new'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    label: 'Products',
                    icon: Icons.inventory_outlined,
                    onTap: () => context.push('/products'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    label: 'Suppliers',
                    icon: Icons.people_outline,
                    onTap: () => context.push('/suppliers'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent orders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: context.textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/orders'),
                  child: const Text('View All'),
                ),
              ],
            ),
            ...orders.take(5).map((o) => _RecentOrderTile(order: o)),
          ],
        ),
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

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark)),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final dynamic order;
  const _RecentOrderTile({required this.order});

  Color _statusColor(String s) => switch (s) {
        'pending' => AppColors.pending,
        'confirmed' => AppColors.confirmed,
        'shipped' => AppColors.shipped,
        'delivered' => AppColors.delivered,
        _ => AppColors.cancelled,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.supplierName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${order.totalItems} items • ${order.totalAmount.inr}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(order.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.toString().toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(order.status)),
            ),
          ),
        ],
      ),
    );
  }
}
