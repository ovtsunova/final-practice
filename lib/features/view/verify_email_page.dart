import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/router/app_router.dart';
import '../bloc/auth_bloc.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (state.message != null) {
            _showMessage(context, state.message!);
          }
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.events,
            (_) => false,
          );
        } else if (state is AuthUnauthenticated) {
          if (state.message != null) {
            _showMessage(context, state.message!);
          }
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.login,
            (_) => false,
          );
        } else if (state is AuthEmailVerificationRequired &&
            state.message != null) {
          _showMessage(context, state.message!);
        } else if (state is AuthFailure) {
          _showMessage(context, state.message ?? 'Ошибка.');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Подтверждение почты'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  final email = switch (state) {
                    AuthEmailVerificationRequired s => s.user.email ?? '',
                    AuthAuthenticated s => s.user.email ?? '',
                    _ => '',
                  };

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Подтвердите email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Мы отправили письмо на:\n$email',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context
                                      .read<AuthBloc>()
                                      .add(const AuthReloadRequested());
                                },
                          child: const Text('Я подтвердил почту'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.read<AuthBloc>().add(
                                        const AuthSendEmailVerificationRequested(),
                                      );
                                },
                          child: const Text('Отправить письмо ещё раз'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.read<AuthBloc>().add(
                                        const AuthSignOutRequested(),
                                      );
                                },
                          child: const Text('Выйти'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}