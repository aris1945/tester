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
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _technicians = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedWorkzone;
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _fetchTechnicians() async {
    setState(() {
      _loading = true;
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
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Local filtering
    final filteredTechs = _technicians.where((tech) {
      final matchesSearch =
          tech['nama']?.toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ??
          true;
      final matchesWorkzone =
          _selectedWorkzone == null || tech['workzone'] == _selectedWorkzone;
      // 'status' mapping depends on your data, using a simple check here
      final techStatus = (tech['total_assigned'] as int? ?? 0) == 0
          ? 'Idle'
          : 'Active';
      final matchesStatus =
          _selectedStatus == null || techStatus == _selectedStatus;

      return matchesSearch && matchesWorkzone && matchesStatus;
    }).toList();

    final total = _technicians.length;
    final assigned = _technicians
        .where((t) => (t['total_assigned'] as int? ?? 0) > 0)
        .length;
    final onProgress = _technicians
        .where(
          (t) =>
              (t['total_assigned'] as int? ?? 0) > 0 &&
              (t['total_assigned'] as int? ?? 0) < 4,
        )
        .length;
    final pending = _technicians
        .where((t) => (t['total_assigned'] as int? ?? 0) >= 4)
        .length;

    return Scaffold(
      backgroundColor: context.themeColors.surface,
      body: RefreshIndicator(
        onRefresh: _fetchTechnicians,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Monitoring Teknisi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.themeColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Area info
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: context.themeColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Area: KRP, LKI',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.themeColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Navigation Links
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildHeaderLink(
                            Icons.calendar_month_outlined,
                            'Rekap\nAbsensi',
                            '/admin/technicians/attendance',
                          ),
                          _buildLinkDivider(),
                          _buildHeaderLink(
                            Icons.check_circle_outline_rounded,
                            'Rekap\nPekerjaan\nBulanan',
                            '/admin/technicians/performance',
                          ),
                          _buildLinkDivider(),
                          _buildHeaderLink(
                            Icons.trending_up,
                            'Produktivitas\nManHours',
                            '/admin/technicians/manhours',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Last update info
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: context.themeColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Diperbarui kurang dari 1 menit yang lalu',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.themeColors.textMuted,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _fetchTechnicians,
                          icon: const Icon(Icons.refresh_rounded),
                          iconSize: 20,
                          color: context.themeColors.textMuted,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // SUMMARY Expansion Section
                    Container(
                      decoration: BoxDecoration(
                        color: context.themeColors.card.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.themeColors.border.withOpacity(0.5),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(
                            'SUMMARY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: context.themeColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: context.themeColors.textMuted,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [
                            _buildSummaryCard(
                              'TOTAL TEKNISI',
                              total,
                              AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryCard(
                              'ASSIGNED',
                              assigned,
                              AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryCard(
                              'ON PROGRESS',
                              onProgress,
                              Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryCard(
                              'PENDING',
                              pending,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // TECHNICIANS Expansion Section
                    Container(
                      decoration: BoxDecoration(
                        color: context.themeColors.card.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.themeColors.border.withOpacity(0.5),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(
                            'TECHNICIANS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: context.themeColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: context.themeColors.textMuted,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [
                            // Search Bar
                            Container(
                              decoration: BoxDecoration(
                                color: context.themeColors.surface.withOpacity(
                                  0.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.themeColors.border.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(
                                  color: context.themeColors.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Cari teknisi...',
                                  hintStyle: TextStyle(
                                    color: context.themeColors.textMuted,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 18,
                                    color: context.themeColors.textMuted,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Filter Toggles
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilterButton(
                                    label: _selectedWorkzone ?? 'All Workzone',
                                    isActive: _selectedWorkzone != null,
                                    onTap: () {
                                      // TODO: Show workzone selector
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFilterButton(
                                    label: _selectedStatus ?? 'All Status',
                                    isActive: _selectedStatus != null,
                                    onTap: () {
                                      // TODO: Show status selector
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // List or Empty
                            if (filteredTechs.isEmpty)
                              _buildEmptyState()
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredTechs.length,
                                itemBuilder: (context, index) =>
                                    _buildTechCard(filteredTechs[index]),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.themeColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.themeColors.border.withOpacity(0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderLink(IconData icon, String label, String route) {
    return InkWell(
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 24,
        width: 1,
        color: context.themeColors.border.withOpacity(0.5),
      ),
    );
  }

  Widget _buildSummaryCard(String label, int value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.themeColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
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
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeColors.border),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.themeColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: context.themeColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      workzone,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.group_outlined,
              size: 80,
              color: context.themeColors.textMuted.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada teknisi di area ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.themeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada teknisi yang ditugaskan di area kerja Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.themeColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
