import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_model.dart';
import '../models/user_profile_model.dart';

class FirestoreSource {
  FirestoreSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Пользователь не авторизован.');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_currentUser.uid);

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _userDoc.collection('events');

  Stream<List<EventModel>> watchEvents() {
    return _eventsCollection.orderBy('eventDate').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String location,
    required String category,
    required DateTime eventDate,
  }) async {
    final now = DateTime.now();
    final doc = _eventsCollection.doc();

    final event = EventModel(
      id: doc.id,
      userId: _currentUser.uid,
      title: title,
      description: description,
      location: location,
      category: category,
      eventDate: eventDate,
      remindAt: eventDate,
      createdAt: now,
      updatedAt: now,
      isCompleted: false,
      notificationSent: false,
    );

    await doc.set(event.toMap());
    return event;
  }

  Future<void> updateEvent(EventModel event) async {
    final updatedEvent = event.copyWith(
      updatedAt: DateTime.now(),
      notificationSent: false,
      remindAt: event.eventDate,
    );

    await _eventsCollection.doc(event.id).update(updatedEvent.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventsCollection.doc(eventId).delete();
  }

  Future<UserProfileModel> fetchProfile() async {
    final user = _currentUser;
    final snapshot = await _userDoc.get();

    if (!snapshot.exists || snapshot.data() == null) {
      final now = DateTime.now();
      final profile = UserProfileModel(
        uid: user.uid,
        displayName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Пользователь',
        email: user.email ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _userDoc.set(profile.toMap(), SetOptions(merge: true));
      return profile;
    }

    return UserProfileModel.fromMap(user.uid, snapshot.data()!);
  }

  Stream<UserProfileModel> watchProfile() {
    return _userDoc.snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) {
        return fetchProfile();
      }

      return UserProfileModel.fromMap(_currentUser.uid, snapshot.data()!);
    });
  }

  Future<void> updateProfile({
    required String displayName,
  }) async {
    final currentProfile = await fetchProfile();

    final updatedProfile = currentProfile.copyWith(
      displayName: displayName.trim(),
      email: _currentUser.email ?? currentProfile.email,
      updatedAt: DateTime.now(),
    );

    await _userDoc.set(
      updatedProfile.toMap(),
      SetOptions(merge: true),
    );

    if ((_currentUser.displayName ?? '').trim() != displayName.trim()) {
      await _currentUser.updateDisplayName(displayName.trim());
      await _currentUser.reload();
    }
  }
}