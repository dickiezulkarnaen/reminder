import '../repositories/reminder_repository.dart';

class ToggleDone {
  const ToggleDone(this._repository);

  final ReminderRepository _repository;

  Future<void> call(String id) => _repository.toggleDone(id);
}
