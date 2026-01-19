import 'package:equatable/equatable.dart';
import 'package:reminder/features/reminders/presentation/pages/location_picker_page.dart';

import '../../domain/entities/reminder.dart';

sealed class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

final class ReminderLoadRequested extends ReminderEvent {
  const ReminderLoadRequested();
}

final class ReminderUpsertRequested extends ReminderEvent {
  const ReminderUpsertRequested(this.reminder);

  final Reminder reminder;

  @override
  List<Object?> get props => [reminder];
}

final class ReminderDeleteRequested extends ReminderEvent {
  const ReminderDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ReminderToggleDoneRequested extends ReminderEvent {
  const ReminderToggleDoneRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ReminderLocationSelected extends ReminderEvent {
  final LocationSelection location;

  const ReminderLocationSelected(this.location);

  @override
  List<Object?> get props => [location];
}

final class ReminderLocationNameRequested extends ReminderEvent  {
  const ReminderLocationNameRequested(this.lat, this.lng, this.accessToken);

  final double lat;
  final double lng;
  final String accessToken;
}

final class ReminderTriggerCleared extends ReminderEvent  {
}
