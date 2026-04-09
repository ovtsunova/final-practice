import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/router/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/splash_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<SplashBloc>().add(const SplashStarted());
  }

  void _navigate(String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SplashBloc, SplashState>(
          listener: (context, state) {
            if (state is SplashCompleted) {
              context.read<AuthBloc>().add(const AuthCheckRequested());
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              _navigate(AppRouter.events);
            } else if (state is AuthEmailVerificationRequired) {
              _navigate(AppRouter.verifyEmail);
            } else if (state is AuthUnauthenticated || state is AuthFailure) {
              _navigate(AppRouter.login);
            }
          },
        ),
      ],
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}