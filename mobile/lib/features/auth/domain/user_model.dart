class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'ADMIN' or 'SERVANT'
  final bool isActive;
  final String? classId;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.classId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? '',
      role: json['role'] ?? 'SERVANT',
      isActive: json['isActive'] ?? false,
      classId: json['classId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'classId': classId,
    };
  }
}
