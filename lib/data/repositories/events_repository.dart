import '../models/event_model.dart';
import '../sources/firestore_source.dart';

class EventsRepository {
  EventsRepository({
    required FirestoreSource firestoreSource,
  }) : _firestoreSource = firestoreSource;

  final FirestoreSource _firestoreSource;

  Stream<List<EventModel>> watchEvents() {
    return _firestoreSource.watchEvents();
  }

  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String location,
    required String category,
    required DateTime eventDate,
    required DateTime remindAt,
  }) {
    return _firestoreSource.createEvent(
      title: title,
      description: description,
      location: location,
      category: category,
      eventDate: eventDate,
      remindAt: remindAt,
    );
  }

  Future<void> updateEvent(EventModel event) {
    return _firestoreSource.updateEvent(event);
  }

  Future<void> deleteEvent(String eventId) {
    return _firestoreSource.deleteEvent(eventId);
  }
}