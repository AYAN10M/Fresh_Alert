import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fresh_alert/screens/dashboard_screen.dart';
import 'package:fresh_alert/screens/inventory_screen.dart';
import 'package:fresh_alert/screens/settings_screen.dart';

const _kGreen = Color(0xFF1DB954);
const _kBg = Color(0xFF0A0A0A);
const _kNavBg = Color(0xFF141414);
const _kBorder = Color(0xFF242424);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Pages kept constant so IndexedStack never rebuilds them
  static const _pages = [MyDashboard(), MyInventory(), MySettings()];

  void _onTap(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick(); // subtle tactile feedback on tab switch
    setState(() => _selectedIndex = index);
  }

  ThemeData _buildTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _kGreen,
      surface: Color(0xFF181818),
    ),
    scaffoldBackgroundColor: _kBg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    final theme = _buildTheme();

    return Theme(
      data: theme,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: IndexedStack(index: _selectedIndex, children: _pages),
        ),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _selectedIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV  — floating pill with icon + label layout
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.dashboard_rounded, label: "Dashboard"),
    _NavItem(icon: Icons.inventory_2_rounded, label: "Inventory"),
    _NavItem(icon: Icons.settings_rounded, label: "Settings"),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: _kNavBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              // subtle green ambient glow when something is selected
              BoxShadow(
                color: _kGreen.withValues(alpha: 0.04),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              return Expanded(
                child: _NavButton(
                  item: _items[i],
                  isSelected: selectedIndex == i,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INDIVIDUAL NAV BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // selected tab gets a pill highlight
            color: selected
                ? _kGreen.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // icon with animated colour + size
              AnimatedScale(
                scale: selected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Icon(
                  widget.item.icon,
                  size: 22,
                  color: selected ? _kGreen : Colors.white38,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w900,
                  color: selected ? _kGreen : Colors.white38,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
