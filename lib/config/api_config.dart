import 'package:flutter/foundation.dart';

class ApiConfig {
  // ── Base URLs (auto-switch by platform) ───────────────
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000'; // Android emulator
  }

  static String get wsUrl {
    if (kIsWeb) return 'ws://localhost:8000';
    return 'ws://10.0.2.2:8000';
  }

  // ── Google Client IDs ──────────────────────────────────
  static const String googleWebClientId =
      '672502992021-g7016rmmt9eqvr4i8f9ve377rphsvkbi.apps.googleusercontent.com';
  static const String googleAndroidClientId =
      '672502992021-jbrd4mcjvibpt1q1tkj08tglpks9jio3.apps.googleusercontent.com';

  // Google Sign In uses Web Client ID on both platforms
  // Android additionally needs the Android Client ID registered in console
  static String get googleClientId => googleWebClientId;

  // Add this to ApiConfig class
  static const String razorpayKeyId = 'rzp_test_Sm2L7AxCzK8qGu'; // from .env

  // ── Auth ───────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String googleMobile = '/auth/google/mobile';

  // ── Users ──────────────────────────────────────────────
  static const String profile = '/users/me';
  static const String avatar = '/users/me/avatar';
  static const String enrollments = '/users/me/enrollments';

  // ── Courses ────────────────────────────────────────────
  static const String courses = '/courses';
  static const String myCourses = '/courses/my/courses';

  // ── Cart ───────────────────────────────────────────────
  static const String cart = '/cart';
  static const String cartAdd = '/cart/add';
  static const String cartClear = '/cart/clear';

  // ── Payments ───────────────────────────────────────────
  static const String createOrder = '/payments/create-order';
  static const String verifyPay = '/payments/verify';
  static const String orders = '/payments/orders';

  // ── Reviews ────────────────────────────────────────────
  static const String reviews = '/reviews';

  // ── Chat ───────────────────────────────────────────────
  static const String chatAsk = '/chat/ask';
  static const String chatHistory = '/chat/history';
  static String chatWs(String token) => '$wsUrl/chat/ws/$token';
}
