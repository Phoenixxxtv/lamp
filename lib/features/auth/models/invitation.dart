/// Invitation model for invite-only onboarding
class Invitation {
  final String id;
  final String email;
  final String name;
  final String role;
  final String inviteCode;
  final DateTime expiresAt;
  final bool used;
  final String? createdBy;
  final DateTime createdAt;

  const Invitation({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.inviteCode,
    required this.expiresAt,
    this.used = false,
    this.createdBy,
    required this.createdAt,
  });

  /// Check if invitation is still valid
  bool get isValid => !used && DateTime.now().isBefore(expiresAt);

  /// Check if invitation is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      inviteCode: json['invite_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      used: json['used'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'invite_code': inviteCode,
      'expires_at': expiresAt.toIso8601String(),
      'used': used,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
