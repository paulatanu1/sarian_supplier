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

  Future<void> seedCategories() => _repo.seedCategoriesIfEmpty();
}

final productsNotifierProvider =
    AsyncNotifierProvider<ProductsNotifier, void>(ProductsNotifier.new);
