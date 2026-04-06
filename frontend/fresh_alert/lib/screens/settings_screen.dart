import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fresh_alert/services/theme_service.dart';
import 'package:fresh_alert/theme/app_colors.dart';

class MySettings extends StatelessWidget {
  const MySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          "Settings",
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: c.onSurface,
          ),
        ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── BRAND CARD ─────────────────────────────────────────
                      _BrandCard(),

                      const SizedBox(height: 28),

                      // ── GENERAL ────────────────────────────────────────────
                      const _SectionLabel("Appearance"),
                      const SizedBox(height: 10),

                      const _ThemeSelectorCard(),

                      const SizedBox(height: 28),

                      // ── GENERAL ────────────────────────────────────────────
                      const _SectionLabel("General"),
                      const SizedBox(height: 10),

                      _Tile(
                        icon: Icons.notifications_outlined,
                        title: "Notifications",
                        subtitle: "Expiry alerts & reminders",
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Manage notifications in your device settings',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _Tile(
                        icon: Icons.lock_outline_rounded,
                        title: "Privacy",
                        subtitle: "Local storage & permissions",
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Fresh Alert',
                            applicationVersion: '1.0.0',
                            children: [
                              const Text(
                                'All your data is stored locally on your device. '
                                'Fresh Alert does not collect or share any personal information.',
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // ── DATA ───────────────────────────────────────────────
                      const _SectionLabel("Data"),
                      const SizedBox(height: 10),

                      _Tile(
                        icon: Icons.download_outlined,
                        title: "Export Inventory",
                        subtitle: "Copy backup to clipboard",
                        onTap: () {
                          final box = Hive.box('inventoryBox');
                          final data = box.values
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList();
                          final json = const JsonEncoder.withIndent(
                            '  ',
                          ).convert(data);
                          Clipboard.setData(ClipboardData(text: json));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Inventory copied (${data.length} items)',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _Tile(
                        icon: Icons.delete_outline_rounded,
                        title: "Clear All Data",
                        subtitle: "Remove all items permanently",
                        onTap: () {
                          _showClearDataDialog(context);
                        },
                        destructive: true,
                      ),

                      const SizedBox(height: 28),

                      // ── ABOUT ──────────────────────────────────────────────
                      const _SectionLabel("About"),
                      const SizedBox(height: 10),

                      _Tile(
                        icon: Icons.info_outline_rounded,
                        title: "About",
                        subtitle: "Message from the developer",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const _AboutScreen(),
                            ),
                          );
                        },
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final c = AppColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Clear All Data?',
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w700,
            color: c.onSurface,
          ),
        ),
        content: Text(
          'This will permanently delete all items from your inventory. This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'NotoSans',
            color: c.onSurfaceVariant,
            fontSize: 14,
          ),
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
              Hive.box('inventoryBox').clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('All data cleared')));
            },
            child: Text(
              'Delete All',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontWeight: FontWeight.w700,
                color: StatusColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelectorCard extends StatelessWidget {
  const _ThemeSelectorCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose app theme',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Follow your system or lock Fresh Alert to light or dark mode.',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.mode,
            builder: (context, mode, _) {
              return Row(
                children: [
                  Expanded(
                    child: _ThemeChoiceChip(
                      label: 'System',
                      icon: Icons.brightness_auto_rounded,
                      selected: mode == ThemeMode.system,
                      onTap: () => ThemeService.setMode(ThemeMode.system),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ThemeChoiceChip(
                      label: 'Light',
                      icon: Icons.light_mode_rounded,
                      selected: mode == ThemeMode.light,
                      onTap: () => ThemeService.setMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ThemeChoiceChip(
                      label: 'Dark',
                      icon: Icons.dark_mode_rounded,
                      selected: mode == ThemeMode.dark,
                      onTap: () => ThemeService.setMode(ThemeMode.dark),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final background = selected
        ? c.primary.withValues(alpha: 0.15)
        : c.surfaceContainerLow;
    final foreground = selected ? c.primary : c.onSurfaceVariant;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
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
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'lib/assets/App Icon/icon.png',
              width: 48,
              height: 48,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fresh Alert",
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                Text(
                  "Smarter kitchen management",
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 13,
                    color: c.onSurfaceVariant,
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
    final c = AppColors.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: c.onSurfaceVariant,
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
    final c = AppColors.of(context);
    final accent = widget.destructive ? StatusColors.red : c.primary;
    final cardColor = c.surfaceContainerHigh;
    final borderColor = widget.destructive
        ? accent.withValues(alpha: 0.2)
        : c.outlineVariant.withValues(alpha: 0.6);
    final titleColor = widget.destructive ? accent : c.onSurface;

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
            color: _pressed ? accent.withValues(alpha: 0.06) : cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _pressed ? accent.withValues(alpha: 0.2) : borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
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
              if (widget.showArrow)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: c.onSurfaceVariant.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT SCREEN — message from the developer
// ─────────────────────────────────────────────────────────────────────────────
class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.onSurfaceVariant),
        titleSpacing: 4,
        title: Text(
          "About",
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: c.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── App icon ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'lib/assets/App Icon/icon.png',
                    width: 72,
                    height: 72,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Title ──
                Text(
                  "Built with ♥ by Ayan Haldar",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.onSurface,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Story ──
                Text(
                  "This app started as a simple idea \nstop wasting things at home.\n\n"
                  "No big team. No funding. Just a problem\n"
                  "I noticed and decided to fix.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 14,
                    color: c.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "I love building real world apps that solve\n"
                  "everyday problems, big or small.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 14,
                    color: c.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "If you have an idea a clone, a tool,\n"
                  "something innovative, or just a small\n"
                  "fun project, I'd love to build it\nwith you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 14,
                    color: c.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Link buttons ──
                Row(
                  children: [
                    Expanded(
                      child: _LinkButton(
                        icon: Icons.language_rounded,
                        label: "Website",
                        onTap: () => _openUrl("https://ayanhaldar.vercel.app"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LinkButton(
                        icon: Icons.work_outline_rounded,
                        label: "LinkedIn",
                        onTap: () =>
                            _openUrl("https://linkedin.com/in/haldar-ayan"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Text(
                  "Let's connect and build something.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Fresh Alert v1.0.0",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 12,
                    color: c.onSurfaceVariant.withValues(alpha: 0.5),
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

// ─────────────────────────────────────────────────────────────────────────────
// LINK BUTTON — rectangular, matching app style
// ─────────────────────────────────────────────────────────────────────────────
class _LinkButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: c.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
