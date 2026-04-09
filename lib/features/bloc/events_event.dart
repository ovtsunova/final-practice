part of 'events_bloc.dart';

sealed class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

final class EventsSubscriptionRequested extends EventsEvent {
  const EventsSubscriptionRequested();
}

final class EventsUpdated extends EventsEvent {
  const EventsUpdated(this.events);

  final List<EventModel> events;

  @override
  List<Object?> get props => [events];
}

final class EventsLoadFailed extends EventsEvent {
  const EventsLoadFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class EventCreateRequested extends EventsEvent {
  const EventCreateRequested({
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.eventDate,
  });

  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime eventDate;

  @override
  List<Object?> get props => [
        title,
        description,
        location,
        category,
        eventDate,
      ];
}

final class EventUpdateRequested extends EventsEvent {
  const EventUpdateRequested(this.event);

  final EventModel event;

  @override
  List<Object?> get props => [event];
}

final class EventToggleCompletedRequested extends EventsEvent {
  const EventToggleCompletedRequested(this.event);

  final EventModel event;

  @override
  List<Object?> get props => [event];
}

final class EventDeleteRequested extends EventsEvent {
  const EventDeleteRequested(this.eventId);

  final String eventId;

  @override
  List<Object?> get props => [eventId];
}