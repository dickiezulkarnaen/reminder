import 'package:equatable/equatable.dart';
import 'package:reminder/features/reminders/presentation/pages/location_picker_page.dart';

import '../../domain/entities/reminder.dart';

enum ReminderStatus { initial, loading, loaded, failure }

class ReminderState extends Equatable {
  const ReminderState({
    required this.status,
    required this.reminders,
    this.errorMessage,
    this.location,
  });

  final ReminderStatus status;
  final List<Reminder> reminders;
  final String? errorMessage;
  final LocationSelection? location;

  factory ReminderState.initial() {
    return const ReminderState(
      status: ReminderStatus.initial,
      reminders: <Reminder>[],
      location: LocationSelection.def,
    );
  }

  ReminderState copyWith({
    ReminderStatus? status,
    List<Reminder>? reminders,
    String? errorMessage,
    LocationSelection? location,
  }) {
    return ReminderState(
      status: status ?? this.status,
      reminders: reminders ?? this.reminders,
      errorMessage: errorMessage ?? this.errorMessage,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [status, reminders, errorMessage, location];
}
