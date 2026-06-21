import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final authRepoProvider = Provider((_) => AuthRepository());

final firebaseUserProvider = StreamProvider<User?>(
  (ref) => ref.read(authRepoProvider).authStateChanges,
);

final appUserProvider = StreamProvider<AppUser?>((ref) {
  final firebaseUser = ref.watch(firebaseUserProvider);
  // Still loading Firebase auth state — don't emit yet
  if (firebaseUser.isLoading) return const Stream.empty();
  final uid = firebaseUser.asData?.value?.uid;
  // Not logged in — emit null immediately so router/splash can navigate
  if (uid == null) return Stream.value(null);
  return ref.read(authRepoProvider).userStream(uid);
});

// ── Auth Notifier ─────────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepoProvider);

  @override
  Future<AppUser?> build() async => null;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.signIn(email, password));
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(null);
  }

  Future<void> sendReset(String email) => _repo.sendPasswordReset(email);

  Future<void> completeProfile({
    required String name,
    required String shopName,
    required String phone,
  }) async {
    final uid   = _repo.uid!;
    final email = _repo.currentUser!.email!;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.completeProfile(
        uid: uid, email: email,
        name: name, shopName: shopName, phone: phone,
      ),
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = _repo.uid!;
    await _repo.updateUser(uid, data);
  }

  Future<AppUser> adminCreateUser({
    required String email,
    required String password,
    required String name,
    required String shopName,
    required String phone,
  }) =>
      _repo.adminCreateUser(
        email: email, password: password,
        name: name, shopName: shopName, phone: phone,
      );
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

// ── Users list (admin) ───────────────────────────────────────────────────
final allUsersProvider = StreamProvider(
  (ref) => ref.read(authRepoProvider).allUsersStream(),
);
