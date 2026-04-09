part of 'profile_bloc.dart';

enum ProfileStatus { initial, loading, success, failure }

final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.message,
  });

  final ProfileStatus status;
  final UserProfileModel? profile;
  final String? message;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfileModel? profile,
    String? message,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, profile, message];
}