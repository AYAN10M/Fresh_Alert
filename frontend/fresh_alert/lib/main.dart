import 'package:flutter/material.dart';
import 'package:fresh_alert/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class AppColors {
  AppColors._(); // Prevent instantiation

  // Light
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF4F4F4);
  static const Color lightPrimary = Colors.black;
  static const Color lightDivider = Color(0xFFE0E0E0);

  // Dark
  static const Color darkBackground = Colors.black;
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkPrimary = Colors.white;
  static const Color darkDivider = Color(0xFF2A2A2A);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

  void _toggleTheme(bool isDark) {
    setState(() => _isDark = isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: MainScreen(isDark: _isDark, onToggleTheme: _toggleTheme),
    );
  }

  ThemeData _buildLightTheme() => ThemeData(
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightPrimary,
      surface: AppColors.lightSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardColor: AppColors.lightSurface,
    dividerColor: AppColors.lightDivider,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightBackground,
      selectedItemColor: AppColors.lightPrimary,
      unselectedItemColor: Color(0xFF9E9E9E),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    useMaterial3: true,
  );

  ThemeData _buildDarkTheme() => ThemeData(
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkPrimary,
      surface: AppColors.darkSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardColor: AppColors.darkSurface,
    dividerColor: AppColors.darkDivider,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
      selectedItemColor: AppColors.darkPrimary,
      unselectedItemColor: Color(0xFF7A7A7A),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    useMaterial3: true,
  );
}
