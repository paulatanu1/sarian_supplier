import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/product_avatar.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../providers/products_provider.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => context.push('/admin/products/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => ListView.builder(
                itemCount: 6,
                padding: const EdgeInsets.all(12),
                itemBuilder: (ctx, _) => const OrderCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                final filtered = _query.isEmpty
                    ? products
                    : products.where((p) =>
                        p.name.toLowerCase().contains(_query) ||
                        p.composition.toLowerCase().contains(_query) ||
                        p.company.toLowerCase().contains(_query)).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        leading: ProductAvatar(
                          imageUrl: p.imageUrl,
                          productName: p.name,
                          company: p.company,
                          composition: p.composition,
                          size: 52,
                          radius: 8,
                        ),
                        title: Text(p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.composition, maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall),
                          Row(children: [
                            _Tag(p.category, AppColors.primary),
                            const SizedBox(width: 6),
                            _Tag(p.inStock ? 'In Stock' : 'Out',
                                p.inStock ? AppColors.success : AppColors.error),
                          ]),
                        ]),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Switch(
                            value: p.isActive,
                            onChanged: (v) => ref
                                .read(productsNotifierProvider.notifier)
                                .toggle(p.id, v),
                            activeThumbColor: AppColors.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => context.push('/admin/products/${p.id}/edit'),
                            padding: EdgeInsets.zero,
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
  );
}
