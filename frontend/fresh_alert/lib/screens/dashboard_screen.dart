import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/screens/qr_scanner_screen.dart';

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
          .map((item) => InventoryItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final today = DateTime.now();

    final totalItems = _items.length;
    final expired = _items.where((e) => e.expiryDate.isBefore(today)).length;

    final expiringSoon = _items.where((e) {
      final diff = e.expiryDate.difference(today).inDays;
      return diff >= 0 && diff <= 3;
    }).length;

    final addedToday = _items
        .where(
          (e) =>
              e.createdAt.year == today.year &&
              e.createdAt.month == today.month &&
              e.createdAt.day == today.day,
        )
        .length;

    final expiringItems = _items.where((e) {
      final diff = e.expiryDate.difference(today).inDays;
      return diff >= 0 && diff <= 3;
    }).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );

              if (result != null && context.mounted) {
                _showAddFromQRDialog(result);
              }
            },
          ),
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
              crossAxisCount: isMobile ? 2 : 4,
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

            const SizedBox(height: 40),

            Text("Expiring Soon", style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),

            if (expiringItems.isEmpty)
              const Text("No items expiring soon")
            else
              ...expiringItems.map((item) {
                final daysLeft = item.expiryDate.difference(today).inDays;
                return _ExpiryItemCard(name: item.name, daysLeft: daysLeft);
              }),
          ],
        ),
      ),
    );
  }

  void _showAddFromQRDialog(String qrCode) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: "1");
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Scanned Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("QR: $qrCode"),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  expiryDate = picked;
                }
              },
              child: const Text("Select Expiry Date"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || expiryDate == null) return;

              final item = InventoryItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                barcode: qrCode,
                buyDate: DateTime.now(),
                expiryDate: expiryDate!,
                quantity: int.tryParse(quantityController.text) ?? 1,
                createdAt: DateTime.now(),
              );

              _box.add(item.toMap());
              _loadItems();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: theme.textTheme.bodySmall),
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
    final theme = Theme.of(context);

    Color statusColor;
    if (daysLeft < 0) {
      statusColor = Colors.red;
    } else if (daysLeft <= 3) {
      statusColor = Colors.orange;
    } else {
      statusColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(
            "$daysLeft days",
            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }
}
