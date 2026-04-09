import 'package:flutter/material.dart';

import '../../features/view/events_page.dart';
import '../../features/view/login_page.dart';
import '../../features/view/profile_page.dart';
import '../../features/view/register_page.dart';
import '../../features/view/reset_password_page.dart';
import '../../features/view/splash_page.dart';
import '../../features/view/verify_email_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';
  static const String events = '/events';
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage());
      case verifyEmail:
        return MaterialPageRoute(builder: (_) => const VerifyEmailPage());
      case events:
        return MaterialPageRoute(builder: (_) => const EventsPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}