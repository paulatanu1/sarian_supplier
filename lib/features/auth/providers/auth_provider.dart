import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../models/user_model.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;
  final doc = await FirebaseService.collection(AppConstants.usersCollection)
      .doc(user.uid)
      .get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});

class AuthNotifier extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() => const AsyncValue.data(null);

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cred = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      final ref = FirebaseService.collection(AppConstants.usersCollection).doc(uid);
      final doc = await ref.get();

      if (!doc.exists) {
        // Auto-create user doc on first login
        await ref.set({
          'name': cred.user!.displayName ?? email.split('@').first,
          'email': email.trim(),
          'phone': cred.user!.phoneNumber ?? '',
          'role': AppConstants.roleSupplier,
          'isActive': true,
          'photoUrl': cred.user!.photoURL,
          'createdAt': FirebaseService.serverTimestamp,
        });
        final created = await ref.get();
        return UserModel.fromFirestore(created);
      }

      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> signOut() async {
    await FirebaseService.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    await FirebaseService.auth.sendPasswordResetEmail(email: email.trim());
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(AuthNotifier.new);
