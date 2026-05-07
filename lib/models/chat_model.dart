class ChatMessageModel {
  final String message;
  final String? response;
  final bool isUser;
  final DateTime createdAt;
  final bool isTyping;

  ChatMessageModel({
    required this.message,
    this.response,
    required this.isUser,
    required this.createdAt,
    this.isTyping = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        message: json['message'],
        response: json['response'],
        isUser: true,
        createdAt: DateTime.parse(json['created_at']),
      );
}
