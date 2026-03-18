import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/data/api/token_storage.dart';
import 'package:dompis_app/data/api/auth_api.dart';
import 'package:dompis_app/providers/api_providers.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? role;
  final String? error;
  final bool needsAttendanceCheck;

  const AuthState({
    this.status = AuthStatus.initial,
    this.role,
    this.error,
    this.needsAttendanceCheck = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? role,
    String? error,
    bool? needsAttendanceCheck,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      error: error,
      needsAttendanceCheck: needsAttendanceCheck ?? this.needsAttendanceCheck,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._authApi, this._tokenStorage)
      : super(const AuthState());

  /// Check if user is already authenticated on app start
  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    final hasToken = await _tokenStorage.hasToken();
    if (!hasToken) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final role = await _tokenStorage.getRole();
    state = state.copyWith(
      status: AuthStatus.authenticated,
      role: role,
    );
  }

  /// Login with username and password
  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final data = await _authApi.login(username, password);

      if (data['success'] == true) {
        final role = data['role'] as String? ?? '';
        final needsAttendance =
            data['needsAttendanceCheck'] as bool? ?? false;

        state = state.copyWith(
          status: AuthStatus.authenticated,
          role: role,
          needsAttendanceCheck: needsAttendance,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: data['message'] as String? ?? 'Login failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Login failed. Check your connection.',
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authApi.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = ref.watch(authApiProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(authApi, tokenStorage);
});
