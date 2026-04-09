import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class EventModel extends Equatable {
  const EventModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.eventDate,
    required this.remindAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isCompleted,
    required this.notificationSent,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime eventDate;
  final DateTime remindAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final bool notificationSent;

  EventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? location,
    String? category,
    DateTime? eventDate,
    DateTime? remindAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    bool? notificationSent,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      eventDate: eventDate ?? this.eventDate,
      remindAt: remindAt ?? this.remindAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationSent: notificationSent ?? this.notificationSent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'eventDate': Timestamp.fromDate(eventDate),
      'remindAt': Timestamp.fromDate(remindAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isCompleted': isCompleted,
      'notificationSent': notificationSent,
    };
  }

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    final eventDate = map['eventDate'];
    final remindAt = map['remindAt'];
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];

    final parsedEventDate =
        eventDate is Timestamp ? eventDate.toDate() : DateTime.now();

    return EventModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      eventDate: parsedEventDate,
      remindAt: remindAt is Timestamp ? remindAt.toDate() : parsedEventDate,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
      isCompleted: (map['isCompleted'] ?? false) as bool,
      notificationSent: (map['notificationSent'] ?? false) as bool,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        location,
        category,
        eventDate,
        remindAt,
        createdAt,
        updatedAt,
        isCompleted,
        notificationSent,
      ];
}