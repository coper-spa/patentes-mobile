import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inspector_profile.dart';
import 'app_providers.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.profile,
    this.errorMessage,
    this.isBusy = false,
  });

  final AuthStatus status;
  final InspectorProfile? profile;
  final String? errorMessage;
  final bool isBusy;

  AuthState copyWith({
    AuthStatus? status,
    InspectorProfile? profile,
    String? errorMessage,
    bool? isBusy,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(const AuthState(status: AuthStatus.checking));

  final Ref ref;
  static const Duration _sessionRestoreTimeout = Duration(seconds: 12);
  static const Duration _profileLoadTimeout = Duration(seconds: 10);
  static const Duration _loginTimeout = Duration(minutes: 3);

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.checking, errorMessage: null);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final hasSession = await authRepository
          .restoreSession()
          .timeout(_sessionRestoreTimeout);

      if (!hasSession) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final profile = await authRepository
          .getProfile()
          .timeout(_profileLoadTimeout);
      state = AuthState(status: AuthStatus.authenticated, profile: profile);
    } on TimeoutException {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'No se pudo recuperar la sesion a tiempo. Revisa tu conexion e inicia sesion nuevamente.',
      );
    } catch (e) {
      try {
        final authRepository = ref.read(authRepositoryProvider);
        await authRepository.logout();
      } catch (_) {
        // Si falla provider/config, igual salimos del estado checking.
      }

      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> login() async {
    state = state.copyWith(isBusy: true, errorMessage: null);

    final authRepository = ref.read(authRepositoryProvider);
    try {
      await authRepository.loginWithPkce().timeout(_loginTimeout);
      final profile = await authRepository
          .getProfile()
          .timeout(_profileLoadTimeout);
      state = AuthState(
        status: AuthStatus.authenticated,
        profile: profile,
        isBusy: false,
      );
    } on TimeoutException {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'La autenticacion tardo demasiado. Intenta nuevamente.',
        isBusy: false,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
        isBusy: false,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isBusy: true, errorMessage: null);

    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();

    state = const AuthState(status: AuthStatus.unauthenticated, isBusy: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
