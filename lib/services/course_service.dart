import 'package:dio/dio.dart';
import 'package:frontend/models/lecture_model.dart';
import '../config/api_config.dart';
import '../models/course_model.dart';
import 'auth_service.dart';

class CourseService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final AuthService _auth = AuthService();

  // ── Get all courses (with optional search + category) ──
  Future<List<CourseModel>> getCourses({
    String? search,
    String? category,
    int skip = 0,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiConfig.courses,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null) 'category': category,
        'skip': skip,
        'limit': limit,
      },
    );
    return (res.data as List).map((e) => CourseModel.fromJson(e)).toList();
  }

  // ── Get single course ──────────────────────────────────
  Future<CourseModel> getCourse(int id) async {
    final res = await _dio.get('${ApiConfig.courses}/$id');
    return CourseModel.fromJson(res.data);
  }

  // ── Check enrollment ───────────────────────────────────
  Future<bool> isEnrolled(int courseId) async {
    try {
      final token = await _auth.getAccessToken();
      if (token == null) return false; // ← not logged in

      final options = await _auth.authHeader();
      final res = await _dio.get(
        '${ApiConfig.courses}/$courseId/enrolled',
        options: options,
      );
      return res.data['enrolled'] ?? false;
    } catch (e) {
      return false; // ← never crash, just return false
    }
  }

  // ── Get my courses (instructor) ────────────────────────
  Future<List<CourseModel>> getMyCourses() async {
    final options = await _auth.authHeader();
    final res = await _dio.get(ApiConfig.myCourses, options: options);
    return (res.data as List).map((e) => CourseModel.fromJson(e)).toList();
  }

  Future<List<LectureModel>> getCourseLectures(int courseId) async {
    try {
      final res = await _dio.get('${ApiConfig.courses}/$courseId');
      final lectures = res.data['lectures'] as List? ?? [];
      return lectures
          .map((e) => LectureModel.fromJson(e, fallbackCourseId: courseId))
          .toList();
    } catch (e) {
      print('getCourseLectures error: $e');
      return [];
    }
  }
}
