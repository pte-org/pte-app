import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/proactive_refresh_scheduler.dart';
import '../../../../core/storage/token_store.dart';
import '../../domain/jwt_claims.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// No `BuildContext` here — expired-session/logout side effects (e.g.
/// navigating to a login screen) are driven by the UI listening to this
/// bloc's state changes, never by the bloc itself.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required TokenStore tokenStore,
    required ProactiveRefreshScheduler scheduler,
  })  : _repository = repository,
        _tokenStore = tokenStore,
        _scheduler = scheduler,
        super(const AuthIdle()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;
  final TokenStore _tokenStore;
  final ProactiveRefreshScheduler _scheduler;

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthAuthenticating());
    try {
      await _repository.login(email: event.email, password: event.password);
      final accessToken = await _tokenStore.readAccessToken();
      final claims = decodeJwtClaims(accessToken!);
      _scheduler.scheduleFromTokenStore();
      emit(AuthAuthenticated(claims));
    } on ApiException catch (e) {
      emit(AuthError(e));
    }
  }

  /// Reachable from every state, not just [AuthAuthenticated] — a stale
  /// session (e.g. [AuthError]) must still be able to log out cleanly.
  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    _scheduler.cancel();
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }
}
