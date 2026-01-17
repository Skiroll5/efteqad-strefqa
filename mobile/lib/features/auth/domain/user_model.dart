class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'ADMIN' or 'SERVANT'
  final bool isActive;
  final String? classId;
  final String? whatsappTemplate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.classId,
    this.whatsappTemplate,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? '',
      role: json['role'] ?? 'SERVANT',
      isActive: json['isActive'] ?? false,
      classId: json['classId'],
      whatsappTemplate: json['whatsappTemplate'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
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
      'whatsappTemplate': whatsappTemplate,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({String? name, String? whatsappTemplate, DateTime? updatedAt}) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role,
      isActive: isActive,
      classId: classId,
      whatsappTemplate: whatsappTemplate ?? this.whatsappTemplate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
