import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/screens/qr_scanner_screen.dart';
import 'package:fresh_alert/screens/add_item_screen.dart';
import 'package:fresh_alert/theme/app_colors.dart';

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
    // Hive watch: fires instantly on any add/delete/update.
    // No manual reload needed — dashboard always stays in sync.
    _box.watch().listen((_) {
      if (mounted) _loadItems();
    });
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
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: c.dragHandle,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              _AddTile(
                icon: Icons.qr_code_scanner_rounded,
                label: "Scan Barcode",
                sub: "Point camera at product barcode or QR code",
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
              const SizedBox(height: 12),
              _AddTile(
                icon: Icons.edit_rounded,
                label: "Add Manually",
                sub: "Type product details by hand",
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
    final total = _items.length;
    final expired = _items.where((e) => e.expiryDate.isBefore(today)).length;
    final fresh = _items
        .where((e) => e.expiryDate.difference(today).inDays > 3)
        .length;
    final expiringSoon = _items.where((e) {
      final d = e.expiryDate.difference(today).inDays;
      return d >= 0 && d <= 3;
    }).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    final healthPct = total == 0 ? 1.0 : fresh / total;
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final theme = Theme.of(context);
    final c = AppColors.of(context);

    final unreadCount = expiringSoon.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'lib/assets/App Icon/icon.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              "FreshAlert",
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: c.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _AppBarBtn(
              onTap: () => _showNotifications(context, expiringSoon),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 19,
                    color: c.onSurfaceVariant,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: StatusColors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AppBarBtn(
              onTap: _showAddOptions,
              filled: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: c.onPrimary),
                  SizedBox(width: 4),
                  Text(
                    "Add",
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surfaceContainerHigh,
        onRefresh: () async => _loadItems(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            _HeroCard(
              expiringSoonCount: expiringSoon.length,
              healthPct: healthPct,
            ),
            const SizedBox(height: 28),
            const _Label("Overview"),
            const SizedBox(height: 14),
            if (isCompact)
              Column(
                children: [
                  _Stat(label: "Total", value: total, color: c.onSurface),
                  const SizedBox(height: 12),
                  _Stat(
                    label: "Expiring",
                    value: expiringSoon.length,
                    color: StatusColors.orange,
                  ),
                  const SizedBox(height: 12),
                  _Stat(label: "Expired", value: expired, color: StatusColors.red),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: "Total",
                      value: total,
                      color: c.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      label: "Expiring",
                      value: expiringSoon.length,
                      color: StatusColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      label: "Expired",
                      value: expired,
                      color: StatusColors.red,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(child: _Label("Expiring Soon")),
                if (expiringSoon.isNotEmpty)
                  Text(
                    "${expiringSoon.length} item${expiringSoon.length == 1 ? '' : 's'}",
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      color: c.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (expiringSoon.isEmpty)
              _EmptyBanner()
            else
              ...expiringSoon.take(5).toList().asMap().entries.map((e) {
                final days = e.value.expiryDate.difference(today).inDays;
                return _SlideFade(
                  delay: e.key * 80,
                  child: _ExpiryRow(item: e.value, daysLeft: days),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, List<InventoryItem> expiring) {
    final today = DateTime.now();
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: c.dragHandle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Text(
                'Notifications',
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (expiring.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: c.onSurfaceVariant.withValues(alpha: 0.4),
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No upcoming expirations',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontSize: 14,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...expiring.take(8).map((item) {
                  final days = item.expiryDate.difference(today).inDays;
                  final color = days == 0 ? StatusColors.red : StatusColors.orange;
                  final label = days == 0
                      ? 'Expires today'
                      : days == 1
                      ? 'Expires tomorrow'
                      : 'Expires in $days days';

                  final hasImage =
                      item.imageUrl != null && item.imageUrl!.isNotEmpty;
                  final isLocal =
                      hasImage && !item.imageUrl!.startsWith('http');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        if (hasImage)
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: isLocal
                                  ? Image.file(
                                      File(item.imageUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: color,
                                      ),
                                    )
                                  : Image.network(
                                      item.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: color,
                                      ),
                                    ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: color,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: c.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                label,
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 12,
                                  color: color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final int expiringSoonCount;
  final double healthPct;

  const _HeroCard({required this.expiringSoonCount, required this.healthPct});

  String get _headline => expiringSoonCount == 0
      ? "All items are fresh 🎉"
      : expiringSoonCount == 1
      ? "1 item needs attention"
      : "$expiringSoonCount items need attention";

  String get _sub => expiringSoonCount == 0
      ? "Your kitchen is in great shape."
      : "Check the expiring items below.";

  Color _hColor(double p) {
    if (p > 0.6) return StatusColors.green;
    if (p > 0.3) return StatusColors.orange;
    return StatusColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final hc = _hColor(healthPct);
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.heroGradientStart, c.heroGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hc.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                "KITCHEN HEALTH",
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: c.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hc.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  "${(healthPct * 100).round()}% Fresh",
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hc,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            _headline,
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.onSurface,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            _sub,
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              color: c.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 20),

          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: healthPct,
              minHeight: 5,
              backgroundColor: c.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(hc),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: c.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            builder: (_, v, _) => Text(
              "$v",
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              color: c.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPIRY ROW
// ─────────────────────────────────────────────────────────────────────────────
class _ExpiryRow extends StatelessWidget {
  final InventoryItem item;
  final int daysLeft;

  const _ExpiryRow({required this.item, required this.daysLeft});

  Color get _color => daysLeft == 0 ? StatusColors.red : StatusColors.orange;

  String get _badge {
    if (daysLeft == 0) return "Today";
    if (daysLeft == 1) return "Tomorrow";
    return "$daysLeft days";
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bool hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final bool isLocal = hasImage && !item.imageUrl!.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: c.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          // Product image or glowing dot
          if (hasImage)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _color.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: isLocal
                    ? Image.file(
                        File(item.imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.fastfood_outlined,
                          size: 16,
                          color: _color,
                        ),
                      )
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.fastfood_outlined,
                          size: 16,
                          color: _color,
                        ),
                      ),
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

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
                if (item.category != null && item.category!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.category!,
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 12,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              _badge,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: c.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: StatusColors.green, size: 36),
          SizedBox(height: 10),
          Text(
            "Nothing expiring soon",
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontWeight: FontWeight.w600,
              color: c.onSurface,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "You're all good for now 🎉",
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR BUTTON  — used for both the bell and the Add pill
// ─────────────────────────────────────────────────────────────────────────────
class _AppBarBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool filled; // true → green pill, false → ghost border

  const _AppBarBtn({
    required this.child,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_AppBarBtn> createState() => _AppBarBtnState();
}

class _AppBarBtnState extends State<_AppBarBtn> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.88),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: widget.filled
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 7)
              : const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.filled ? c.primary : c.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: widget.filled
                ? null
                : Border.all(
                    color: c.outlineVariant.withValues(alpha: 0.45),
                    width: 1,
                  ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.of(context).onSurface,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE + FADE ANIMATION
// ─────────────────────────────────────────────────────────────────────────────
class _SlideFade extends StatelessWidget {
  final Widget child;
  final int delay;
  const _SlideFade({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 380 + delay),
    curve: Curves.easeOut,
    builder: (_, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
    ),
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD TILE  (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _AddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _AddTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: c.primary.withValues(alpha: 0.07),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: c.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: c.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: c.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
