import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/reminders/data/datasources/reminder_local_data_source.dart';
import '../../features/reminders/data/datasources/reminder_remote_data_source.dart';
import '../../features/reminders/data/repositories/reminder_repository_impl.dart';
import '../../features/reminders/domain/repositories/reminder_repository.dart';
import '../../features/reminders/domain/usecases/delete_reminder.dart';
import '../../features/reminders/domain/usecases/get_location_name.dart';
import '../../features/reminders/domain/usecases/get_reminders.dart';
import '../../features/reminders/domain/usecases/toggle_done.dart';
import '../../features/reminders/domain/usecases/upsert_reminder.dart';
import '../../features/reminders/presentation/bloc/reminder_bloc.dart';
import '../services/location_monitor_service.dart';
import '../services/notification_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<ReminderLocalDataSource>(
    () => ReminderLocalDataSource(getIt()),
  );

  getIt.registerLazySingleton<ReminderRemoteDataSource>(
    () => ReminderRemoteDataSource(),
  );

  getIt.registerLazySingleton<ReminderRepository>(
    () => ReminderRepositoryImpl(getIt(), getIt()),
  );

  getIt.registerLazySingleton<GetReminders>(() => GetReminders(getIt()));
  getIt.registerLazySingleton<UpsertReminder>(() => UpsertReminder(getIt()));
  getIt.registerLazySingleton<DeleteReminder>(() => DeleteReminder(getIt()));
  getIt.registerLazySingleton<ToggleDone>(() => ToggleDone(getIt()));
  getIt.registerLazySingleton<GetLocationName>(() => GetLocationName(getIt()));

  getIt.registerLazySingleton<NotificationService>(
    () => FlutterLocalNotificationService(),
  );
  await getIt<NotificationService>().initialize();

  getIt.registerLazySingleton<LocationMonitorService>(
    () => LocationMonitorService(notificationService: getIt()),
  );

  getIt.registerFactory<ReminderBloc>(
    () => ReminderBloc(
      getReminders: getIt(),
      upsertReminder: getIt(),
      deleteReminder: getIt(),
      toggleDone: getIt(),
      notificationService: getIt(),
      getLocationName: getIt(),
    ),
  );
}
