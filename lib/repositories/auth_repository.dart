import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:water_tank_controller/models/app_user.dart';

class AuthRepository {
  AuthRepository(this._storage);

  final FlutterSecureStorage _storage;

  static const _usersKey = 'auth.users.v1';
  static const _activeUserKey = 'auth.activeUserId.v1';

  Future<AuthSession?> restoreSession() async {
    await _ensureDefaults();
    final activeId = await _storage.read(key: _activeUserKey);
    if (activeId == null) return null;
    final users = await loadUsers();
    final user = users.where((item) => item.id == activeId && item.active);
    if (user.isEmpty) return null;
    return AuthSession(user: user.first);
  }

  Future<List<AppUser>> loadUsers() async {
    await _ensureDefaults();
    final records = await _loadRecords();
    return records.map((item) => item.user).toList();
  }

  Future<AuthSession> login(String userId, String password) async {
    await _ensureDefaults();
    final records = await _loadRecords();
    final record = records.firstWhere(
      (item) => item.user.id == userId && item.user.active,
      orElse: () => throw AuthException('Invalid credentials.'),
    );
    if (record.passwordHash != _hash(password, record.salt)) {
      throw AuthException('Invalid credentials.');
    }
    await _storage.write(key: _activeUserKey, value: record.user.id);
    return AuthSession(user: record.user);
  }

  Future<void> logout() => _storage.delete(key: _activeUserKey);

  Future<void> changePassword(String userId, String password) async {
    final records = await _loadRecords();
    final index = records.indexWhere((item) => item.user.id == userId);
    if (index == -1) throw AuthException('User not found.');
    final salt = _newSalt();
    records[index] = records[index].copyWith(
      salt: salt,
      passwordHash: _hash(password, salt),
    );
    await _saveRecords(records);
  }

  Future<void> addUser({
    required String name,
    required UserRole role,
    required String password,
  }) async {
    final records = await _loadRecords();
    final id = _slug(name);
    if (records.any((item) => item.user.id == id)) {
      throw AuthException('A user with this name already exists.');
    }
    final salt = _newSalt();
    records.add(
      _CredentialRecord(
        user: AppUser(id: id, name: name.trim(), role: role, active: true),
        salt: salt,
        passwordHash: _hash(password, salt),
      ),
    );
    await _saveRecords(records);
  }

  Future<void> removeUser(String userId) async {
    if (userId == 'admin' || userId == 'family') {
      throw AuthException('Built-in users can be renamed but not removed.');
    }
    final records = await _loadRecords();
    await _saveRecords(
      records.where((item) => item.user.id != userId).toList(),
    );
  }

  Future<void> _ensureDefaults() async {
    final raw = await _storage.read(key: _usersKey);
    if (raw != null) return;
    await _saveRecords([
      _record('admin', 'Administrator', UserRole.administrator, 'admin123'),
      _record('family', 'Family Member', UserRole.familyMember, 'family123'),
    ]);
  }

  _CredentialRecord _record(
    String id,
    String name,
    UserRole role,
    String password,
  ) {
    final salt = _newSalt();
    return _CredentialRecord(
      user: AppUser(id: id, name: name, role: role, active: true),
      salt: salt,
      passwordHash: _hash(password, salt),
    );
  }

  Future<List<_CredentialRecord>> _loadRecords() async {
    final raw = await _storage.read(key: _usersKey);
    final decoded = jsonDecode(raw ?? '[]') as List<dynamic>;
    return decoded
        .map((item) => _CredentialRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveRecords(List<_CredentialRecord> records) async {
    await _storage.write(
      key: _usersKey,
      value: jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _slug(String input) {
    final slug = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty
        ? 'user-${DateTime.now().millisecondsSinceEpoch}'
        : slug;
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _CredentialRecord {
  const _CredentialRecord({
    required this.user,
    required this.salt,
    required this.passwordHash,
  });

  final AppUser user;
  final String salt;
  final String passwordHash;

  _CredentialRecord copyWith({String? salt, String? passwordHash}) {
    return _CredentialRecord(
      user: user,
      salt: salt ?? this.salt,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user.toJson(), 'salt': salt, 'passwordHash': passwordHash};
  }

  factory _CredentialRecord.fromJson(Map<String, dynamic> json) {
    return _CredentialRecord(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      salt: '${json['salt']}',
      passwordHash: '${json['passwordHash']}',
    );
  }
}
