class ReviewModel {
  final int id;
  final int userId;
  final int courseId;
  final int rating;
  final String? comment;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'],
    userId: json['user_id'],
    courseId: json['course_id'],
    rating: json['rating'],
    comment: json['comment'],
    createdAt: json['created_at'],
  );
}
