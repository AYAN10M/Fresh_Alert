import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/theme/app_colors.dart';

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
    // Hive watch: inventory list updates the moment anything is
    // added or deleted — no app restart needed.
    _box.watch().listen((_) {
      if (mounted) _loadItems();
    });
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
          .where(
            (item) =>
                item.name.toLowerCase().contains(query) ||
                (item.category?.toLowerCase().contains(query) ?? false),
          )
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
  // EDIT QUANTITY: in-place update inside Hive
  // ─────────────────────────────────────────────────────────
  void _showEditQuantityDialog(InventoryItem target) {
    final qtyController = TextEditingController(
      text: target.quantity.toString(),
    );
    final c = AppColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          target.name,
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w700,
            color: c.onSurface,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Update quantity',
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  color: c.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
              ),
              cursorColor: c.primary,
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'NotoSans',
                color: c.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newQty =
                  int.tryParse(qtyController.text) ?? target.quantity;
              if (newQty > 0 && newQty != target.quantity) {
                // Find the Hive key and update
                for (final entry in _box.toMap().entries) {
                  final map = Map<String, dynamic>.from(entry.value);
                  final item = InventoryItem.fromMap(map);
                  if (item.id == target.id) {
                    final updated = target.copyWith(quantity: newQty);
                    _box.put(entry.key, updated.toMap());
                    break;
                  }
                }
                _loadItems();
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontWeight: FontWeight.w700,
                color: c.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Undo snackbar – shown after every swipe delete
  // ─────────────────────────────────────────────────────────
  void _showUndoSnackbar(InventoryItem deleted) {
    final map = deleted.toMap(); // snapshot before delete
    final c = AppColors.of(context);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${deleted.name} removed',
          style: TextStyle(color: c.snackbarText, fontFamily: 'NotoSans'),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          textColor: c.primary,
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
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Inventory",
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: c.onSurface,
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
                    color: c.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: c.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _loadItems(),
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            color: c.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search groceries...",
                            hintStyle: TextStyle(
                              fontFamily: 'NotoSans',
                              color: c.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── GROUP & SORT ─────────────────────────────────
                if (isCompact)
                  Column(
                    children: [
                      _ActionButton(
                        icon: Icons.category_rounded,
                        label: _groupByCategory ? "Grouped" : "Group By",
                        active: _groupByCategory,
                        onTap: () {
                          setState(() => _groupByCategory = !_groupByCategory);
                          _savePreferences();
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        icon: Icons.swap_vert_rounded,
                        label: "Sort",
                        active: false,
                        onTap: _showSortOptions,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.category_rounded,
                          label: _groupByCategory ? "Grouped" : "Group By",
                          active: _groupByCategory,
                          onTap: () {
                            setState(
                              () => _groupByCategory = !_groupByCategory,
                            );
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: c.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: c.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: c.primary,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your kitchen is empty',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontWeight: FontWeight.w600,
                              color: c.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add items from the dashboard ➕',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 13,
                              color: c.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
          onTap: () => _showEditQuantityDialog(item),
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
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).onSurface,
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
                onTap: () => _showEditQuantityDialog(item),
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
  final VoidCallback? onTap;

  const _SwipableCard({required this.item, required this.onDelete, this.onTap});

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
          color: StatusColors.red,
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
      child: GestureDetector(
        onTap: onTap,
        child: _InventoryCard(item: item),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD UI  –  theme-aware
// ─────────────────────────────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final InventoryItem item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    Color statusColor;
    if (daysLeft < 0) {
      statusColor = StatusColors.red;
    } else if (daysLeft <= 3) {
      statusColor = StatusColors.orange;
    } else {
      statusColor = c.primary;
    }

    final bool hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final bool isLocal = hasImage && !item.imageUrl!.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: c.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          // Product image or status bar
          if (hasImage)
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: isLocal
                    ? Image.file(
                        File(item.imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, s) => Icon(
                          Icons.image_not_supported_outlined,
                          size: 18,
                          color: c.onSurfaceVariant,
                        ),
                      )
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, s) => Icon(
                          Icons.image_not_supported_outlined,
                          size: 18,
                          color: c.onSurfaceVariant,
                        ),
                      ),
              ),
            )
          else
            Container(
              width: 6,
              height: 42,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: c.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Qty: ${item.quantity}",
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    if (item.location != null && item.location!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: c.onSurface.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.location!,
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Days remaining
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              daysLeft < 0 ? "Expired" : "${daysLeft}d",
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON  –  theme-aware
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
    final c = AppColors.of(context);

    return Material(
      borderRadius: BorderRadius.circular(8),
      color: active
          ? c.surfaceContainerHigh
          : c.primary.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? c.onSurface : c.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w600,
                  color: active ? c.onSurface : c.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
