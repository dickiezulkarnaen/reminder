import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reminder/features/reminders/domain/usecases/get_location_name.dart';

import '../../domain/usecases/delete_reminder.dart';
import '../../domain/usecases/get_reminders.dart';
import '../../domain/usecases/toggle_done.dart';
import '../../domain/usecases/upsert_reminder.dart';
import '../../../../core/services/notification_service.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  ReminderBloc({
    required GetReminders getReminders,
    required UpsertReminder upsertReminder,
    required DeleteReminder deleteReminder,
    required ToggleDone toggleDone,
    required GetLocationName getLocationName,
    required NotificationService notificationService,
  })  : _getReminders = getReminders,
        _upsertReminder = upsertReminder,
        _deleteReminder = deleteReminder,
        _toggleDone = toggleDone,
        _notificationService = notificationService,
        _getLocationName = getLocationName,
        super(ReminderState.initial()) {
    on<ReminderLoadRequested>(_onLoad);
    on<ReminderUpsertRequested>(_onUpsert);
    on<ReminderDeleteRequested>(_onDelete);
    on<ReminderToggleDoneRequested>(_onToggle);
    on<ReminderLocationNameRequested>(_onGetLocationName);
    on<ReminderTriggerCleared>(_onClearLocationCompose);
  }

  final GetReminders _getReminders;
  final UpsertReminder _upsertReminder;
  final DeleteReminder _deleteReminder;
  final ToggleDone _toggleDone;
  final NotificationService _notificationService;
  final GetLocationName _getLocationName;

  Future<void> _onLoad(
    ReminderLoadRequested event,
    Emitter<ReminderState> emit,
  ) async {
    emit(state.copyWith(status: ReminderStatus.loading, errorMessage: null));
    try {
      final reminders = await _getReminders();
      emit(state.copyWith(status: ReminderStatus.loaded, reminders: reminders));
    } catch (e) {
      emit(state.copyWith(
        status: ReminderStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpsert(
    ReminderUpsertRequested event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await Future.wait([
        _upsertReminder(event.reminder),
        _notificationService.scheduleForReminder(event.reminder),
      ]);
      final reminders = await _getReminders();
      emit(state.copyWith(status: ReminderStatus.loaded, reminders: reminders));
    } catch (e) {
      emit(state.copyWith(
        status: ReminderStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDelete(
    ReminderDeleteRequested event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await Future.wait([
        _deleteReminder(event.id),
        _notificationService.cancelForReminder(event.id),
      ]);
      final reminders = await _getReminders();
      emit(state.copyWith(status: ReminderStatus.loaded, reminders: reminders));
    } catch (e) {
      emit(state.copyWith(
        status: ReminderStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onToggle(
    ReminderToggleDoneRequested event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      await _toggleDone(event.id);
      final reminders = await _getReminders();
      final updated = reminders.where((e) => e.id == event.id).firstOrNull;
      if (updated != null) {
        await _notificationService.scheduleForReminder(updated);
      }
      emit(state.copyWith(status: ReminderStatus.loaded, reminders: reminders));
    } catch (e) {
      emit(state.copyWith(
        status: ReminderStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onGetLocationName(
      ReminderLocationNameRequested event,
      Emitter<ReminderState> emit) async {
    try {
      final name = await _getLocationName(
        lat: event.lat,
        lng: event.lng,
        accessToken: event.accessToken,
      );
      emit(state.copyWith(
          status: ReminderStatus.loaded,
          location: state.location?.copyWith(label: name ?? '')
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReminderStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onClearLocationCompose(
      ReminderTriggerCleared event,
      Emitter<ReminderState> emit
      ) async {
    emit(state.copyWith(
      status: ReminderStatus.loaded,
      location: null,
    ));
  }
}

extension FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
