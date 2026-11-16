enum UserRole { administrator, familyMember }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.active = true,
  });

  final String id;
  final String name;
  final UserRole role;
  final bool active;

  bool get isAdmin => role == UserRole.administrator;

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role.name, 'active': active};
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.familyMember,
      ),
      active: json['active'] as bool? ?? true,
    );
  }
}

class AuthSession {
  const AuthSession({required this.user});

  final AppUser user;
}
