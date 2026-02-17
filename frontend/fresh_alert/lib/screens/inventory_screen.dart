import 'package:flutter/material.dart';

class MyInventory extends StatefulWidget {
  const MyInventory({super.key});

  @override
  State<MyInventory> createState() => _MyInventoryState();
}

class _MyInventoryState extends State<MyInventory> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                /// FULL WIDTH SEARCH
                _buildSearchField(theme, secondaryText),

                const SizedBox(height: 14),

                /// GROUP BY + SORT BY
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionButton(
                        theme,
                        icon: Icons.grid_view_rounded,
                        label: "Group By",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOptionButton(
                        theme,
                        icon: Icons.swap_vert_rounded,
                        label: "Sort By",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 15,
              itemBuilder: (context, index) =>
                  _buildInventoryCard(context, theme, secondaryText, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme, Color secondaryText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 44,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 0.6),
      ),
      child: TextField(
        controller: _searchController,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: "Search items",
          hintStyle: TextStyle(color: secondaryText),
          icon: Icon(Icons.search_rounded, color: secondaryText),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildOptionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
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
        onTap: () {
          // TODO: Add bottom sheet or logic
        },
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

  Widget _buildInventoryCard(
    BuildContext context,
    ThemeData theme,
    Color secondaryText,
    int index,
  ) {
    final daysLeft = (index % 7) + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {},
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
                        "Product ${index + 1}",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "SKU: P${1001 + index}",
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
