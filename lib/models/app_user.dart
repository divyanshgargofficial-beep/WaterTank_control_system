enum UserRole { administrator, familyMember }

extension UserRoleLabels on UserRole {
  String get label {
    return switch (this) {
      UserRole.administrator => 'Administrator',
      UserRole.familyMember => 'Family Member',
    };
  }

  bool get canControlPump => this == UserRole.administrator;
  bool get canModifySettings => this == UserRole.administrator;
  bool get canManageUsers => this == UserRole.administrator;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
  });

  final String id;
  final String name;
  final UserRole role;
  final bool active;

  AppUser copyWith({String? name, UserRole? role, bool? active}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role.name, 'active': active};
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: '${json['id']}',
      name: '${json['name']}',
      role: UserRole.values.firstWhere(
        (item) => item.name == json['role'],
        orElse: () => UserRole.familyMember,
      ),
      active: json['active'] != false,
    );
  }
}

class AuthSession {
  const AuthSession({required this.user});

  final AppUser user;
}
