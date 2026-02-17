import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_alert/models/inventory_item.dart';

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
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _currentSort = SortOption.values[prefs.getInt("sortOption") ?? 0];
    _groupByCategory = prefs.getBool("groupByCategory") ?? false;

    _loadItems();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("sortOption", _currentSort.index);
    await prefs.setBool("groupByCategory", _groupByCategory);
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
            trailing: _currentSort == option ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _currentSort = option);
              _savePreferences();
              _loadItems();
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 0.6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = theme.colorScheme.onSurface.withAlpha(153);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Inventory",
          style: TextStyle(
            fontFamily: 'LoveLight',
            fontSize: 40,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                /// SEARCH
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor, width: 0.6),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _loadItems(),
                    decoration: InputDecoration(
                      hintText: "Search items",
                      hintStyle: TextStyle(color: secondaryText),
                      icon: Icon(Icons.search_rounded, color: secondaryText),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// GROUP + SORT
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionButton(
                        theme,
                        icon: Icons.grid_view_rounded,
                        label: "Group By",
                        onTap: () {
                          setState(() {
                            _groupByCategory = !_groupByCategory;
                          });
                          _savePreferences();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOptionButton(
                        theme,
                        icon: Icons.swap_vert_rounded,
                        label: "Sort By",
                        onTap: _showSortOptions,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text("No inventory items found"))
                : _groupByCategory
                ? _buildGroupedList(theme, secondaryText)
                : _buildNormalList(theme, secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalList(ThemeData theme, Color secondaryText) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _items.length,
      itemBuilder: (_, index) {
        return _buildInventoryCard(_items[index], theme, secondaryText);
      },
    );
  }

  Widget _buildGroupedList(ThemeData theme, Color secondaryText) {
    final Map<String, List<InventoryItem>> grouped = {};

    for (var item in _items) {
      final category = item.category ?? "Uncategorized";
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
            ...entry.value.map(
              (item) => _buildInventoryCard(item, theme, secondaryText),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInventoryCard(
    InventoryItem item,
    ThemeData theme,
    Color secondaryText,
  ) {
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    Color statusColor;
    if (daysLeft < 0) {
      statusColor = Colors.red;
    } else if (daysLeft <= 3) {
      statusColor = Colors.orange;
    } else {
      statusColor = theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 0.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Qty: ${item.quantity}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "$daysLeft days",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
