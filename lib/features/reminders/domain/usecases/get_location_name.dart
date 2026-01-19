
import 'package:reminder/features/reminders/domain/repositories/reminder_repository.dart';

class GetLocationName {
  final ReminderRepository _repository;

  GetLocationName(this._repository);

  Future<String?> call({required double lat, required double lng, required String accessToken}) {
    return _repository.getLocationName(lat: lat, lng: lng, accessToken: accessToken);
  }
}