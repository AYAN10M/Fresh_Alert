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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        .map((e) => InventoryItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      items = items
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    }

    _applySorting(items);
    setState(() => _items = items);
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

  String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.expiryNearest:
        return "Expiry (Nearest)";
      case SortOption.expiryFarthest:
        return "Expiry (Farthest)";
      case SortOption.recentlyAdded:
        return "Recently Added";
      case SortOption.quantity:
        return "Quantity";
    }
  }

  // ─────────────────────────────────────────────────────────
  // DELETE: find the item's key inside Hive and erase it
  // ─────────────────────────────────────────────────────────
  void _deleteItem(InventoryItem target) {
    // Walk every Hive entry to find the matching id
    dynamic targetKey;
    for (final entry in _box.toMap().entries) {
      final map = Map<String, dynamic>.from(entry.value);
      final item = InventoryItem.fromMap(map);
      if (item.id == target.id) {
        targetKey = entry.key;
        break;
      }
    }

    if (targetKey != null) {
      _box.delete(targetKey);
      _loadItems(); // refresh list
    }
  }

  // ─────────────────────────────────────────────────────────
  // Undo snackbar – shown after every swipe delete
  // ─────────────────────────────────────────────────────────
  void _showUndoSnackbar(InventoryItem deleted) {
    final map = deleted.toMap(); // snapshot before delete

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${deleted.name} removed',
          style: const TextStyle(color: Colors.white, fontFamily: 'NotoSans'),
        ),
        backgroundColor: const Color(0xFF1C1C1C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF38B000),
          onPressed: () {
            _box.add(map); // re-add the exact same data
            _loadItems();
          },
        ),
      ),
    );
  }

  void _showSortOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: SortOption.values.map((option) {
              final selected = _currentSort == option;
              return ListTile(
                title: Text(_sortLabel(option)),
                trailing: selected
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSort = option);
                  _savePreferences();
                  _loadItems();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Inventory",
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              children: [
                // ── SEARCH ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _loadItems(),
                          decoration: const InputDecoration(
                            hintText: "Search groceries...",
                            hintStyle: TextStyle(
                              fontFamily: 'NotoSans',
                              color: Colors.white60,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── GROUP & SORT ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.category_rounded,
                        label: _groupByCategory ? "Grouped" : "Group By",
                        active: _groupByCategory,
                        onTap: () {
                          setState(() => _groupByCategory = !_groupByCategory);
                          _savePreferences();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.swap_vert_rounded,
                        label: "Sort",
                        active: false,
                        onTap: _showSortOptions,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      "Your kitchen is empty 🛒",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  )
                : _groupByCategory
                ? _buildGroupedList()
                : _buildNormalList(),
          ),
        ],
      ),
    );
  }

  // ── LIST BUILDERS ──────────────────────────────────────────────────────────

  Widget _buildNormalList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _items.length,
      itemBuilder: (_, index) {
        final item = _items[index];
        return _SwipableCard(
          item: item,
          onDelete: () {
            _showUndoSnackbar(item);
            _deleteItem(item);
          },
        );
      },
    );
  }

  Widget _buildGroupedList() {
    final Map<String, List<InventoryItem>> grouped = {};

    for (final item in _items) {
      final category = item.category ?? "Uncategorized";
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Text(
              entry.key,
              style: const TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...entry.value.map(
              (item) => _SwipableCard(
                item: item,
                onDelete: () {
                  _showUndoSnackbar(item);
                  _deleteItem(item);
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWIPABLE CARD  ←  replaces the old _InventoryCard
// Swipe left  → red delete background appears → item removed
// ─────────────────────────────────────────────────────────────────────────────
class _SwipableCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onDelete;

  const _SwipableCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // Each card needs a unique key so Flutter can track it
      key: ValueKey(item.id),

      // Only allow swiping from right to left
      direction: DismissDirection.endToStart,

      // Called when the swipe animation completes
      onDismissed: (_) => onDelete(),

      // Red background revealed while swiping
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      // The visible card (same design as before, just wrapped)
      child: _InventoryCard(item: item),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD UI  –  unchanged visual design
// ─────────────────────────────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final InventoryItem item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    Color statusColor;
    if (daysLeft < 0) {
      statusColor = Colors.redAccent;
    } else if (daysLeft <= 3) {
      statusColor = Colors.orangeAccent;
    } else {
      statusColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Coloured status bar on the left
          Container(
            width: 6,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),

          // Name + quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Qty: ${item.quantity}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Days remaining
          Text(
            daysLeft < 0 ? "Expired" : "$daysLeft d",
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON  –  unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(8),
      color: active
          ? theme.colorScheme.primary.withValues(alpha: 0)
          : theme.colorScheme.primary.withValues(alpha: 0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
