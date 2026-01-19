import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

class GetReminders {
  const GetReminders(this._repository);

  final ReminderRepository _repository;

  Future<List<Reminder>> call() async {
    final reminders = await _repository.getReminders();
    reminders.sort((a, b) {
      final aDone = a.isDone ? 1 : 0;
      final bDone = b.isDone ? 1 : 0;
      if (aDone != bDone) return aDone.compareTo(bDone);

      final aDue = a.dueAt?.millisecondsSinceEpoch ?? 1 << 62;
      final bDue = b.dueAt?.millisecondsSinceEpoch ?? 1 << 62;
      if (aDue != bDue) return aDue.compareTo(bDue);

      return b.createdAt.compareTo(a.createdAt);
    });
    return reminders;
  }
}
