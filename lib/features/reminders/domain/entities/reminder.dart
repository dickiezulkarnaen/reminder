import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';


class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.title,
    required this.note,
    required this.type,
    required this.dueAt,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.isDone,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String note;
  final ReminderType type;
  final DateTime? dueAt;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final bool isDone;
  final DateTime createdAt;

  Reminder copyWith({
    String? id,
    String? title,
    String? note,
    ReminderType? type,
    DateTime? dueAt,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? locationLabel,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      type: type ?? this.type,
      dueAt: dueAt ?? this.dueAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        note,
        type,
        dueAt,
        latitude,
        longitude,
        locationLabel,
        isDone,
        createdAt,
      ];
}
