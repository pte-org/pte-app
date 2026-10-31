import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/proactive_refresh_scheduler.dart';
import 'package:pte_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';

/// No `BuildContext` here — expired-session/logout side effects (e.g.
/// navigating to a login screen) are driven by the UI listening to this
/// bloc's state changes, never by the bloc itself.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required ProactiveRefreshScheduler scheduler,
  }) : _repository = repository,
       _scheduler = scheduler,
       super(const AuthIdle()) {
    on<LoginRequested>(_onLoginRequested);
    on<PasswordChangeSubmitted>(_onPasswordChangeSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;
  final ProactiveRefreshScheduler _scheduler;
  bool _isAuthenticating = false;

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_isAuthenticating) {
      return;
    }
    _isAuthenticating = true;
    emit(const AuthAuthenticating());
    try {
      final claims = await _repository.login(
        email: event.email,
        password: event.password,
      );
      _scheduler.scheduleFromTokenStore();
      emit(
        claims.mustChangePassword
            ? AuthPasswordChangeRequired(claims)
            : AuthAuthenticated(claims),
      );
    } catch (e) {
      // Any failure here — a mapped ApiException or an unexpected shape
      // error from a malformed 2xx body — must still reach AuthError;
      // otherwise the bloc is stranded in AuthAuthenticating forever with
      // no route back to a state the UI can act on (QUAL-103, Phase 1
      // quality gate).
      emit(
        AuthError(e is ApiException ? e : UnknownApiException(e.toString())),
      );
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Only meaningful while a temporary password is waiting to be replaced; a
  /// second submit while one is in flight, or from any other state, is ignored.
  Future<void> _onPasswordChangeSubmitted(
    PasswordChangeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final claims = switch (state) {
      AuthPasswordChangeRequired(:final claims) => claims,
      AuthPasswordChangeFailed(:final claims) => claims,
      _ => null,
    };
    if (claims == null) {
      return;
    }
    emit(AuthPasswordChanging(claims));
    try {
      await _repository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(AuthAuthenticated(claims.copyWith(mustChangePassword: false)));
    } catch (e) {
      emit(
        AuthPasswordChangeFailed(
          claims,
          e is ApiException ? e : UnknownApiException(e.toString()),
        ),
      );
    }
  }

  /// Reachable from every state, not just [AuthAuthenticated] — a stale
  /// session (e.g. [AuthError]) must still be able to log out cleanly.
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _scheduler.cancel();
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }
}
