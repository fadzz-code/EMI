enum UserRole {
  admin('admin'),
  teacher('teacher'),
  student('student'),
  unknown('unknown');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.unknown,
    );
  }
}

class SessionUser {
  const SessionUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.activeClassName,
    this.activeSchoolName,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final UserRole role;
  final String status;
  final String? activeClassName;
  final String? activeSchoolName;

  bool get isApproved => status == 'approved';

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    final activeClass = json['active_class'];
    final activeSchool = json['active_school'];

    return SessionUser(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: UserRole.fromValue(json['role'] as String?),
      status: json['status'] as String? ?? '',
      activeClassName: activeClass is Map<String, dynamic>
          ? activeClass['name'] as String?
          : null,
      activeSchoolName: activeSchool is Map<String, dynamic>
          ? activeSchool['name'] as String?
          : null,
    );
  }
}
