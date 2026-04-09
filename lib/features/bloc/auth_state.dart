part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({super.message});
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user, {super.message});

  final User user;

  @override
  List<Object?> get props => [
        user.uid,
        user.email,
        user.emailVerified,
        message,
      ];
}

final class AuthEmailVerificationRequired extends AuthState {
  const AuthEmailVerificationRequired(this.user, {super.message});

  final User user;

  @override
  List<Object?> get props => [
        user.uid,
        user.email,
        user.emailVerified,
        message,
      ];
}

final class AuthFailure extends AuthState {
  const AuthFailure(String message) : super(message: message);
}