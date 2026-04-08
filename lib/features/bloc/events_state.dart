part of 'events_bloc.dart';

sealed class EventsState extends Equatable {
  const EventsState();
  
  @override
  List<Object> get props => [];
}

final class EventsInitial extends EventsState {}
