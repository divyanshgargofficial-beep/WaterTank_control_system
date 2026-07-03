import 'package:water_tank_controller/models/app_user.dart';

class AuthState {
  const AuthState({
    required this.loading,
    required this.users,
    this.session,
    this.errorMessage,
  });

  const AuthState.loading()
    : loading = true,
      users = const [],
      session = null,
      errorMessage = null;

  final bool loading;
  final List<AppUser> users;
  final AuthSession? session;
  final String? errorMessage;

  bool get signedIn => session != null;

  AuthState copyWith({
    bool? loading,
    List<AppUser>? users,
    AuthSession? session,
    String? errorMessage,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      users: users ?? this.users,
      session: clearSession ? null : session ?? this.session,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
