import 'package:flutter/material.dart';

class MySettings extends StatelessWidget {
  const MySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = theme.colorScheme.onSurface.withAlpha(153);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            fontFamily: 'LoveLight',
            fontSize: 40,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        children: [
          /// GENERAL
          Text(
            "General",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 24),

          const _SettingsCard(
            icon: Icons.notifications_rounded,
            title: "Notifications",
            subtitle: "Manage alerts & reminders",
          ),

          const SizedBox(height: 18),

          const _SettingsCard(
            icon: Icons.security_rounded,
            title: "Privacy",
            subtitle: "Permissions & data control",
          ),

          const SizedBox(height: 56),

          /// ABOUT
          Text(
            "About",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 24),

          const _SettingsCard(
            icon: Icons.info_outline_rounded,
            title: "App Version",
            subtitle: "1.0.0",
            showArrow: false,
          ),

          const SizedBox(height: 72),

          Center(
            child: Text(
              "Fresh Alert © 2026",
              style: theme.textTheme.bodySmall?.copyWith(color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showArrow;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = theme.colorScheme.onSurface.withAlpha(153);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: showArrow ? () {} : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor, width: 0.6),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
