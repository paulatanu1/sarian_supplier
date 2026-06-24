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
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsNotifierProvider.notifier).seedCategories();
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _showCategoryCounts() async {
    final products = ref.read(allProductsAdminProvider).asData?.value ?? const [];

    // Count by exact category value. Empty/whitespace counts under "(no category)".
    final counts = <String, int>{};
    var noCategory = 0;
    for (final p in products) {
      final raw = p.category.trim();
      if (raw.isEmpty) {
        noCategory++;
      } else {
        counts[raw] = (counts[raw] ?? 0) + 1;
      }
    }
    final sortedCats = counts.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text('Product counts (${products.length} total)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in sortedCats)
                  _CountRow(label: c, count: counts[c]!),
                if (noCategory > 0) ...[
                  const Divider(height: 24),
                  _CountRow(
                    label: '(no category)',
                    count: noCategory,
                    warn: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _seedSampleProducts() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Seed Sample Products?'),
        content: const Text(
          'Adds ~81 sample pharma products across all 18 categories. '
          'Existing products are kept; only new names will be added.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Seed')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _seeding = true);
    try {
      final (added, skipped) =
          await ref.read(productsNotifierProvider.notifier).seedSampleProducts();
      if (mounted) {
        context.showSnack(added == 0
            ? 'No new products — catalogue already seeded.'
            : 'Added $added products. Skipped $skipped already present.');
      }
    } catch (e) {
      if (mounted) context.showSnack('Seed failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Tools',
            icon: _seeding
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.more_vert_rounded, color: Colors.white),
            enabled: !_seeding,
            onSelected: (v) {
              switch (v) {
                case 'counts': _showCategoryCounts();
                case 'seed':   _seedSampleProducts();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'counts',
                child: ListTile(
                  leading: Icon(Icons.assessment_outlined),
                  title: Text('Category counts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'seed',
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_rounded),
                  title: Text('Seed sample products'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
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
              error: (e, _) => const Center(child: Text('Unable to load products. Please try again.')),
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
                          Wrap(spacing: 6, runSpacing: 2, children: [
                            _Tag(p.category, AppColors.primary),
                            _Tag('In Stock', AppColors.success),
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

class _CountRow extends StatelessWidget {
  final String label;
  final int    count;
  final bool   warn;
  const _CountRow({required this.label, required this.count, this.warn = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(
        warn ? Icons.warning_amber_rounded : Icons.label_outline,
        size: 16,
        color: warn ? AppColors.warning
            : (count > 0 ? AppColors.success : AppColors.textSecondary),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label,
            style: const TextStyle(fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: (count > 0 ? AppColors.primary : AppColors.textSecondary)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: count > 0 ? AppColors.primary : AppColors.textSecondary,
            )),
      ),
    ]),
  );
}
