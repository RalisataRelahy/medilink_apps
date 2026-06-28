import 'package:medilink/features/auth/data/models/user_model.dart';
import 'package:medilink/shared/enums/user_role.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final UserRole? role;
  final String? error;
  const AuthState({
    this.isLoading = false,
    this.user,
    this.role,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    UserRole? role,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      role: role ?? this.role,
      error: error,
    );
  }
}