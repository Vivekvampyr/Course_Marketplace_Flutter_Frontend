import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class CartService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final AuthService _auth = AuthService();

  Future<List<dynamic>> getCart() async {
    final options = await _auth.authHeader();
    final res = await _dio.get(ApiConfig.cart, options: options);
    return res.data;
  }

  Future<void> addToCart(int courseId) async {
    final options = await _auth.authHeader();
    await _dio.post(
      ApiConfig.cartAdd,
      data: {'course_id': courseId},
      options: options,
    );
  }

  Future<void> removeFromCart(int courseId) async {
    final options = await _auth.authHeader();
    await _dio.delete('${ApiConfig.cart}/remove/$courseId', options: options);
  }

  Future<void> clearCart() async {
    final options = await _auth.authHeader();
    await _dio.delete(ApiConfig.cartClear, options: options);
  }
}
