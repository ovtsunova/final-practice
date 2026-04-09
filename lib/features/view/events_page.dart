import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/router/app_router.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/event_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/events_bloc.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  EventFilter _selectedFilter = EventFilter.all;
  bool _fabVisible = false;

  static const List<String> _categories = [
    'Учёба',
    'Работа',
    'Встреча',
    'Личное',
    'Праздник',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    context.read<EventsBloc>().add(const EventsSubscriptionRequested());

    Future.microtask(() async {
      await NotificationService.instance.requestPermissions();
      if (mounted) {
        setState(() {
          _fabVisible = true;
        });
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  DateTime _calculateRemindAt(DateTime eventDate, ReminderOption option) {
    switch (option) {
      case ReminderOption.atTime:
        return eventDate;
      case ReminderOption.tenMinutes:
        return eventDate.subtract(const Duration(minutes: 10));
      case ReminderOption.thirtyMinutes:
        return eventDate.subtract(const Duration(minutes: 30));
      case ReminderOption.oneHour:
        return eventDate.subtract(const Duration(hours: 1));
      case ReminderOption.oneDay:
        return eventDate.subtract(const Duration(days: 1));
    }
  }

  List<EventModel> _applyFilter(List<EventModel> events) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case EventFilter.all:
        return events;
      case EventFilter.today:
        return events.where((event) {
          return event.eventDate.year == now.year &&
              event.eventDate.month == now.month &&
              event.eventDate.day == now.day;
        }).toList();
      case EventFilter.upcoming:
        return events.where((event) {
          return !event.isCompleted && event.eventDate.isAfter(now);
        }).toList();
      case EventFilter.completed:
        return events.where((event) => event.isCompleted).toList();
    }
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

        final formKey = GlobalKey<FormState>();
        DateTime? selectedDate = event?.eventDate;
        ReminderOption selectedReminder = ReminderOption.atTime;
        String? selectedCategory =
            event?.category.isNotEmpty == true ? event!.category : null;

        if (event != null) {
          final difference = event.eventDate.difference(event.remindAt);
          if (difference == const Duration(minutes: 10)) {
            selectedReminder = ReminderOption.tenMinutes;
          } else if (difference == const Duration(minutes: 30)) {
            selectedReminder = ReminderOption.thirtyMinutes;
          } else if (difference == const Duration(hours: 1)) {
            selectedReminder = ReminderOption.oneHour;
          } else if (difference == const Duration(days: 1)) {
            selectedReminder = ReminderOption.oneDay;
          } else {
            selectedReminder = ReminderOption.atTime;
          }
        }

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
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Категория',
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Выберите категорию';
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ReminderOption>(
                        value: selectedReminder,
                        decoration: const InputDecoration(
                          labelText: 'Напомнить',
                        ),
                        items: ReminderOption.values.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedReminder = value;
                          });
                        },
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

                    final remindAt =
                        _calculateRemindAt(selectedDate!, selectedReminder);

                    if (!remindAt.isAfter(DateTime.now())) {
                      ScaffoldMessenger.of(dialogContext)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Время напоминания уже прошло. Выбери другое время.',
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
                        category: selectedCategory!.trim(),
                        eventDate: selectedDate!,
                        remindAt: remindAt,
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
                remindAt: result.remindAt,
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
              remindAt: result.remindAt,
            ),
          );
    }
  }

  String _reminderText(EventModel event) {
    final difference = event.eventDate.difference(event.remindAt);

    if (difference == const Duration(minutes: 10)) {
      return 'Напоминание: за 10 минут';
    }
    if (difference == const Duration(minutes: 30)) {
      return 'Напоминание: за 30 минут';
    }
    if (difference == const Duration(hours: 1)) {
      return 'Напоминание: за 1 час';
    }
    if (difference == const Duration(days: 1)) {
      return 'Напоминание: за 1 день';
    }
    return 'Напоминание: в момент события';
  }

  Color _categoryColor(String category, BuildContext context) {
    switch (category) {
      case 'Учёба':
        return Colors.indigo;
      case 'Работа':
        return Colors.teal;
      case 'Встреча':
        return Colors.orange;
      case 'Личное':
        return Colors.deepPurple;
      case 'Праздник':
        return Colors.pink;
      case 'Другое':
        return Colors.blueGrey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildStatusChip(EventModel event) {
    final now = DateTime.now();

    if (event.isCompleted) {
      return const _StatusChip(
        label: 'Завершено',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    }

    if (event.eventDate.isBefore(now)) {
      return const _StatusChip(
        label: 'Просрочено',
        color: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }

    return const _StatusChip(
      label: 'Активно',
      color: Colors.blue,
      icon: Icons.schedule,
    );
  }

  Widget _buildContent(EventsState state) {
    final filteredEvents = _applyFilter(state.events);

    if (state.status == EventsStatus.loading && state.events.isEmpty) {
      return const _AnimatedScreenState(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.status == EventsStatus.failure) {
      return _AnimatedScreenState(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              state.message ?? 'Не удалось загрузить мероприятия.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Column(
      key: ValueKey(_selectedFilter),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: EventFilter.values.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                'Найдено: ${filteredEvents.length}',
                key: ValueKey(filteredEvents.length),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredEvents.isEmpty
              ? _AnimatedScreenState(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _selectedFilter == EventFilter.all
                            ? 'Пока нет мероприятий.\nНажми "Добавить", чтобы создать первое.'
                            : 'По выбранному фильтру мероприятий нет.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  key: ValueKey(
                    '${_selectedFilter.name}_${filteredEvents.length}',
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];

                    return _AnimatedEventCard(
                      index: index,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _showEventDialog(event: event),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: event.isCompleted,
                                        onChanged: (_) {
                                          context.read<EventsBloc>().add(
                                                EventToggleCompletedRequested(
                                                  event,
                                                ),
                                              );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                              milliseconds: 220),
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            decoration: event.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                          child: Text(event.title),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusChip(event),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _InfoBadge(
                                        icon: Icons.calendar_today_outlined,
                                        text: DateFormat('dd.MM.yyyy HH:mm')
                                            .format(event.eventDate),
                                      ),
                                      _InfoBadge(
                                        icon: Icons.notifications_none,
                                        text: _reminderText(event)
                                            .replaceFirst('Напоминание: ', ''),
                                      ),
                                      if (event.category.isNotEmpty)
                                        _CategoryBadge(
                                          label: event.category,
                                          color: _categoryColor(
                                              event.category, context),
                                        ),
                                    ],
                                  ),
                                  if (event.location.isNotEmpty ||
                                      event.description.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    if (event.location.isNotEmpty)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.place_outlined,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(event.location),
                                          ),
                                        ],
                                      ),
                                    if (event.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        event.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        tooltip: 'Редактировать',
                                        onPressed: () =>
                                            _showEventDialog(event: event),
                                        icon:
                                            const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Удалить',
                                        onPressed: () {
                                          context.read<EventsBloc>().add(
                                                EventDeleteRequested(event.id),
                                              );
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
        floatingActionButton: AnimatedScale(
          scale: _fabVisible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _fabVisible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton.extended(
              onPressed: () => _showEventDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ),
        ),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildContent(state),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedScreenState extends StatelessWidget {
  const _AnimatedScreenState({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _AnimatedEventCard extends StatelessWidget {
  const _AnimatedEventCard({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = 60 * index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + delay.clamp(0, 300)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum ReminderOption {
  atTime('В момент события'),
  tenMinutes('За 10 минут'),
  thirtyMinutes('За 30 минут'),
  oneHour('За 1 час'),
  oneDay('За 1 день');

  const ReminderOption(this.label);
  final String label;
}

enum EventFilter {
  all('Все'),
  today('Сегодня'),
  upcoming('Предстоящие'),
  completed('Завершённые');

  const EventFilter(this.label);
  final String label;
}

class _EventFormResult {
  const _EventFormResult({
    required this.originalEvent,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.eventDate,
    required this.remindAt,
  });

  final EventModel? originalEvent;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime eventDate;
  final DateTime remindAt;
}