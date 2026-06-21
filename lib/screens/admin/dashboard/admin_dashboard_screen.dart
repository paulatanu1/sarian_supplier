import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/products_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(appUserProvider).asData?.value;
    final allOrders  = ref.watch(allOrdersProvider).asData?.value ?? [];
    final allUsers   = ref.watch(allUsersProvider).asData?.value ?? [];
    final products   = ref.watch(allProductsAdminProvider).asData?.value ?? [];
    final themeMode  = ref.watch(themeModeProvider);
    final isDark     = themeMode == ThemeMode.dark;

    final pending    = allOrders.where((o) => o.status == 'pending').length;
    final revenue    = allOrders
        .where((o) => o.status == 'delivered')
        .fold<double>(0, (s, o) => s + o.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: Colors.white),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
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
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome, ${user?.name.split(' ').first ?? 'Admin'} 👋',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateTime.now().displayTime,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
              const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white38, size: 48),
            ]),
          ),
          const SizedBox(height: 20),

          // Stats
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _Card('Total Orders',  '${allOrders.length}',
                  Icons.shopping_bag_outlined, AppColors.info,
                  () => context.go('/admin/orders')),
              _Card('Pending',       '$pending',
                  Icons.hourglass_empty_rounded, AppColors.warning,
                  () => context.go('/admin/orders')),
              _Card('Products',      '${products.length}',
                  Icons.inventory_2_outlined, AppColors.primary,
                  () => context.go('/admin/products')),
              _Card('Users',         '${allUsers.length}',
                  Icons.people_outline, AppColors.accent,
                  () => context.go('/admin/users')),
            ],
          ),
          const SizedBox(height: 16),

          // Revenue
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.currency_rupee_rounded,
                  color: AppColors.success, size: 40),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total Revenue', style: context.textTheme.bodyMedium),
                Text(revenue.inr,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                        color: AppColors.success)),
                Text('from delivered orders', style: context.textTheme.bodySmall),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Recent orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Orders', style: context.textTheme.titleMedium),
              TextButton(
                  onPressed: () => context.go('/admin/orders'),
                  child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 8),
          ...allOrders.take(5).map((o) {
            final color = AppColors.statusColor(o.status);
            return GestureDetector(
              onTap: () => context.push('/admin/orders/${o.id}'),
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
                    Text(o.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(o.shopName, style: context.textTheme.bodySmall),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(o.status.toUpperCase(),
                        style: TextStyle(fontSize: 9,
                            fontWeight: FontWeight.bold, color: color)),
                  ),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Card(this.label, this.value, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 26),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: context.textTheme.bodySmall),
        ]),
      ]),
    ),
  );
}
