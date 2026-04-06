import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fresh_alert/screens/main_screen.dart';
import 'package:fresh_alert/services/notification_service.dart';
import 'package:fresh_alert/services/theme_service.dart';
import 'package:fresh_alert/theme/app_theme.dart';

final NotificationService _notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('inventoryBox');

  await _notificationService.init();
  await ThemeService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}
