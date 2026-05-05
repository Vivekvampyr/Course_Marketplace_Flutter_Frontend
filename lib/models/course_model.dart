class CourseModel {
  final int id;
  final String title;
  final String? description;
  final double price;
  final String? thumbnail;
  final String? category;
  final String level;
  final bool isPublished;
  final int instructorId;

  CourseModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.thumbnail,
    this.category,
    required this.level,
    required this.isPublished,
    required this.instructorId,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    price: (json['price'] as num).toDouble(),
    thumbnail: json['thumbnail'],
    category: json['category'],
    level: json['level'],
    isPublished: json['is_published'],
    instructorId: json['instructor_id'],
  );
}
