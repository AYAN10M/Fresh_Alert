import 'package:flutter/material.dart';

class MySettings extends StatelessWidget {
  const MySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // PROFILE / BRAND CARD
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1DB954),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.black),
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Fresh Alert",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Smarter kitchen management",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // GENERAL SECTION
          const _SectionTitle(title: "General"),

          const SizedBox(height: 18),

          const _SettingsTile(
            icon: Icons.notifications_rounded,
            title: "Notifications",
            subtitle: "Expiry alerts & reminders",
          ),

          const SizedBox(height: 14),

          const _SettingsTile(
            icon: Icons.security_rounded,
            title: "Privacy",
            subtitle: "Local storage & permissions",
          ),

          const SizedBox(height: 36),

          // ABOUT SECTION
          const _SectionTitle(title: "About"),

          const SizedBox(height: 18),

          const _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: "App Version",
            subtitle: "1.0.0",
            showArrow: false,
          ),

          const SizedBox(height: 60),

          Center(
            child: Text(
              "Fresh Alert © 2026",
              style: TextStyle(
                fontFamily: 'Manrope',
                color: muted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Manrope',
        color: Colors.white60,
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      color: const Color(0xFF1C1C1C),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: showArrow ? () {} : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.circle,
                  size: 0, // placeholder, replaced below
                ),
              ),
              // We overlay icon to preserve clean structure
              PositionedIcon(icon: icon),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              if (showArrow)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white38,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PositionedIcon extends StatelessWidget {
  final IconData icon;

  const PositionedIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-44, 0),
      child: Container(
        height: 44,
        width: 44,
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: const Color(0xFF1DB954)),
      ),
    );
  }
}
