import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/review_model.dart';
import 'auth_service.dart';

class ReviewService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final AuthService _auth = AuthService();

  Future<List<ReviewModel>> getCourseReviews(int courseId) async {
    final res = await _dio.get('${ApiConfig.reviews}/course/$courseId');
    return (res.data as List).map((e) => ReviewModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getCourseRating(int courseId) async {
    final res = await _dio.get('${ApiConfig.reviews}/course/$courseId/rating');
    return res.data;
  }

  Future<void> createReview({
    required int courseId,
    required int rating,
    String? comment,
  }) async {
    final options = await _auth.authHeader();
    await _dio.post(
      ApiConfig.reviews,
      data: {'course_id': courseId, 'rating': rating, 'comment': comment},
      options: options,
    );
  }
}
