import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final AuthService _auth = AuthService();

  Future<List<dynamic>> getEnrollments() async {
    final options = await _auth.authHeader();
    final res = await _dio.get(ApiConfig.enrollments, options: options);
    return res.data as List;
  }

  Future<UserModel> uploadAvatar(dynamic imageFile) async {
    final options = await _auth.authHeader();
    final formData = FormData.fromMap({'avatar': imageFile});
    final res = await _dio.post(
      ApiConfig.avatar,
      data: formData,
      options: Options(
        headers: {...?options.headers, 'Content-Type': 'multipart/form-data'},
      ),
    );
    return UserModel.fromJson(res.data);
  }
}
