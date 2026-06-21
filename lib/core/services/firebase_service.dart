import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  static Stream<User?> get authStateChanges => auth.authStateChanges();

  static User? get currentUser => auth.currentUser;

  static String? get currentUserId => auth.currentUser?.uid;

  // Firestore helpers
  static CollectionReference<Map<String, dynamic>> collection(String path) =>
      firestore.collection(path);

  static DocumentReference<Map<String, dynamic>> doc(String path) =>
      firestore.doc(path);

  static Future<void> setDoc(
    String path,
    Map<String, dynamic> data, {
    bool merge = true,
  }) =>
      firestore.doc(path).set(data, SetOptions(merge: merge));

  static Future<void> updateDoc(String path, Map<String, dynamic> data) =>
      firestore.doc(path).update(data);

  static Future<void> deleteDoc(String path) => firestore.doc(path).delete();

  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();
}
