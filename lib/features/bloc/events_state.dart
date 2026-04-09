part of 'events_bloc.dart';

enum EventsStatus { initial, loading, success, failure }

final class EventsState extends Equatable {
  const EventsState({
    this.status = EventsStatus.initial,
    this.events = const [],
    this.message,
  });

  final EventsStatus status;
  final List<EventModel> events;
  final String? message;

  EventsState copyWith({
    EventsStatus? status,
    List<EventModel>? events,
    String? message,
  }) {
    return EventsState(
      status: status ?? this.status,
      events: events ?? this.events,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, events, message];
}