import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/k.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cartRef(String uid) =>
      _db.collection(K.users).doc(uid).collection(K.cart);

  Stream<List<CartItem>> cartStream(String uid) =>
      _cartRef(uid).snapshots().map((s) => s.docs.map(CartItem.fromFirestore).toList());

  Future<void> addToCart(String uid, ProductModel product) async {
    final ref = _cartRef(uid).doc(product.id);
    final doc = await ref.get();
    if (doc.exists) {
      final current = CartItem.fromFirestore(doc);
      await ref.update({'quantity': current.quantity + 1, 'updatedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.set(CartItem(
        productId:   product.id,
        productName: product.name,
        composition: product.composition,
        company:     product.company,
        category:    product.category,
        imageUrl:    product.imageUrl,
        quantity:    1,
        updatedAt:   DateTime.now(),
      ).toMap());
    }
  }

  Future<void> updateQuantity(String uid, String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(uid, productId);
    } else {
      await _cartRef(uid).doc(productId).update({
        'quantity':  quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeItem(String uid, String productId) =>
      _cartRef(uid).doc(productId).delete();

  Future<void> clearCart(String uid) async {
    final snap  = await _cartRef(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) { batch.delete(doc.reference); }
    await batch.commit();
  }
}
