import 'package:firebase_auth/firebase_auth.dart';

import '../sources/firebase_auth_source.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuthSource authSource,
  }) : _authSource = authSource;

  final FirebaseAuthSource _authSource;

  User? get currentUser => _authSource.currentUser;

  Stream<User?> authStateChanges() => _authSource.authStateChanges();

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _authSource.signIn(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _authSource.signUp(
      name: name,
      email: email,
      password: password,
    );

    await _authSource.sendEmailVerification();
    await _authSource.reloadCurrentUser();

    return credential.user;
  }

  Future<void> signOut() => _authSource.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _authSource.sendPasswordResetEmail(email);
  }

  Future<void> sendEmailVerification() {
    return _authSource.sendEmailVerification();
  }

  Future<void> reloadCurrentUser() {
    return _authSource.reloadCurrentUser();
  }
}