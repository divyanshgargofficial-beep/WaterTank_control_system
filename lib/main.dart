import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/screens/app_shell.dart';
import 'package:water_tank_controller/services/notification_service.dart';
import 'package:water_tank_controller/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  await notifications.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const WaterTankApp(),
    ),
  );
}

class WaterTankApp extends ConsumerWidget {
  const WaterTankApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return MaterialApp(
      title: 'Water Tank Controller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AppShell(),
      builder: (context, child) {
        return AnimatedTheme(
          data: AppTheme.dark(highContrast: settings.highContrast),
          duration: const Duration(milliseconds: 250),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
