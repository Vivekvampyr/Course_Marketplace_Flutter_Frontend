import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../models/chat_model.dart';
import 'auth_service.dart';

class ChatService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final AuthService _auth = AuthService();

  WebSocketChannel? _channel;

  // ── REST: Ask AI ───────────────────────────────────────
  Future<String> askAI(String message, {int? courseId}) async {
    final options = await _auth.authHeader();
    final res = await _dio.post(
      ApiConfig.chatAsk,
      data: {'message': message, if (courseId != null) 'course_id': courseId},
      options: options,
    );
    return res.data['response'];
  }

  // ── REST: Get history ──────────────────────────────────
  Future<List<ChatMessageModel>> getChatHistory() async {
    final options = await _auth.authHeader();
    final res = await _dio.get(ApiConfig.chatHistory, options: options);
    return (res.data as List).map((e) => ChatMessageModel.fromJson(e)).toList();
  }

  // ── REST: Clear history ────────────────────────────────
  Future<void> clearHistory() async {
    final options = await _auth.authHeader();
    await _dio.delete(ApiConfig.chatHistory, options: options);
  }

  // ── WebSocket: Connect ─────────────────────────────────
  Future<WebSocketChannel> connectWebSocket() async {
    final token = await _auth.getAccessToken();
    final url = ApiConfig.chatWs(token ?? '');
    _channel = WebSocketChannel.connect(Uri.parse(url));
    return _channel!;
  }

  void sendMessage(String message) {
    _channel?.sink.add('{"message": "$message"}');
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
