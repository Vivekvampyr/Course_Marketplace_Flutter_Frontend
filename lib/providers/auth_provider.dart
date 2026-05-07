import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, UserModel?>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _service;

  AuthNotifier(this._service) : super(null) {
    _loadUser();
  }

  // ── Auto-load user on app start ──────────────────────
  Future<void> _loadUser() async {
    try {
      final token = await _service.getAccessToken();
      if (token != null) {
        state = await _service.getProfile();
      }
    } catch (_) {
      state = null;
    }
  }

  // ── Email Login ──────────────────────────────────────
  Future<void> login(String email, String password) async {
    final data = await _service.login(email: email, password: password);
    state = UserModel.fromJson(data['user']);
  }

  // ── Register ─────────────────────────────────────────
  Future<void> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final data = await _service.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    state = UserModel.fromJson(data['user']);
  }

  // ── Google Sign In ───────────────────────────────────
  Future<void> signInWithGoogle() async {
    final data = await _service.signInWithGoogle();
    state = UserModel.fromJson(data['user']);
  }

  // ── Refresh Profile ──────────────────────────────────
  Future<void> refreshProfile() async {
    try {
      final user = await _service.getProfile();
      state = user;
    } catch (_) {}
  }

  // ── Logout ───────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
    state = null;
  }

  // ── Getters ──────────────────────────────────────────
  UserModel? get user => state;
  bool get isLoggedIn => state != null;
}

// ── Convenience providers ──────────────────────────────
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) != null;
});
