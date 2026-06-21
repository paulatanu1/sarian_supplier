import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/product_avatar.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sticky_cart_bar.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/products_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsNotifierProvider.notifier).seedCategories();
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cats          = ref.watch(categoriesProvider).asData?.value ?? [];
    final selectedCat   = ref.watch(selectedCategoryProvider);
    final effectiveCat  = selectedCat.isEmpty && cats.isNotEmpty ? cats.first.name : selectedCat;
    final productsAsync = ref.watch(productsProvider(effectiveCat));
    final searchAsync   = ref.watch(productSearchProvider(_query));

    final products = _query.isNotEmpty
        ? (searchAsync.asData?.value ?? [])
        : (productsAsync.asData?.value ?? []);

    final isLoading = _query.isNotEmpty
        ? searchAsync.isLoading
        : productsAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, composition, company…',
                hintStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        })
                    : null,
                filled: true,
                fillColor: Colors.white12,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white38)),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // ── Left: Category sidebar ──────────────────────────────
                if (_query.isEmpty)
                  Container(
                    width: 80,
                    color: context.isDark
                        ? AppColors.surfaceDark
                        : const Color(0xFFF0F2F5),
                    child: cats.isEmpty
                        ? const SizedBox()
                        : ListView.builder(
                            itemCount: cats.length,
                            itemBuilder: (_, i) {
                              final cat = cats[i];
                              final active = cat.name == effectiveCat;
                              return GestureDetector(
                                onTap: () => ref
                                    .read(selectedCategoryProvider.notifier)
                                    .state = cat.name,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(children: [
                                    Text(cat.icon, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(height: 4),
                                    Text(
                                      cat.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: active
                                            ? Colors.white
                                            : context.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                  ),

                // ── Right: Product grid ─────────────────────────────────
                Expanded(
                  child: isLoading
                      ? GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: 6,
                          itemBuilder: (ctx, _) => const ProductCardSkeleton(),
                        )
                      : products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.inventory_2_outlined,
                                      size: 64, color: AppColors.textSecondary),
                                  const SizedBox(height: 12),
                                  Text('No products found',
                                      style: context.textTheme.bodyMedium),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.62,
                              ),
                              itemCount: products.length,
                              itemBuilder: (_, i) =>
                                  _ProductCard(product: products[i]),
                            ),
                ),
              ],
            ),
          ),

          // Sticky cart bar
          const StickyCartBar(),
        ],
      ),
    );
  }
}

// ── Product card ───────────────────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = ref.watch(isInCartProvider(product.id));
    final qty    = ref.watch(cartItemQtyProvider(product.id));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: ProductAvatar(
              imageUrl:    product.imageUrl,
              productName: product.name,
              company:     product.company,
              composition: product.composition,
              size:        double.infinity,
              radius:      0,
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.composition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                  Text(
                    product.company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (product.mrp > 0)
                    Text(product.mrp.inr,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark)),

                  const SizedBox(height: 6),
                  // ADD / Qty control
                  !inCart
                      ? SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: product.inStock
                                ? () => ref
                                    .read(cartNotifierProvider.notifier)
                                    .add(product)
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            child: Text(product.inStock ? 'ADD' : 'Out of Stock'),
                          ),
                        )
                      : _QtyControl(
                          qty: qty,
                          onMinus: () => ref
                              .read(cartNotifierProvider.notifier)
                              .updateQty(product.id, qty - 1),
                          onPlus: () => ref
                              .read(cartNotifierProvider.notifier)
                              .updateQty(product.id, qty + 1),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus, onPlus;
  const _QtyControl({required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.primary),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      _Btn(icon: Icons.remove, onTap: onMinus),
      Expanded(child: Text('$qty',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13))),
      _Btn(icon: Icons.add, onTap: onPlus),
    ]),
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 28, height: 32,
      child: Icon(icon, size: 16, color: AppColors.primary),
    ),
  );
}
