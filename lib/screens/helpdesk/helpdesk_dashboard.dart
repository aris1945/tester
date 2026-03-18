import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/providers/auth_provider.dart';
import 'package:dompis_app/widgets/stat_card.dart';

class HelpdeskDashboard extends ConsumerStatefulWidget {
  const HelpdeskDashboard({super.key});

  @override
  ConsumerState<HelpdeskDashboard> createState() => _HelpdeskDashboardState();
}

class _HelpdeskDashboardState extends ConsumerState<HelpdeskDashboard> {
  bool _loading = true;
  int _total = 0, _open = 0, _assigned = 0, _closed = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(ticketApiProvider);
      final data = await api.getTicketStats();
      if (data['success'] == true && data['data'] != null) {
        final stats = data['data'] as Map<String, dynamic>;
        setState(() {
          _total = stats['total'] as int? ?? 0;
          _open = stats['open'] as int? ?? 0;
          _assigned = stats['assigned'] as int? ?? 0;
          _closed = stats['closed'] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Helpdesk Dashboard',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Manage and monitor tickets',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(authProvider.notifier).logout(),
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2,
                  children: [
                    StatCard(
                        label: 'Total',
                        value: _total,
                        color: AppColors.primary,
                        loading: _loading),
                    StatCard(
                        label: 'Open',
                        value: _open,
                        color: AppColors.open,
                        loading: _loading),
                    StatCard(
                        label: 'Assigned',
                        value: _assigned,
                        color: AppColors.assigned,
                        loading: _loading),
                    StatCard(
                        label: 'Closed',
                        value: _closed,
                        color: AppColors.closed,
                        loading: _loading),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
