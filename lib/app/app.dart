import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/events_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/sources/firebase_auth_source.dart';
import '../data/sources/firestore_source.dart';
import '../features/bloc/auth_bloc.dart';
import '../features/bloc/events_bloc.dart';
import '../features/bloc/profile_bloc.dart';
import '../features/bloc/splash_bloc.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FirebaseAuthSource>(
          create: (_) => FirebaseAuthSource(),
        ),
        RepositoryProvider<FirestoreSource>(
          create: (_) => FirestoreSource(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(
            authSource: context.read<FirebaseAuthSource>(),
          ),
        ),
        RepositoryProvider<EventsRepository>(
          create: (context) => EventsRepository(
            firestoreSource: context.read<FirestoreSource>(),
          ),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(
            firestoreSource: context.read<FirestoreSource>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<SplashBloc>(
            create: (_) => SplashBloc(),
          ),
          BlocProvider<EventsBloc>(
            create: (context) => EventsBloc(
              eventsRepository: context.read<EventsRepository>(),
            ),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Event Planner',
          theme: AppTheme.lightTheme,
          initialRoute: AppRouter.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}