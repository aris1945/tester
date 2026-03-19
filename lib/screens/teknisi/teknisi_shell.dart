import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/screens/teknisi/teknisi_dashboard.dart';
import 'package:dompis_app/screens/teknisi/attendance_screen.dart';
import 'package:dompis_app/widgets/profile_page.dart';
import 'package:dompis_app/providers/navigation_provider.dart';

class TeknisiShell extends ConsumerStatefulWidget {
  const TeknisiShell({super.key});

  @override
  ConsumerState<TeknisiShell> createState() => _TeknisiShellState();
}

class _TeknisiShellState extends ConsumerState<TeknisiShell> {
  final List<Widget> _screens = const [
    TeknisiDashboard(),
    AttendanceScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(teknisiNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.themeColors.card,
          border: Border(
            top: BorderSide(color: context.themeColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.confirmation_number_rounded, 'Tiket', currentIndex),
                _buildNavItem(1, Icons.fingerprint_rounded, 'Absensi', currentIndex),
                _buildNavItem(2, Icons.person_rounded, 'Profil', currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int currentIndex) {
    final isActive = currentIndex == index;

    return InkWell(
      onTap: () => ref.read(teknisiNavIndexProvider.notifier).state = index,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.primary : context.themeColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : context.themeColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
