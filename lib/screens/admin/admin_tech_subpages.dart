import 'package:flutter/material.dart';
import 'package:dompis_app/core/theme.dart';

/// Placeholder for Technician Attendance Recap page.
class AdminTechAttendanceScreen extends StatelessWidget {
  const AdminTechAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.calendar_today_rounded,
      title: 'Rekap Absensi Teknisi',
      subtitle: 'Data rekap absensi bulanan teknisi akan ditampilkan di sini.',
    );
  }
}

/// Placeholder for Technician Performance page.
class AdminTechPerformanceScreen extends StatelessWidget {
  const AdminTechPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.check_circle_outline_rounded,
      title: 'Rekap Pekerjaan Bulanan',
      subtitle: 'Data rekap pekerjaan bulanan teknisi akan ditampilkan di sini.',
    );
  }
}

/// Placeholder for Technician ManHours page.
class AdminTechManhoursScreen extends StatelessWidget {
  const AdminTechManhoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.trending_up_rounded,
      title: 'Produktivitas ManHours',
      subtitle: 'Data produktivitas manhours teknisi akan ditampilkan di sini.',
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
