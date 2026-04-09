import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  const UserProfileModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserProfileModel.fromMap(String uid, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];

    return UserProfileModel(
      uid: uid,
      displayName: (map['displayName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        email,
        createdAt,
        updatedAt,
      ];
}