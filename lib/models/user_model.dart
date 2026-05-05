class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final bool isActive;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    role: json['role'],
    avatar: json['avatar'],
    isActive: json['is_active'] ?? true,
    createdAt: json['created_at'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'avatar': avatar,
    'is_active': isActive,
    'created_at': createdAt,
  };

  bool get isInstructor => role == 'instructor';
  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';
}
