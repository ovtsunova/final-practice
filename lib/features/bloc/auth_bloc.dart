import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
    on<AuthSendEmailVerificationRequested>(_onAuthSendEmailVerificationRequested);
    on<AuthReloadRequested>(_onAuthReloadRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _emitCurrentUserState(emit);
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      await _emitCurrentUserState(emit);
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      emit(const AuthFailure('Не удалось выполнить вход.'));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
      );

      final user = _authRepository.currentUser;
      if (user == null) {
        emit(const AuthFailure('Не удалось завершить регистрацию.'));
        return;
      }

      emit(
        AuthEmailVerificationRequired(
          user,
          message: 'Регистрация выполнена. Подтвердите почту.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      emit(const AuthFailure('Не удалось выполнить регистрацию.'));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(
        const AuthUnauthenticated(
          message: 'Письмо для сброса пароля отправлено.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      emit(const AuthFailure('Не удалось отправить письмо для сброса пароля.'));
    }
  }

  Future<void> _onAuthSendEmailVerificationRequested(
    AuthSendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.sendEmailVerification();
      final user = _authRepository.currentUser;
      if (user == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      emit(
        AuthEmailVerificationRequired(
          user,
          message: 'Письмо с подтверждением отправлено повторно.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    } catch (_) {
      emit(const AuthFailure('Не удалось отправить письмо подтверждения.'));
    }
  }

  Future<void> _onAuthReloadRequested(
    AuthReloadRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _emitCurrentUserState(emit);
  }

  Future<void> _emitCurrentUserState(
    Emitter<AuthState> emit, {
    String? message,
  }) async {
    final currentUser = _authRepository.currentUser;

    if (currentUser == null) {
      emit(AuthUnauthenticated(message: message));
      return;
    }

    await _authRepository.reloadCurrentUser();
    final refreshedUser = _authRepository.currentUser;

    if (refreshedUser == null) {
      emit(AuthUnauthenticated(message: message));
      return;
    }

    if (!refreshedUser.emailVerified) {
      emit(
        AuthEmailVerificationRequired(
          refreshedUser,
          message: message ?? 'Подтвердите почту, чтобы продолжить.',
        ),
      );
      return;
    }

    emit(AuthAuthenticated(refreshedUser, message: message));
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Некорректный email.';
      case 'user-not-found':
        return 'Пользователь не найден.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль.';
      case 'email-already-in-use':
        return 'Этот email уже используется.';
      case 'weak-password':
        return 'Пароль слишком простой.';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже.';
      default:
        return e.message ?? 'Произошла ошибка авторизации.';
    }
  }
}