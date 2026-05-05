import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

// Holds current logged-in user (null = not logged in)
final authStateProvider = StateNotifierProvider<AuthNotifier, UserModel?>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _service;
  AuthNotifier(this._service) : super(null) {
    _loadUser();
  }

  // Auto-load user on app start if token exists
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

  Future<void> login(String email, String password) async {
    final data = await _service.login(email: email, password: password);
    state = UserModel.fromJson(data['user']);
  }

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

  Future<void> logout() async {
    await _service.logout();
    state = null;
  }
}

// Convenience: is user logged in?
final isLoggedInProvider = Provider((ref) {
  return ref.watch(authStateProvider) != null;
});
