import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/router/app_router.dart';
import '../bloc/auth_bloc.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _iconScaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
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
                          AnimatedBuilder(
                            animation: _iconScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _iconScaleAnimation.value,
                                child: child,
                              );
                            },
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 82,
                            ),
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              'Мы отправили письмо на:\n$email',
                              key: ValueKey(email),
                              textAlign: TextAlign.center,
                            ),
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
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: isLoading
                                    ? const SizedBox(
                                        key: ValueKey('loading_1'),
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Я подтвердил почту',
                                        key: ValueKey('text_1'),
                                      ),
                              ),
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
        ),
      ),
    );
  }
}