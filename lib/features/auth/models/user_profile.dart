/// User role enum per ROLE_BEHAVIOR_MATRIX
enum UserRole {
  admin,
  chaperone,
  protege;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'chaperone':
        return UserRole.chaperone;
      case 'protege':
      default:
        return UserRole.protege;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.chaperone:
        return 'Chaperone';
      case UserRole.protege:
        return 'Protégé';
    }
  }

  /// Check if user can create habits/tasks
  bool get canCreateContent => this == UserRole.admin || this == UserRole.chaperone;

  /// Check if user can assign to anyone (admin only)
  bool get canAssignToAnyone => this == UserRole.admin;

  /// Check if user can moderate community
  bool get canModerate => this == UserRole.admin;

  /// Check if user can invite users
  bool get canInviteUsers => this == UserRole.admin;
}

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final String language;
  final String? courseType;
  final UserRole role;
  final String? chaperoneId;
  final bool isActive;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    this.language = 'en',
    this.courseType,
    this.role = UserRole.protege,
    this.chaperoneId,
    this.isActive = false,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if profile is complete (has required fields filled)
  bool get isProfileComplete {
    return name.isNotEmpty && 
           phone != null && 
           phone!.isNotEmpty &&
           language.isNotEmpty;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      language: json['language'] as String? ?? 'en',
      courseType: json['course_type'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'protege'),
      chaperoneId: json['chaperone_id'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'language': language,
      'course_type': courseType,
      'role': role.name,
      'chaperone_id': chaperoneId,
      'is_active': isActive,
      'avatar_url': avatarUrl,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? address,
    String? language,
    String? courseType,
    UserRole? role,
    String? chaperoneId,
    bool? isActive,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      language: language ?? this.language,
      courseType: courseType ?? this.courseType,
      role: role ?? this.role,
      chaperoneId: chaperoneId ?? this.chaperoneId,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
