import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/providers/api_providers.dart';

class AdminTechniciansScreen extends ConsumerStatefulWidget {
  const AdminTechniciansScreen({super.key});

  @override
  ConsumerState<AdminTechniciansScreen> createState() =>
      _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState
    extends ConsumerState<AdminTechniciansScreen> {
  List<dynamic> _technicians = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _fetchTechnicians() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(ApiConstants.technicians);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        setState(() {
          _technicians = (data['data'] as List?) ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['message'] as String? ?? 'Gagal memuat data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data teknisi';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchTechnicians,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title + sub-links
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monitoring Teknisi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _fetchTechnicians,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sub links
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSubLink(
                icon: Icons.calendar_today_rounded,
                label: 'Rekap Absensi',
                route: '/admin/technicians/attendance',
              ),
              _buildSubLink(
                icon: Icons.check_circle_outline_rounded,
                label: 'Rekap Bulanan',
                route: '/admin/technicians/performance',
              ),
              _buildSubLink(
                icon: Icons.trending_up_rounded,
                label: 'ManHours',
                route: '/admin/technicians/manhours',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Content
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _buildErrorState()
          else if (_technicians.isEmpty)
            _buildEmptyState()
          else
            ..._technicians.map((tech) => _buildTechCard(tech)),
        ],
      ),
    );
  }

  Widget _buildSubLink({
    required IconData icon,
    required String label,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechCard(dynamic tech) {
    final name = tech['nama']?.toString() ?? 'Unknown';
    final workzone = tech['workzone']?.toString() ?? '-';
    final totalAssigned = tech['total_assigned'] as int? ?? 0;
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    String status;
    Color statusColor;
    if (totalAssigned == 0) {
      status = 'Idle';
      statusColor = AppColors.textMuted;
    } else if (totalAssigned > 3) {
      status = 'Overload';
      statusColor = Colors.red;
    } else {
      status = 'Aktif';
      statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      workzone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$status · $totalAssigned tiket',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _fetchTechnicians,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.engineering_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Belum ada data teknisi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
