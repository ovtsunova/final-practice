import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/router/app_router.dart';
import '../../data/models/event_model.dart';
import '../bloc/auth_bloc.dart';
import '../../core/services/notification_service.dart';
import '../bloc/events_bloc.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  void initState() {
    super.initState();
    context.read<EventsBloc>().add(const EventsSubscriptionRequested());

    NotificationService.instance.requestPermissions();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _showEventDialog({EventModel? event}) async {
    final result = await showDialog<_EventFormResult>(
      context: context,
      builder: (dialogContext) {
        final isEdit = event != null;

        final titleController = TextEditingController(text: event?.title ?? '');
        final descriptionController =
            TextEditingController(text: event?.description ?? '');
        final locationController =
            TextEditingController(text: event?.location ?? '');
        final categoryController =
            TextEditingController(text: event?.category ?? '');

        final formKey = GlobalKey<FormState>();
        DateTime? selectedDate = event?.eventDate;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDateTime() async {
              final now = DateTime.now();
              final initialDate = selectedDate ?? now;

              final pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 10),
              );

              if (pickedDate == null) return;

              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(initialDate),
              );

              if (pickedTime == null) return;

              setDialogState(() {
                selectedDate = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            return AlertDialog(
              title: Text(isEdit ? 'Редактировать' : 'Новое мероприятие'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Введите название';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Место',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Категория',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Дата и время'),
                        subtitle: Text(
                          selectedDate == null
                              ? 'Не выбраны'
                              : DateFormat('dd.MM.yyyy HH:mm')
                                  .format(selectedDate!),
                        ),
                        trailing: IconButton(
                          onPressed: pickDateTime,
                          icon: const Icon(Icons.calendar_month_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    if (selectedDate == null) {
                      ScaffoldMessenger.of(dialogContext)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Выберите дату и время мероприятия.',
                            ),
                          ),
                        );
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _EventFormResult(
                        originalEvent: event,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        location: locationController.text.trim(),
                        category: categoryController.text.trim(),
                        eventDate: selectedDate!,
                      ),
                    );
                  },
                  child: Text(isEdit ? 'Сохранить' : 'Создать'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    if (result.originalEvent != null) {
      context.read<EventsBloc>().add(
            EventUpdateRequested(
              result.originalEvent!.copyWith(
                title: result.title,
                description: result.description,
                location: result.location,
                category: result.category,
                eventDate: result.eventDate,
              ),
            ),
          );
    } else {
      context.read<EventsBloc>().add(
            EventCreateRequested(
              title: result.title,
              description: result.description,
              location: result.location,
              category: result.category,
              eventDate: result.eventDate,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.login,
                (_) => false,
              );
            }
          },
        ),
        BlocListener<EventsBloc, EventsState>(
          listenWhen: (previous, current) =>
              previous.message != current.message && current.message != null,
          listener: (context, state) {
            if (state.message != null) {
              _showMessage(state.message!);
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мероприятия'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.profile);
              },
              icon: const Icon(Icons.person_outline),
            ),
            IconButton(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showEventDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Добавить'),
        ),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            if (state.status == EventsStatus.loading &&
                state.events.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.status == EventsStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message ?? 'Не удалось загрузить мероприятия.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (state.events.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Пока нет мероприятий.\nНажми "Добавить", чтобы создать первое.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.events.length,
              itemBuilder: (context, index) {
                final event = state.events[index];

                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: event.isCompleted,
                      onChanged: (_) {
                        context.read<EventsBloc>().add(
                              EventToggleCompletedRequested(event),
                            );
                      },
                    ),
                    title: Text(
                      event.title,
                      style: TextStyle(
                        decoration: event.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm')
                                .format(event.eventDate),
                          ),
                          if (event.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Место: ${event.location}'),
                          ],
                          if (event.category.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Категория: ${event.category}'),
                          ],
                          if (event.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(event.description),
                          ],
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showEventDialog(event: event),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () {
                            context.read<EventsBloc>().add(
                                  EventDeleteRequested(event.id),
                                );
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EventFormResult {
  const _EventFormResult({
    required this.originalEvent,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.eventDate,
  });

  final EventModel? originalEvent;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime eventDate;
}