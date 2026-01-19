import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_local_data_source.dart';
import '../datasources/reminder_remote_data_source.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  const ReminderRepositoryImpl(this._local, this._remote);

  final ReminderLocalDataSource _local;
  final ReminderRemoteDataSource _remote;

  @override
  Future<List<Reminder>> getReminders() async {
    return _local.getReminders();
  }

  @override
  Future<void> upsertReminder(Reminder reminder) async {
    final current = await _local.getReminders();
    final idx = current.indexWhere((e) => e.id == reminder.id);

    final model = ReminderModel.fromEntity(reminder);

    if (idx >= 0) {
      current[idx] = model;
    } else {
      current.add(model);
    }

    await _local.saveReminders(current);
  }

  @override
  Future<void> deleteReminder(String id) async {
    final current = await _local.getReminders();
    current.removeWhere((e) => e.id == id);
    await _local.saveReminders(current);
  }

  @override
  Future<void> toggleDone(String id) async {
    final current = await _local.getReminders();
    final idx = current.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    final existing = current[idx];
    current[idx] = ReminderModel(
      id: existing.id,
      title: existing.title,
      note: existing.note,
      type: existing.type,
      dueAt: existing.dueAt,
      latitude: existing.latitude,
      longitude: existing.longitude,
      locationLabel: existing.locationLabel,
      isDone: !existing.isDone,
      createdAt: existing.createdAt,
    );

    await _local.saveReminders(current);
  }

  @override
  Future<String?> getLocationName({
    required double lat,
    required double lng,
    required String accessToken,
  }) {
    return _remote.getLocationName(
      lat: lat,
      lng: lng,
      accessToken: accessToken,
    );
  }
}
