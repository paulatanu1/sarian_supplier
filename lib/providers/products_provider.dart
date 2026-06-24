import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../repositories/products_repository.dart';

final productsRepoProvider = Provider((_) => ProductsRepository());

final selectedCategoryProvider = StateProvider<String>((_) => '');

final categoriesProvider = StreamProvider<List<CategoryModel>>(
  (ref) => ref.read(productsRepoProvider).categoriesStream(),
);

/// Always returns a non-empty category list. Uses Firestore stream when it has
/// data; falls back to the local [kDefaultCategories] list otherwise so the
/// UI never shows an empty sidebar.
final effectiveCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final remote = ref.watch(categoriesProvider).asData?.value ?? const [];
  if (remote.isNotEmpty) return remote;
  // Fallback: build CategoryModel list from the hard-coded defaults.
  return kDefaultCategories.asMap().entries.map((entry) {
    final i = entry.key;
    final c = entry.value;
    return CategoryModel(
      id:        'local-$i',
      name:      c['name'] as String,
      shortName: (c['shortName'] as String?) ?? c['name'] as String,
      icon:      c['icon'] as String,
      order:     (c['order'] as int?) ?? i,
      isActive:  true,
    );
  }).toList();
});

/// All active products (no category filter). Sorted by name.
/// Category filtering happens client-side in the UI for resilience against
/// products whose `category` field doesn't match a seeded category.
final allActiveProductsProvider = StreamProvider<List<ProductModel>>(
  (ref) => ref.read(productsRepoProvider).productsStream(),
);

/// Sorted unique non-empty category values *as they appear on products* in
/// Firestore. This is the source of truth for the sidebar — whatever an
/// admin writes into a product's `category` field shows up here.
final productCategoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(allActiveProductsProvider).asData?.value
      ?? const [];
  final set = <String>{};
  for (final p in products) {
    final c = p.category.trim();
    if (c.isNotEmpty) set.add(c);
  }
  return set.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
});

/// Same list but with per-category counts of active products.
final productCategoryCountsProvider = Provider<Map<String, int>>((ref) {
  final products = ref.watch(allActiveProductsProvider).asData?.value
      ?? const [];
  final counts = <String, int>{};
  for (final p in products) {
    final key = p.category.trim();
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
});

@Deprecated('Use allActiveProductsProvider + client-side filter')
final productsProvider = StreamProvider.family<List<ProductModel>, String>(
  (ref, category) =>
      ref.read(productsRepoProvider).productsStream(category: category),
);

final allProductsAdminProvider = StreamProvider<List<ProductModel>>(
  (ref) => ref.read(productsRepoProvider).allProductsAdminStream(),
);

final productSearchProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) =>
        ref.read(productsRepoProvider).searchProducts(query));

final productByIdProvider =
    StreamProvider.family<ProductModel?, String>((ref, id) =>
        ref.read(productsRepoProvider).productByIdStream(id));

// ── Products Notifier (admin CRUD) ────────────────────────────────────────
class ProductsNotifier extends AsyncNotifier<void> {
  ProductsRepository get _repo => ref.read(productsRepoProvider);

  @override
  Future<void> build() async {}

  Future<String> add(ProductModel p, {File? image}) =>
      _repo.addProduct(p, image: image);

  Future<void> editProduct(String id, Map<String, dynamic> data, {File? image}) =>
      _repo.updateProduct(id, data, image: image);

  Future<void> delete(String id) => _repo.deleteProduct(id);

  Future<void> toggle(String id, bool active) => _repo.toggleProduct(id, active);

  Future<void> seedCategories()    => _repo.seedCategoriesIfEmpty();
  Future<int>  resyncCategories()  => _repo.resyncCategories();

  Future<(int, int)> seedSampleProducts() => _repo.seedSampleProducts();
}

final productsNotifierProvider =
    AsyncNotifierProvider<ProductsNotifier, void>(ProductsNotifier.new);
