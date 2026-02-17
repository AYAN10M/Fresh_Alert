import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fresh_alert/models/inventory_item.dart';
import 'package:fresh_alert/screens/qr_scanner_screen.dart';
import 'package:fresh_alert/screens/add_item_screen.dart';

// ── colour tokens (compatible with existing dark theme) ──────────────────────
const _kBg = Color(0xFF0A0A0A);
const _kCard = Color(0xFF161616);
const _kCardAlt = Color(0xFF1C1C1C);
const _kGreen = Color(0xFF1DB954);
const _kGreenLt = Color(0xFF1ED760);
const _kRed = Color(0xFFFF453A);
const _kOrange = Color(0xFFFF9F0A);
const _kBorder = Color(0xFF2A2A2A);

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
      backgroundColor: _kCardAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _AddTile(
                icon: Icons.qr_code_scanner_rounded,
                label: "Scan QR Code",
                sub: "Point camera at product label",
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

    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: _GreenFab(onTap: _showAddOptions),
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "FreshAlert",
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white54,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: _kGreen,
        backgroundColor: _kCardAlt,
        onRefresh: () async => _loadItems(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            // ── HERO ─────────────────────────────────────────────────────
            _HeroCard(
              expiringSoonCount: expiringSoon.length,
              healthPct: healthPct,
            ),

            const SizedBox(height: 28),

            // ── STATS ROW ─────────────────────────────────────────────────
            const _Label("Overview"),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: "Total",
                    value: total,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: "Expiring",
                    value: expiringSoon.length,
                    color: _kOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(label: "Expired", value: expired, color: _kRed),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── EXPIRING SOON ─────────────────────────────────────────────
            Row(
              children: [
                const Expanded(child: _Label("Expiring Soon")),
                if (expiringSoon.isNotEmpty)
                  Text(
                    "${expiringSoon.length} item${expiringSoon.length == 1 ? '' : 's'}",
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      color: Colors.white38,
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
    if (p > 0.6) return _kGreen;
    if (p > 0.3) return _kOrange;
    return _kRed;
  }

  @override
  Widget build(BuildContext context) {
    final hc = _hColor(healthPct);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3D2B), Color(0xFF0D2318)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kGreen.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "KITCHEN HEALTH",
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Colors.white38,
                ),
              ),
              const Spacer(),
              // health pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
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
            style: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _sub,
            style: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              color: Colors.white54,
            ),
          ),

          const SizedBox(height: 20),

          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: healthPct,
              minHeight: 5,
              backgroundColor: Colors.white10,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
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
            style: const TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              color: Colors.white38,
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

  Color get _color => daysLeft == 0 ? _kRed : _kOrange;

  String get _badge {
    if (daysLeft == 0) return "Today";
    if (daysLeft == 1) return "Tomorrow";
    return "$daysLeft days";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // glowing dot
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
                  style: const TextStyle(
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (item.category != null && item.category!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.category!,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 12,
                      color: Colors.white38,
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
              borderRadius: BorderRadius.circular(10),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: _kGreen, size: 36),
          SizedBox(height: 10),
          Text(
            "Nothing expiring soon",
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "You're all good for now 🎉",
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 13,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM FAB
// ─────────────────────────────────────────────────────────────────────────────
class _GreenFab extends StatefulWidget {
  final VoidCallback onTap;
  const _GreenFab({required this.onTap});

  @override
  State<_GreenFab> createState() => _GreenFabState();
}

class _GreenFabState extends State<_GreenFab> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kGreen, _kGreenLt],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.black, size: 20),
              SizedBox(width: 6),
              Text(
                "Add Item",
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ],
          ),
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
    style: const TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: Colors.white,
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
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: _kGreen.withValues(alpha: 0.07),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                  color: _kGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _kGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
