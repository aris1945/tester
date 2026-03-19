import 'package:flutter/material.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/providers/theme_provider.dart';

class DrawerMenuItem {
  final String label;
  final IconData icon;
  final String route;

  const DrawerMenuItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class AppDrawer extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<DrawerMenuItem> menuItems;
  final String currentRoute;
  final String? userName;
  final String? userRole;
  final VoidCallback onLogout;
  final void Function(String route) onNavigate;

  const AppDrawer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.menuItems,
    required this.currentRoute,
    required this.onLogout,
    required this.onNavigate,
    this.userName,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final initials = (userName ?? 'U')
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Drawer(
      backgroundColor: context.themeColors.card,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: context.themeColors.textPrimary.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.themeColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.themeColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Consumer(
                    builder: (context, ref, child) {
                      final themeMode = ref.watch(themeProvider);
                      return IconButton(
                        icon: Icon(
                          themeMode == ThemeMode.dark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: themeMode == ThemeMode.dark ? Colors.amber : context.themeColors.textPrimary,
                        ),
                        onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MAIN',
                  style: TextStyle(
                    color: context.themeColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: menuItems.map((item) {
                  final isActive = currentRoute == item.route;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: isActive
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          onNavigate(item.route);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isActive
                                    ? AppColors.primary
                                    : context.themeColors.textSecondary,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.primary
                                      : context.themeColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // User card at bottom
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themeColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.themeColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? 'User',
                          style: TextStyle(
                            color: context.themeColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole ?? '',
                          style: TextStyle(
                            color: context.themeColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: context.themeColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
