import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/k.dart';
import '../core/utils/helpers.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _db.collection(K.users).doc(uid).get();
    return doc.exists ? AppUser.fromFirestore(doc) : null;
  }

  Stream<AppUser?> userStream(String uid) => _db
      .collection(K.users)
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromFirestore(d) : null);

  Future<AppUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final user = await fetchUser(cred.user!.uid);
    if (user == null) throw Exception('User record not found in Firestore.');
    if (!user.isActive) throw Exception('Your account has been deactivated.');
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<AppUser> completeProfile({
    required String uid,
    required String email,
    required String name,
    required String shopName,
    required String phone,
  }) async {
    if (!await isPhoneUnique(_db, K.users, phone, excludeUid: uid)) {
      throw Exception('This mobile number is already registered.');
    }
    if (!await isOwnerPhoneUnique(_db, K.users, name, phone, excludeUid: uid)) {
      throw Exception('Owner name + mobile combination already exists.');
    }
    final data = {
      'name':             name,
      'shopName':         shopName,
      'email':            email,
      'phone':            phone,
      'role':             K.roleUser,
      'profileCompleted': true,
      'isActive':         true,
      'createdAt':        FieldValue.serverTimestamp(),
    };
    await _db.collection(K.users).doc(uid).set(data, SetOptions(merge: true));
    final doc = await _db.collection(K.users).doc(uid).get();
    return AppUser.fromFirestore(doc);
  }

  /// Creates a new user WITHOUT disturbing the current admin session.
  /// Uses a secondary FirebaseApp instance so the admin stays signed in.
  Future<AppUser> adminCreateUser({
    required String email,
    required String password,
    required String name,
    required String shopName,
    required String phone,
  }) async {
    if (!await isPhoneUnique(_db, K.users, phone)) {
      throw Exception('This mobile number is already registered.');
    }
    if (!await isOwnerPhoneUnique(_db, K.users, name, phone)) {
      throw Exception('Owner name + mobile combination already exists.');
    }

    // Use a throw-away secondary FirebaseApp so the admin session is untouched.
    final secondaryApp = await Firebase.initializeApp(
      name:    'userCreate_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final cred = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
            email:    email.trim(),
            password: password,
          );

      final newUid = cred.user!.uid;
      await _db.collection(K.users).doc(newUid).set({
        'name':             name,
        'shopName':         shopName,
        'email':            email.trim(),
        'phone':            phone,
        'role':             K.roleUser,
        'profileCompleted': true,
        'isActive':         true,
        'createdAt':        FieldValue.serverTimestamp(),
      });

      final doc = await _db.collection(K.users).doc(newUid).get();
      return AppUser.fromFirestore(doc);
    } finally {
      // Always clean up the secondary app whether the call succeeded or failed.
      await secondaryApp.delete();
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection(K.users).doc(uid).update(data);

  Stream<List<AppUser>> allUsersStream() => _db
      .collection(K.users)
      .where('role', isEqualTo: K.roleUser)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromFirestore).toList());
}
