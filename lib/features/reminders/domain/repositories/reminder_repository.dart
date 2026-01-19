import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getReminders();
  Future<void> upsertReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> toggleDone(String id);
  Future<String?> getLocationName({
    required double lat,
    required double lng,
    required String accessToken,
  });
}
