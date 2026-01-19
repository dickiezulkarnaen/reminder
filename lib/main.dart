import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'features/reminders/presentation/bloc/reminder_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();
  MapboxOptions.setAccessToken(String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),);

  runApp(
    const ReminderApp(),
  );
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B5BD6),
      brightness: Brightness.light,
    );

    return BlocProvider(
      create: (_) => getIt<ReminderBloc>(),
      child: MaterialApp.router(
        title: 'Reminder',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: colorScheme.surface,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
