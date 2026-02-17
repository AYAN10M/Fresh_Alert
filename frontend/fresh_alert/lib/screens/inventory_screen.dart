import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum SortOption { expiryNearest, expiryFarthest, recentlyAdded, quantity }

class MyInventory extends StatefulWidget {
  const MyInventory({super.key});

  @override
  State<MyInventory> createState() => _MyInventoryState();
}

class _MyInventoryState extends State<MyInventory> {
  late Box _box;
  late TextEditingController _searchController;

  List<InventoryItem> _items = [];

  SortOption _currentSort = SortOption.expiryNearest;
  bool _groupByCategory = false;

  @override
  void initState() {
    super.initState();
    _box = Hive.box('inventoryBox');
    _searchController = TextEditingController();
    _loadItems();
  }

  void _loadItems() {
    final data = _box.values.toList();

    List<InventoryItem> items = data
        .map((item) => InventoryItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      items = items
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    }

    _applySorting(items);

    setState(() {
      _items = items;
    });
  }

  void _applySorting(List<InventoryItem> items) {
    switch (_currentSort) {
      case SortOption.expiryNearest:
        items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;

      case SortOption.expiryFarthest:
        items.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        break;

      case SortOption.recentlyAdded:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case SortOption.quantity:
        items.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: SortOption.values.map((option) {
          return ListTile(
            title: Text(option.name),
            onTap: () {
              setState(() {
                _currentSort = option;
              });
              _loadItems();
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert),
            onPressed: _showSortOptions,
          ),
          IconButton(
            icon: Icon(_groupByCategory ? Icons.grid_view : Icons.view_list),
            onPressed: () {
              setState(() {
                _groupByCategory = !_groupByCategory;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadItems(),
              decoration: const InputDecoration(
                hintText: "Search items",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text("No items found"))
                : _groupByCategory
                ? _buildGroupedList(theme)
                : _buildNormalList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _items.length,
      itemBuilder: (_, index) {
        return _buildInventoryCard(_items[index], theme);
      },
    );
  }

  Widget _buildGroupedList(ThemeData theme) {
    final Map<String, List<InventoryItem>> grouped = {};

    for (var item in _items) {
      final category = item.category ?? "Uncategorized";
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              entry.key,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...entry.value
                .map((item) => _buildInventoryCard(item, theme))
                .toList(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInventoryCard(InventoryItem item, ThemeData theme) {
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    Color statusColor;
    if (daysLeft < 0) {
      statusColor = Colors.red;
    } else if (daysLeft <= 3) {
      statusColor = Colors.orange;
    } else {
      statusColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text("Qty: ${item.quantity} | ${item.location ?? '-'}"),
              ],
            ),
          ),
          Text(
            "$daysLeft days",
            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }
}
