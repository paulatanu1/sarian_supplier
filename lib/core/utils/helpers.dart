import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String generateOrderNumber() {
  final date = DateFormat('yyyyMMdd').format(DateTime.now());
  final rand = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
  return 'ORD-$date-$rand';
}

/// Returns gradient index from a string (used for category/product cards).
int gradientIndexFor(String text) => text.codeUnits.fold(0, (a, b) => a + b) % 9;

/// Converts a Firestore Timestamp or DateTime to DateTime safely.
DateTime? tsToDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

/// Validates that a phone number is unique in a Firestore collection.
Future<bool> isPhoneUnique(
  FirebaseFirestore db,
  String collection,
  String phone, {
  String? excludeUid,
}) async {
  var q = db.collection(collection).where('phone', isEqualTo: phone);
  final snap = await q.get();
  if (snap.docs.isEmpty) return true;
  if (excludeUid != null && snap.docs.length == 1 && snap.docs.first.id == excludeUid) {
    return true;
  }
  return false;
}

/// Validates that owner+phone combination is unique.
Future<bool> isOwnerPhoneUnique(
  FirebaseFirestore db,
  String collection,
  String ownerName,
  String phone, {
  String? excludeUid,
}) async {
  final snap = await db
      .collection(collection)
      .where('phone', isEqualTo: phone)
      .where('name', isEqualTo: ownerName)
      .get();
  if (snap.docs.isEmpty) return true;
  if (excludeUid != null && snap.docs.length == 1 && snap.docs.first.id == excludeUid) {
    return true;
  }
  return false;
}
