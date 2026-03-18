import 'package:flutter/material.dart';
import 'package:dompis_app/core/theme.dart';

/// Placeholder screen for Semesta Dompis analytics page.
/// Full implementation coming in a later phase.
class AdminSemestaScreen extends StatelessWidget {
  const AdminSemestaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Title
          const Text(
            'Dompis Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unified view of tickets, workload, and trend.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Placeholder cards
          _buildPlaceholderCard(
            icon: Icons.bar_chart_rounded,
            title: 'Stats Overview',
            subtitle: 'Total, Open, In Progress, Closed',
          ),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.pie_chart_rounded,
            title: 'Ticket Type Distribution',
            subtitle: 'By customer type and ticket category',
          ),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.show_chart_rounded,
            title: 'Ticket Trend',
            subtitle: 'Daily/monthly ticket trends',
          ),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.table_chart_rounded,
            title: 'Ticket Table',
            subtitle: 'Full ticket list with filters',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
