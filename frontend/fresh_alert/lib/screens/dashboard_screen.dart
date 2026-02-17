import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/screens/qr_scanner_screen.dart';
import 'package:fresh_alert/screens/add_item_screen.dart';

class MyDashboard extends StatefulWidget {
  final bool isDark;
  final Function(bool) onToggleTheme;

  const MyDashboard({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text("Add using QR Code"),
              onTap: () async {
                Navigator.pop(context);

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );

                if (result != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddItemScreen(barcode: result),
                    ),
                  ).then((_) => _loadItems());
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Add Manually"),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    final totalItems = _items.length;
    final expired = _items.where((e) => e.expiryDate.isBefore(today)).length;

    final expiringSoon = _items.where((e) {
      final diff = e.expiryDate.difference(today).inDays;
      return diff >= 0 && diff <= 3;
    }).length;

    final addedToday = _items.where((e) {
      return e.createdAt.year == today.year &&
          e.createdAt.month == today.month &&
          e.createdAt.day == today.day;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddOptions),
          IconButton(
            icon: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => widget.onToggleTheme(!widget.isDark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overview", style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardCard(
                  title: "Total Items",
                  value: totalItems.toString(),
                ),
                _DashboardCard(
                  title: "Expiring Soon",
                  value: expiringSoon.toString(),
                ),
                _DashboardCard(title: "Expired", value: expired.toString()),
                _DashboardCard(
                  title: "Added Today",
                  value: addedToday.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;

  const _DashboardCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
