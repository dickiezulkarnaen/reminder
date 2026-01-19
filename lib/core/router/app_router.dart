import 'package:go_router/go_router.dart';

import '../../features/reminders/domain/entities/reminder.dart';
import '../../features/reminders/presentation/pages/location_picker_page.dart';
import '../../features/reminders/presentation/pages/reminder_form_page.dart';
import '../../features/reminders/presentation/pages/reminder_list_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppPages.reminders,
      builder: (context, state) => const ReminderListPage(),
      routes: [
        GoRoute(
          path: AppPages.remindersNew,
          builder: (context, state) {
            return const ReminderFormPage();
          }
        ),
        GoRoute(
          path: AppPages.remindersEdit,
          builder: (context, state) {
            return ReminderFormPage(existing: state.extra as Reminder);
          },
        ),
        GoRoute(
          path: AppPages.locationPicker,
          builder: (context, state) {
            return LocationPickerPage(initial: state.extra as LocationSelection?);
          },
        ),
      ],
    ),
  ],
);

class AppPages {
  static const reminders = '/';
  static const remindersNew = '/reminders/new';
  static const remindersEdit = '/reminders/edit';
  static const locationPicker = '/location-picker';
}
