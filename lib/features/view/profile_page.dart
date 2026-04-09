import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/profile_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
    context.read<ProfileBloc>().add(const ProfileSubscriptionRequested());
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ProfileBloc>().add(
          ProfileSaveRequested(
            displayName: _nameController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          previous.message != current.message && current.message != null,
      listener: (context, state) {
        if (state.message != null) {
          _showMessage(state.message!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Профиль'),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state.status == ProfileStatus.loading &&
                    state.profile == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.status == ProfileStatus.failure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.message ?? 'Не удалось загрузить профиль.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final profile = state.profile;
                if (profile == null) {
                  return const Center(
                    child: Text('Профиль недоступен.'),
                  );
                }

                if (!_isControllerInitialized) {
                  _nameController.text = profile.displayName;
                  _isControllerInitialized = true;
                }

                final isLoading = state.status == ProfileStatus.loading;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.9, end: 1),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: const CircleAvatar(
                              radius: 42,
                              child: Icon(Icons.person, size: 40),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeInOut,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(profile.email),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Имя пользователя',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Имя',
                                          prefixIcon: Icon(
                                            Icons.person_outline_outlined,
                                          ),
                                        ),
                                        validator: (value) {
                                          if ((value ?? '').trim().isEmpty) {
                                            return 'Введите имя';
                                          }
                                          if (value!.trim().length < 2) {
                                            return 'Минимум 2 символа';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed: isLoading ? null : _save,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: isLoading
                                                ? const SizedBox(
                                                    key: ValueKey('loading'),
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Сохранить',
                                                    key: ValueKey('text'),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}