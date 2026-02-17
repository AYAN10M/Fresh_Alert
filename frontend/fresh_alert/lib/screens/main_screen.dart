import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_alert/screens/dashboard_screen.dart';
import 'package:fresh_alert/screens/inventory_screen.dart';
import 'package:fresh_alert/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool("isDarkTheme") ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = value;
    });
    await prefs.setBool("isDarkTheme", value);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _isDark ? ThemeData.dark() : ThemeData.light();

    final pages = [
      MyDashboard(isDark: _isDark, onToggleTheme: _toggleTheme),
      const MyInventory(),
      const MySettings(),
    ];

    return Theme(
      data: themeData,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (_selectedIndex != index) {
              setState(() => _selectedIndex = index);
            }
          },
          iconSize: 24,
          showUnselectedLabels: true,
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
          ),
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
