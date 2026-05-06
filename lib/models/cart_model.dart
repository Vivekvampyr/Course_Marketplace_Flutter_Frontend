class CartItemModel {
  final int id;
  final int courseId;
  final String addedAt;
  final CartCourseModel course;

  CartItemModel({
    required this.id,
    required this.courseId,
    required this.addedAt,
    required this.course,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    id: json['id'],
    courseId: json['course_id'],
    addedAt: json['added_at'],
    course: CartCourseModel.fromJson(json['course']),
  );
}

class CartCourseModel {
  final int id;
  final String title;
  final double price;
  final String? thumbnail;
  final String? category;
  final String level;

  CartCourseModel({
    required this.id,
    required this.title,
    required this.price,
    this.thumbnail,
    this.category,
    required this.level,
  });

  factory CartCourseModel.fromJson(Map<String, dynamic> json) =>
      CartCourseModel(
        id: json['id'],
        title: json['title'],
        price: (json['price'] as num).toDouble(),
        thumbnail: json['thumbnail'],
        category: json['category'],
        level: json['level'] ?? 'beginner',
      );
}
