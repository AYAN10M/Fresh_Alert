import 'package:flutter/material.dart';
import 'package:fresh_alert/screens/qr_scanner_screen.dart';

class MyDashboard extends StatelessWidget {
  final bool isDark;
  final Function(bool) onToggleTheme;

  const MyDashboard({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    const double actionHeight = 36;
    const Duration animationDuration = Duration(milliseconds: 320);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontFamily: 'LoveLight',
            fontSize: 40,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                /// ADD BUTTON
                Container(
                  height: actionHeight,
                  width: actionHeight,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor, width: 0.6),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QrScannerScreen(),
                        ),
                      );

                      if (result != null && context.mounted) {
                        print("Scanned QR: $result");

                        // Show success dialog with scanned value
                        _showScanResultDialog(context, result);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),

                /// THEME TOGGLE
                GestureDetector(
                  onTap: () => onToggleTheme(!isDark),
                  child: AnimatedContainer(
                    duration: animationDuration,
                    curve: Curves.easeInOut,
                    height: actionHeight,
                    width: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor, width: 0.6),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedOpacity(
                              duration: animationDuration,
                              opacity: isDark ? 0.4 : 1,
                              child: const Icon(
                                Icons.light_mode_rounded,
                                size: 16,
                              ),
                            ),
                            AnimatedOpacity(
                              duration: animationDuration,
                              opacity: isDark ? 1 : 0.4,
                              child: const Icon(
                                Icons.dark_mode_rounded,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        AnimatedAlign(
                          duration: animationDuration,
                          curve: Curves.easeInOut,
                          alignment: isDark
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: animationDuration,
                            curve: Curves.easeInOut,
                            height: 26,
                            width: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overview", style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _DashboardCard(title: "Total Items", value: "34"),
                _DashboardCard(title: "Expiring Soon", value: "5"),
                _DashboardCard(title: "Expired", value: "2"),
                _DashboardCard(title: "Added Today", value: "3"),
              ],
            ),
            const SizedBox(height: 56),
            Text("Expiring Soon", style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            const _ExpiryItemCard(name: "Milk", daysLeft: 2),
            const _ExpiryItemCard(name: "Spinach", daysLeft: 1),
            const _ExpiryItemCard(name: "Yogurt", daysLeft: 3),
          ],
        ),
      ),
    );
  }

  // Show dialog with scan result
  void _showScanResultDialog(BuildContext context, String qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            const Text('QR Code Scanned'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scanned Value:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withAlpha(100)),
              ),
              child: SelectableText(
                qrCode,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Next step: Add expiry date and save to inventory',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add to inventory feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Add to Inventory'),
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
      padding: const EdgeInsets.all(22),
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
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 0.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            "$daysLeft days",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
