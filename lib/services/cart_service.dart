import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/cart_model.dart';
import 'auth_service.dart';

class CartService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final AuthService _auth = AuthService();

  Future<List<CartItemModel>> getCart() async {
    final options = await _auth.authHeader();
    final res = await _dio.get(ApiConfig.cart, options: options);
    return (res.data as List).map((e) => CartItemModel.fromJson(e)).toList();
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

  Future<Map<String, dynamic>> createRazorpayOrder() async {
    final options = await _auth.authHeader();
    final res = await _dio.post(ApiConfig.createOrder, options: options);
    return res.data;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final options = await _auth.authHeader();
    final res = await _dio.post(
      ApiConfig.verifyPay,
      data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
      options: options,
    );
    return res.data;
  }
}
