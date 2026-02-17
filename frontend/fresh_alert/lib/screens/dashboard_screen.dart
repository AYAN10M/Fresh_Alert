import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/screens/qr_scanner_screen.dart';
import 'package:fresh_alert/screens/add_item_screen.dart';

class MyDashboard extends StatefulWidget {
  const MyDashboard({super.key});

  @override
  State<MyDashboard> createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyDashboard> {
  late Box _box;
  List<InventoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _box = Hive.box('inventoryBox');
    _loadItems();
  }

  void _loadItems() {
    final data = _box.values.toList();
    setState(() {
      _items = data
          .map((e) => InventoryItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AddOptionTile(
                icon: Icons.qr_code_scanner_rounded,
                label: "Scan QR Code",
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  );

                  if (!mounted) return;

                  if (result != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddItemScreen(barcode: result),
                      ),
                    ).then((_) => _loadItems());
                  }
                },
              ),
              const SizedBox(height: 16),
              _AddOptionTile(
                icon: Icons.edit_rounded,
                label: "Add Manually",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddItemScreen()),
                  ).then((_) => _loadItems());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    final totalItems = _items.length;
    final expired = _items.where((e) => e.expiryDate.isBefore(today)).length;

    final expiringSoon = _items.where((e) {
      final diff = e.expiryDate.difference(today).inDays;
      return diff >= 0 && diff <= 3;
    }).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF1DB954),
        elevation: 0,
        splashColor: Colors.transparent,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Item"),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          "FreshAlert",
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 24),

            // HERO CARD
            PressScale(
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kitchen Health",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      expiringSoon.isEmpty
                          ? "All items are fresh 🎉"
                          : "${expiringSoon.length} items need attention",
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Manrope',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            const Text(
              "Overview",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: PressScale(
                    child: _StatCard(
                      title: "Total",
                      value: totalItems,
                      color: const Color(0xFF1DB954),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PressScale(
                    child: _StatCard(
                      title: "Expired",
                      value: expired,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            const Text(
              "Expiring Soon",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            if (expiringSoon.isEmpty)
              const Text(
                "No items expiring soon",
                style: TextStyle(fontFamily: 'Manrope', color: Colors.white54),
              )
            else
              ...expiringSoon.take(3).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final daysLeft = item.expiryDate.difference(today).inDays;

                return SlideFadeIn(
                  delay: index * 100,
                  child: _ExpiryItemCard(name: item.name, daysLeft: daysLeft),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/* ------------------ Animated Widgets ------------------ */

class PressScale extends StatefulWidget {
  final Widget child;
  const PressScale({super.key, required this.child});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

class SlideFadeIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const SlideFadeIn({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/* ------------------ UI Components ------------------ */

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            builder: (context, val, _) => Text(
              "$val",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryItemCard extends StatelessWidget {
  final String name;
  final int daysLeft;

  const _ExpiryItemCard({required this.name, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (daysLeft < 0) {
      statusColor = Colors.redAccent;
    } else if (daysLeft <= 3) {
      statusColor = Colors.orangeAccent;
    } else {
      statusColor = const Color(0xFF1DB954);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            "$daysLeft days",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      color: const Color(0xFF1DB954).withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1DB954)),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
