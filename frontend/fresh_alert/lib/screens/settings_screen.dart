import 'package:flutter/material.dart';

const _kBg = Color(0xFF0A0A0A);
const _kCard = Color(0xFF161616);
const _kGreen = Color(0xFF1DB954);
const _kBorder = Color(0xFF242424);

class MySettings extends StatelessWidget {
  const MySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),

      // ── Fixed layout — no scroll ─────────────────────────────────────
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── BRAND CARD ─────────────────────────────────────────
              _BrandCard(),

              const SizedBox(height: 28),

              // ── GENERAL ────────────────────────────────────────────
              const _SectionLabel("General"),
              const SizedBox(height: 10),

              _Tile(
                icon: Icons.notifications_outlined,
                title: "Notifications",
                subtitle: "Expiry alerts & reminders",
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _Tile(
                icon: Icons.lock_outline_rounded,
                title: "Privacy",
                subtitle: "Local storage & permissions",
                onTap: () {},
              ),

              const SizedBox(height: 28),

              // ── DATA ───────────────────────────────────────────────
              const _SectionLabel("Data"),
              const SizedBox(height: 10),

              _Tile(
                icon: Icons.download_outlined,
                title: "Export Inventory",
                subtitle: "Save a backup to your device",
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _Tile(
                icon: Icons.delete_outline_rounded,
                title: "Clear All Data",
                subtitle: "Remove all items permanently",
                onTap: () {},
                destructive: true,
              ),

              const SizedBox(height: 28),

              // ── ABOUT ──────────────────────────────────────────────
              const _SectionLabel("About"),
              const SizedBox(height: 10),

              _Tile(
                icon: Icons.info_outline_rounded,
                title: "App Version",
                subtitle: "1.0.0",
                showArrow: false,
              ),

              // pushes footer to the very bottom of the screen
              const Spacer(),

              // ── FOOTER ─────────────────────────────────────────────
              const Center(
                child: Text(
                  "Fresh Alert © 2026",
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    color: Colors.white24,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
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
// BRAND CARD
// ─────────────────────────────────────────────────────────────────────────────
class _BrandCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fresh Alert",
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Smarter kitchen management",
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _kGreen.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: const Text(
              "v1.0",
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: Colors.white38,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TILE
// ─────────────────────────────────────────────────────────────────────────────
class _Tile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool destructive;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showArrow = true,
    this.destructive = false,
  });

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.destructive ? const Color(0xFFFF453A) : _kGreen;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed ? accent.withValues(alpha: 0.05) : _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed ? accent.withValues(alpha: 0.2) : _kBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 18, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.destructive
                            ? const Color(0xFFFF453A)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showArrow)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
