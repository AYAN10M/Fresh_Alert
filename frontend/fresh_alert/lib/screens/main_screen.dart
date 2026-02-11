import 'package:flutter/material.dart';
import 'package:fresh_alert/screens/dashboard_screen.dart';
import 'package:fresh_alert/screens/inventory_screen.dart';
import 'package:fresh_alert/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isDark;
  final Function(bool) onToggleTheme;

  const MainScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      MyDashboard(isDark: widget.isDark, onToggleTheme: widget.onToggleTheme),
      const MyInventory(),
      const MySettings(),
    ];

    return Scaffold(
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
    );
  }
}
