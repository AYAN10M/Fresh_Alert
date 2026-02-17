import 'package:flutter/material.dart';
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

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38B000),
        surface: Color(0xFF181818),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),

      // REMOVE SPLASH GLOBALLY
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _buildTheme();

    final pages = const [MyDashboard(), MyInventory(), MySettings()];

    return Theme(
      data: themeData,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IndexedStack(
              key: ValueKey(_selectedIndex),
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ),

        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: themeData.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (_selectedIndex != index) {
                setState(() => _selectedIndex = index);
              }
            },
            type: BottomNavigationBarType.fixed,
            enableFeedback: false,
            selectedItemColor: themeData.colorScheme.primary,
            unselectedItemColor: Colors.white.withValues(alpha: 0.5),

            items: [
              _navItem(Icons.dashboard_rounded, "Dashboard,", 0),
              _navItem(Icons.inventory_2_rounded, "Inventory", 1),
              _navItem(Icons.settings_rounded, "Settings", 2),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 3,
            width: isSelected ? 28 : 0,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF38B000),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(icon),
        ],
      ),
    );
  }
}
