import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/user_profile_model.dart';
import '../../data/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required ProfileRepository profileRepository,
  })  : _profileRepository = profileRepository,
        super(const ProfileState()) {
    on<ProfileSubscriptionRequested>(_onProfileSubscriptionRequested);
    on<ProfileUpdated>(_onProfileUpdated);
    on<ProfileLoadFailed>(_onProfileLoadFailed);
    on<ProfileSaveRequested>(_onProfileSaveRequested);
  }

  final ProfileRepository _profileRepository;
  StreamSubscription<UserProfileModel>? _profileSubscription;

  Future<void> _onProfileSubscriptionRequested(
    ProfileSubscriptionRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ProfileStatus.loading,
        message: null,
      ),
    );

    await _profileSubscription?.cancel();

    _profileSubscription = _profileRepository.watchProfile().listen(
      (profile) {
        add(ProfileUpdated(profile));
      },
      onError: (error) {
        add(
          ProfileLoadFailed(
            _mapError(error),
          ),
        );
      },
    );
  }

  void _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      state.copyWith(
        status: ProfileStatus.success,
        profile: event.profile,
        message: null,
      ),
    );
  }

  void _onProfileLoadFailed(
    ProfileLoadFailed event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      state.copyWith(
        status: ProfileStatus.failure,
        message: event.message,
      ),
    );
  }

  Future<void> _onProfileSaveRequested(
    ProfileSaveRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentProfile = state.profile;
    if (currentProfile == null) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'Профиль ещё не загружен.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ProfileStatus.loading,
        profile: currentProfile,
      ),
    );

    try {
      await _profileRepository.updateProfile(
        displayName: event.displayName,
      );

      emit(
        state.copyWith(
          status: ProfileStatus.success,
          message: 'Профиль сохранён.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: _mapError(error),
        ),
      );
    }
  }

  String _mapError(Object error) {
    final text = error.toString();

    if (text.contains('permission-denied')) {
      return 'Нет доступа к Firestore. Проверь правила безопасности.';
    }

    if (text.contains('failed-precondition')) {
      return 'Firestore ещё не готов или требует дополнительной настройки.';
    }

    return 'Ошибка загрузки профиля: $text';
  }

  @override
  Future<void> close() async {
    await _profileSubscription?.cancel();
    return super.close();
  }
}