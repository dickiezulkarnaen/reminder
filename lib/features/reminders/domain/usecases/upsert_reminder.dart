import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

class UpsertReminder {
  const UpsertReminder(this._repository);

  final ReminderRepository _repository;

  Future<void> call(Reminder reminder) => _repository.upsertReminder(reminder);
}
