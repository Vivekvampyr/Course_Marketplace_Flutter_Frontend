import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // flutter_secure_storage web config
    _storage = const FlutterSecureStorage(
      webOptions: WebOptions(dbName: 'course_marketplace', publicKey: 'cm_key'),
    );

    // Google Sign In — web only needs clientId
    _googleSignIn =
        kIsWeb
            ? GoogleSignIn(clientId: ApiConfig.googleWebClientId)
            : GoogleSignIn(serverClientId: ApiConfig.googleWebClientId);
  }

  // ── Token Management ───────────────────────────────────
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');
  Future<void> clearTokens() => _storage.deleteAll();

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<Options> authHeader() async {
    final token = await getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ── Register ───────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    try {
      final res = await _dio.post(
        ApiConfig.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      await saveTokens(res.data['access_token'], res.data['refresh_token']);
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Login ──────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // OAuth2PasswordRequestForm expects form data with "username" field
      final res = await _dio.post(
        ApiConfig.login,
        data: FormData.fromMap({
          'username': email, // ← OAuth2 uses "username" not "email"
          'password': password,
        }),
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
      await saveTokens(res.data['access_token'], res.data['refresh_token']);
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Google Sign In ─────────────────────────────────────
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in cancelled');

      final googleAuth = await googleUser.authentication;

      // Web uses accessToken, Android uses idToken
      final token = kIsWeb ? googleAuth.accessToken : googleAuth.idToken;

      if (token == null) throw Exception('Failed to get Google token');

      final res = await _dio.post(
        ApiConfig.googleMobile,
        data: {
          'id_token': kIsWeb ? null : token,
          'access_token': kIsWeb ? token : null,
          'is_web': kIsWeb,
        },
      );

      await saveTokens(res.data['access_token'], res.data['refresh_token']);
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ── Refresh Token ──────────────────────────────────────
  Future<void> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return;
      final res = await _dio.post(
        ApiConfig.refresh,
        data: {'refresh_token': refreshToken},
      );
      await _storage.write(
        key: 'access_token',
        value: res.data['access_token'],
      );
    } catch (_) {}
  }

  // ── Get Profile ────────────────────────────────────────
  Future<UserModel> getProfile() async {
    try {
      final options = await authHeader();
      final res = await _dio.get(ApiConfig.profile, options: options);
      return UserModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Logout ─────────────────────────────────────────────
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await clearTokens();
  }

  // ── Error Handler ──────────────────────────────────────
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final detail = e.response?.data['detail'];
      return Exception(detail ?? 'Something went wrong');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Cannot connect to server. Is it running?');
    }
    return Exception(e.message ?? 'Unknown error');
  }
}
