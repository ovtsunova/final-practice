part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthResetPasswordRequested extends AuthEvent {
  const AuthResetPasswordRequested({
    required this.email,
  });

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthSendEmailVerificationRequested extends AuthEvent {
  const AuthSendEmailVerificationRequested();
}

final class AuthReloadRequested extends AuthEvent {
  const AuthReloadRequested();
}