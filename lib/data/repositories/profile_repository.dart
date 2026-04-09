import '../models/user_profile_model.dart';
import '../sources/firestore_source.dart';

class ProfileRepository {
  ProfileRepository({
    required FirestoreSource firestoreSource,
  }) : _firestoreSource = firestoreSource;

  final FirestoreSource _firestoreSource;

  Future<UserProfileModel> fetchProfile() {
    return _firestoreSource.fetchProfile();
  }

  Stream<UserProfileModel> watchProfile() {
    return _firestoreSource.watchProfile();
  }

  Future<void> updateProfile({
    required String displayName,
  }) {
    return _firestoreSource.updateProfile(
      displayName: displayName,
    );
  }
}