part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

final class ProfileSubscriptionRequested extends ProfileEvent {
  const ProfileSubscriptionRequested();
}

final class ProfileUpdated extends ProfileEvent {
  const ProfileUpdated(this.profile);

  final UserProfileModel profile;

  @override
  List<Object?> get props => [profile];
}

final class ProfileLoadFailed extends ProfileEvent {
  const ProfileLoadFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ProfileSaveRequested extends ProfileEvent {
  const ProfileSaveRequested({
    required this.displayName,
  });

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}