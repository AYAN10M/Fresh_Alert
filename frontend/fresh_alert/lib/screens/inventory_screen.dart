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
    final secondaryText = theme.colorScheme.onSurface.withOpacity(0.6);

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
          /// SEARCH + FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Expanded(child: _buildSearchField(theme, secondaryText)),
                const SizedBox(width: 12),
                _buildFilterButton(theme),
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

  Widget _buildFilterButton(ThemeData theme) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 0.6),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.tune_rounded, size: 18),
        onPressed: () {},
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
