import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/services/notification_service.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

part 'events_event.dart';
part 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc({
    required EventsRepository eventsRepository,
  })  : _eventsRepository = eventsRepository,
        super(const EventsState()) {
    on<EventsSubscriptionRequested>(_onSubscriptionRequested);
    on<EventsUpdated>(_onEventsUpdated);
    on<EventsLoadFailed>(_onEventsLoadFailed);
    on<EventCreateRequested>(_onEventCreateRequested);
    on<EventUpdateRequested>(_onEventUpdateRequested);
    on<EventToggleCompletedRequested>(_onEventToggleCompletedRequested);
    on<EventDeleteRequested>(_onEventDeleteRequested);
  }

  final EventsRepository _eventsRepository;
  StreamSubscription<List<EventModel>>? _eventsSubscription;

  Future<void> _onSubscriptionRequested(
    EventsSubscriptionRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EventsStatus.loading,
        message: null,
      ),
    );

    await _eventsSubscription?.cancel();

    _eventsSubscription = _eventsRepository.watchEvents().listen(
      (events) {
        add(EventsUpdated(events));
      },
      onError: (error) {
        add(
          EventsLoadFailed(
            _mapError(error),
          ),
        );
      },
    );
  }

  void _onEventsUpdated(
    EventsUpdated event,
    Emitter<EventsState> emit,
  ) {
    emit(
      state.copyWith(
        status: EventsStatus.success,
        events: event.events,
        message: null,
      ),
    );
  }

  void _onEventsLoadFailed(
    EventsLoadFailed event,
    Emitter<EventsState> emit,
  ) {
    emit(
      state.copyWith(
        status: EventsStatus.failure,
        message: event.message,
      ),
    );
  }

  Future<void> _onEventCreateRequested(
    EventCreateRequested event,
    Emitter<EventsState> emit,
  ) async {
    try {
      final createdEvent = await _eventsRepository.createEvent(
        title: event.title,
        description: event.description,
        location: event.location,
        category: event.category,
        eventDate: event.eventDate,
        remindAt: event.remindAt,
      );

      await NotificationService.instance.scheduleForEvent(createdEvent);

      emit(
        state.copyWith(
          status: EventsStatus.success,
          message: 'Мероприятие сохранено. Напоминание создано.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          message: _mapError(error),
        ),
      );
    }
  }

  Future<void> _onEventUpdateRequested(
    EventUpdateRequested event,
    Emitter<EventsState> emit,
  ) async {
    try {
      await _eventsRepository.updateEvent(event.event);
      await NotificationService.instance.scheduleForEvent(event.event);

      emit(
        state.copyWith(
          status: EventsStatus.success,
          message: 'Изменения сохранены. Напоминание обновлено.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          message: _mapError(error),
        ),
      );
    }
  }

  Future<void> _onEventToggleCompletedRequested(
    EventToggleCompletedRequested event,
    Emitter<EventsState> emit,
  ) async {
    try {
      final updatedEvent = event.event.copyWith(
        isCompleted: !event.event.isCompleted,
      );

      await _eventsRepository.updateEvent(updatedEvent);

      if (updatedEvent.isCompleted) {
        await NotificationService.instance.cancelForEvent(updatedEvent.id);
      } else {
        await NotificationService.instance.scheduleForEvent(updatedEvent);
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
          message: _mapError(error),
        ),
      );
    }
  }

  Future<void> _onEventDeleteRequested(
    EventDeleteRequested event,
    Emitter<EventsState> emit,
  ) async {
    try {
      await NotificationService.instance.cancelForEvent(event.eventId);
      await _eventsRepository.deleteEvent(event.eventId);

      emit(
        state.copyWith(
          status: EventsStatus.success,
          message: 'Мероприятие удалено. Напоминание удалено.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EventsStatus.failure,
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

    return 'Ошибка работы с мероприятиями: $text';
  }

  @override
  Future<void> close() async {
    await _eventsSubscription?.cancel();
    return super.close();
  }
}