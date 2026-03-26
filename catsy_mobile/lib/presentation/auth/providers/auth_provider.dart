import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../data/local/providers.dart';
import '../../../data/local/secure_storage/secure_storage_service.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

// ── Auth Repository Provider ────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authDao: ref.watch(authDaoProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
    apiClient: ref.watch(apiClientProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

// ── Auth Notifier ───────────────────────────────────────────────────────────

/// Riverpod Notifier that manages authentication lifecycle.
///
/// All session checks hit local storage / SQLite first (offline-first).
/// Remote validation is deferred to Phase 12.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.initial();

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  // ── Session Check (splash screen calls this) ───────────────────────
  Future<void> checkSession() async {
    state = AuthState.loading();

    final isAuthed = await _authRepository.isAuthenticated();
    if (!isAuthed) {
      state = AuthState.unauthenticated();
      return;
    }

    // Token exists — try loading cached staff profile
    final result = await _authRepository.getCurrentStaff();
    result.fold((failure) => state = AuthState.unauthenticated(), (staff) {
      if (staff != null) {
        state = AuthState.authenticated(staff);
      } else {
        state = AuthState.unauthenticated();
      }
    });
  }

  // ── Login ──────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    state = AuthState.loading();

    final result = await _authRepository.login(email, password);
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (staff) => state = AuthState.authenticated(staff),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────
  Future<void> logout() async {
    state = AuthState.loading();

    final result = await _authRepository.logout();
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (_) => state = AuthState.unauthenticated(),
    );
  }
}

/// Global provider for [AuthNotifier].
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
