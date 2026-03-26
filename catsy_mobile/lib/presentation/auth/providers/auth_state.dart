import 'package:catsy_pos/domain/entities/staff.dart';

/// Possible authentication statuses.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Immutable authentication state.
class AuthState {
  final AuthStatus status;
  final Staff? staff;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.staff,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, Staff? staff, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      staff: staff ?? this.staff,
      errorMessage: errorMessage,
    );
  }

  /// Convenience factories.
  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated(Staff staff) =>
      AuthState(status: AuthStatus.authenticated, staff: staff);

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}
