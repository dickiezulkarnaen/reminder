import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/reminder.dart';

class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    required super.title,
    required super.note,
    required super.type,
    required super.dueAt,
    required super.latitude,
    required super.longitude,
    required super.locationLabel,
    required super.isDone,
    required super.createdAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      type: ReminderType.fromJson(json['type'] as String?),
      dueAt: json['dueAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['dueAt'] as int),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationLabel: json['locationLabel'] as String?,
      isDone: (json['isDone'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'note': note,
      'type': type.name,
      'dueAt': dueAt?.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'locationLabel': locationLabel,
      'isDone': isDone,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ReminderModel.fromEntity(Reminder reminder) {
    return ReminderModel(
      id: reminder.id,
      title: reminder.title,
      note: reminder.note,
      type: reminder.type,
      dueAt: reminder.dueAt,
      latitude: reminder.latitude,
      longitude: reminder.longitude,
      locationLabel: reminder.locationLabel,
      isDone: reminder.isDone,
      createdAt: reminder.createdAt,
    );
  }
}
