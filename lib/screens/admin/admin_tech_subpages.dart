import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/providers/api_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ATTENDANCE RECAP
// ─────────────────────────────────────────────────────────────────────────────

class AdminTechAttendanceScreen extends ConsumerStatefulWidget {
  const AdminTechAttendanceScreen({super.key});

  @override
  ConsumerState<AdminTechAttendanceScreen> createState() =>
      _AdminTechAttendanceScreenState();
}

class _AdminTechAttendanceScreenState
    extends ConsumerState<AdminTechAttendanceScreen> {
  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  late int _month;
  late int _year;
  bool _loading = true;
  int _totalWorkingDays = 0;
  List<_AttendanceSummary> _summaries = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        ApiConstants.attendance,
        queryParameters: {'month': _month, 'year': _year},
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final records = (data['data']?['records'] as List<dynamic>?) ?? [];
        final workingDays =
            data['data']?['summary']?['working_days'] as int? ?? 0;

        // Group by technician
        final map = <String, _AttendanceSummary>{};
        for (final record in records) {
          final key = record['technician_id'].toString();
          if (!map.containsKey(key)) {
            map[key] = _AttendanceSummary(
              name: record['technician_name']?.toString() ?? 'Unknown',
              nik: record['technician_nik']?.toString() ?? '',
              workzone: record['workzone_name']?.toString() ?? 'Unknown',
              workingDays: workingDays,
            );
          }
          final summary = map[key]!;
          if (record['status'] == 'PRESENT') {
            summary.present++;
          } else if (record['status'] == 'LATE') {
            summary.late++;
          }
        }

        final summaries = map.values.toList();
        for (final s in summaries) {
          final total = s.present + s.late;
          s.percentage = s.workingDays > 0
              ? (total / s.workingDays * 1000).round() / 10
              : 0;
        }
        summaries.sort((a, b) => b.percentage.compareTo(a.percentage));

        setState(() {
          _summaries = summaries;
          _totalWorkingDays = workingDays;
        });
      }
    } catch (e) {
      debugPrint('Attendance error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month < 1) {
        _month = 12;
        _year--;
      } else if (_month > 12) {
        _month = 1;
        _year++;
      }
    });
    _fetchData();
  }

  double get _avgPercentage {
    if (_summaries.isEmpty) return 0;
    return _summaries.map((s) => s.percentage).reduce((a, b) => a + b) /
        _summaries.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeColors.surface,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekap Absensi Teknisi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.themeColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lihat rekap absensi teknisi per bulan',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.themeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Month picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: context.themeColors.textPrimary,
                  onPressed: () => _changeMonth(-1),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_months[_month - 1]} $_year',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.themeColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: context.themeColors.textPrimary,
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Overview stats row
            Row(
              children: [
                Expanded(
                  child: _overviewCard(
                    Icons.calendar_today_outlined,
                    'Hari Kerja',
                    '$_totalWorkingDays',
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _overviewCard(
                    Icons.check_circle_outline_rounded,
                    'Rata-rata',
                    '${_avgPercentage.round()}%',
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _overviewCard(
                    Icons.people_alt_outlined,
                    'Teknisi',
                    '${_summaries.length}',
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table Section
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_summaries.isEmpty)
              _emptyState('Tidak ada data absensi')
            else
              _buildTable(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _overviewCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(context.themeColors.surface),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: [
            DataColumn(
              label: Text('Teknisi',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
            ),
            DataColumn(
              label: Text('Workzone',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
            ),
            DataColumn(
              label: Text('Hadir',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Terlambat',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Persentase',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
              numeric: true,
            ),
          ],
          rows: _summaries.map((s) {
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: context.themeColors.textPrimary)),
                      if (s.nik.isNotEmpty)
                        Text(s.nik,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.themeColors.textSecondary.withOpacity(0.7))),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.themeColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.workzone,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.themeColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text('${s.present}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF10B981))),
                ),
                DataCell(
                  Text('${s.late}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFFF59E0B))),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: context.themeColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (s.percentage / 100).clamp(0.0, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _percentageColor(s.percentage),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${s.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _percentageColor(s.percentage),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _percentageColor(double pct) {
    if (pct >= 90) return Colors.green;
    if (pct >= 70) return Colors.amber.shade700;
    return Colors.red;
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(
                  fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AttendanceSummary {
  final String name;
  final String nik;
  final String workzone;
  final int workingDays;
  int present = 0;
  int late = 0;
  double percentage = 0;

  _AttendanceSummary({
    required this.name,
    required this.nik,
    required this.workzone,
    required this.workingDays,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PERFORMANCE RECAP
// ─────────────────────────────────────────────────────────────────────────────

class AdminTechPerformanceScreen extends ConsumerStatefulWidget {
  const AdminTechPerformanceScreen({super.key});

  @override
  ConsumerState<AdminTechPerformanceScreen> createState() =>
      _AdminTechPerformanceScreenState();
}

class _AdminTechPerformanceScreenState
    extends ConsumerState<AdminTechPerformanceScreen> {
  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  late int _month;
  late int _year;
  bool _loading = true;
  String? _error;
  List<_PerfRow> _rows = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        ApiConstants.techniciansPerformance,
        queryParameters: {'month': _month, 'year': _year},
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final rawRows = (data['data']?['rows'] as List<dynamic>?) ?? [];
        _rows = rawRows.map((r) => _PerfRow(
          name: r['nama']?.toString() ?? 'N/A',
          nik: r['nik']?.toString() ?? '',
          workzone: r['workzone']?.toString() ?? '-',
          closedCount: r['closed_count'] as int? ?? 0,
          avgResolveHours: (r['avg_resolve_time_hours'] as num?)?.toDouble(),
        )).toList();
      } else {
        _error = data['message'] as String? ?? 'Gagal memuat data';
      }
    } catch (e) {
      _error = 'Gagal memuat data performa';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month < 1) {
        _month = 12;
        _year--;
      } else if (_month > 12) {
        _month = 1;
        _year++;
      }
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeColors.surface,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            Text(
              'Performa Teknisi (Bulanan)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.themeColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rekap pekerjaan teknisi per bulan',
              style: TextStyle(
                fontSize: 14,
                color: context.themeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Month picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: context.themeColors.textPrimary,
                  onPressed: () => _changeMonth(-1),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_months[_month - 1]} $_year',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.themeColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: context.themeColors.textPrimary,
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 14, color: Colors.redAccent),
                ),
              ),

            // Table
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rows.isEmpty && _error == null)
              _emptyState('Tidak ada data')
            else
              _buildTable(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(context.themeColors.surface),
          columnSpacing: 28,
          horizontalMargin: 20,
          columns: [
            DataColumn(
              label: Text('Nama',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
            ),
            DataColumn(
              label: Text('NIK',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
            ),
            DataColumn(
              label: Text('Workzone',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
            ),
            DataColumn(
              label: Text('Closed',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.themeColors.textSecondary)),
              numeric: true,
            ),
          ],
          rows: _rows.map((r) {
            return DataRow(
              cells: [
                DataCell(Text(r.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.themeColors.textPrimary))),
                DataCell(Text(r.nik.isEmpty ? '-' : r.nik,
                    style: TextStyle(
                        fontSize: 13, color: context.themeColors.textSecondary))),
                DataCell(Text(r.workzone,
                    style: TextStyle(
                        fontSize: 13, color: context.themeColors.textSecondary))),
                DataCell(Text('${r.closedCount}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: context.themeColors.textPrimary))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(
                  fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PerfRow {
  final String name;
  final String nik;
  final String workzone;
  final int closedCount;
  final double? avgResolveHours;

  _PerfRow({
    required this.name,
    required this.nik,
    required this.workzone,
    required this.closedCount,
    this.avgResolveHours,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MANHOURS PRODUCTIVITY
// ─────────────────────────────────────────────────────────────────────────────

class AdminTechManhoursScreen extends ConsumerStatefulWidget {
  const AdminTechManhoursScreen({super.key});

  @override
  ConsumerState<AdminTechManhoursScreen> createState() =>
      _AdminTechManhoursScreenState();
}

class _AdminTechManhoursScreenState
    extends ConsumerState<AdminTechManhoursScreen> {
  bool _loading = false;
  String? _error;

  // Filter state
  late String _dateFrom;
  late String _dateTo;
  String _sto = '';
  String _nameSearch = '';

  // Data
  List<_ManhoursRow> _rows = [];
  List<_ManhourConfig> _configs = [];
  List<String> _stoOptions = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    _dateFrom = DateFormat('yyyy-MM-dd').format(firstDay);
    _dateTo = DateFormat('yyyy-MM-dd').format(now);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final params = <String, dynamic>{
        'date_from': _dateFrom,
        'date_to': _dateTo,
      };
      if (_sto.isNotEmpty) params['sto'] = _sto;
      if (_nameSearch.isNotEmpty) params['name'] = _nameSearch;

      final response = await apiClient.dio.get(
        ApiConstants.techniciansManhours,
        queryParameters: params,
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final rawRows = (data['rows'] as List<dynamic>?) ?? [];
        _rows = rawRows.map((r) {
          final cats = (r['categories'] as Map<String, dynamic>?) ?? {};
          return _ManhoursRow(
            name: r['nama']?.toString() ?? 'N/A',
            nik: r['nik']?.toString() ?? '',
            sto: r['sto']?.toString() ?? '-',
            categories: cats.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
            totalTickets: r['total_tickets'] as int? ?? 0,
            realisasi: (r['realisasi'] as num?)?.toDouble() ?? 0,
            jamEfektif: (r['jam_efektif'] as num?)?.toDouble() ?? 0,
            produktivitas: (r['produktivitas'] as num?)?.toDouble() ?? 0,
            target: (r['target'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        final rawConfigs = (data['configs'] as List<dynamic>?) ?? [];
        _configs = rawConfigs.map((c) => _ManhourConfig(
          jenisKey: c['jenis_key']?.toString() ?? '',
          label: c['label']?.toString() ?? '',
          sortOrder: c['sort_order'] as int? ?? 0,
        )).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final rawSto = (data['stoOptions'] as List<dynamic>?) ?? [];
        _stoOptions = rawSto.map((o) => o['value']?.toString() ?? '').toList();
      } else {
        _error = data['message'] as String? ?? 'Gagal mengambil data';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan saat mengambil data';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Summary stats
  int get _totalTeknisi => _rows.length;
  int get _totalTiket => _rows.fold(0, (s, r) => s + r.totalTickets);
  double get _totalRealisasi =>
      (_rows.fold(0.0, (s, r) => s + r.realisasi) * 100).round() / 100;
  double get _avgProduktivitas => _rows.isEmpty
      ? 0
      : ((_rows.fold(0.0, (s, r) => s + r.produktivitas) / _rows.length) * 100)
              .round() /
          100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeColors.surface,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            Text(
              'Produktivitas ManHours Teknisi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.themeColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitoring produktivitas berdasarkan realisasi manhours per kategori tiket',
              style: TextStyle(
                fontSize: 14,
                color: context.themeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Filter section (White Card)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.themeColors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _dateField('Dari', _dateFrom, (v) {
                          setState(() => _dateFrom = v);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _dateField('Sampai', _dateTo, (v) {
                          setState(() => _dateTo = v);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStoDropdown()),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NAME',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: context.themeColors.textSecondary,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: context.themeColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Nama Teknisi',
                                  hintStyle: TextStyle(
                                      fontSize: 14, color: context.themeColors.textMuted),
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  suffixIcon: Icon(Icons.search,
                                      size: 18, color: context.themeColors.textMuted),
                                  suffixIconConstraints: const BoxConstraints(),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                style: TextStyle(
                                    fontSize: 14, color: context.themeColors.textPrimary),
                                onChanged: (v) => _nameSearch = v,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _fetchData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _loading ? 'Memproses...' : 'Tampilkan',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Summary stats cards (Grid)
            if (_rows.isNotEmpty) ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _summaryCard(Icons.people_alt_rounded, 'Total Teknisi',
                      '$_totalTeknisi', const Color(0xFF3B82F6)),
                  _summaryCard(Icons.emoji_events_rounded, 'Total Tiket Closed',
                      '$_totalTiket', const Color(0xFF8B5CF6)),
                  _summaryCard(Icons.trending_up_rounded, 'Total Realisasi MH',
                      '$_totalRealisasi', const Color(0xFF10B981)),
                  _summaryCard(Icons.timer_rounded, 'Avg Produktivitas',
                      _avgProduktivitas.toStringAsFixed(2), const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 28),
            ],

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 14, color: Colors.redAccent),
                ),
              ),

            // Table
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rows.isEmpty && _error == null)
              _emptyState()
            else
              _buildTable(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.themeColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.parse(value),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onChanged(DateFormat('yyyy-MM-dd').format(picked));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: context.themeColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style:
                        TextStyle(fontSize: 14, color: context.themeColors.textPrimary),
                  ),
                ),
                Icon(Icons.calendar_month_rounded,
                    size: 18, color: context.themeColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.themeColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.themeColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: context.themeColors.card,
              value: _sto.isEmpty ? null : _sto,
              hint: Text('Semua STO',
                  style: TextStyle(fontSize: 14, color: context.themeColors.textMuted)),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: context.themeColors.textMuted),
              style: TextStyle(fontSize: 14, color: context.themeColors.textPrimary),
              items: [
                const DropdownMenuItem(value: '', child: Text('Semua STO')),
                ..._stoOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (v) => setState(() => _sto = v ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.themeColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF14B8A6)),
          columnSpacing: 24,
          horizontalMargin: 20,
          headingTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5),
          columns: [
            const DataColumn(label: Text('NO')),
            const DataColumn(label: Text('NAMA')),
            const DataColumn(label: Text('STO')),
            ..._configs.map((c) => DataColumn(label: Text(c.label.toUpperCase()))),
            const DataColumn(label: Text('TOTAL'), numeric: true),
            const DataColumn(label: Text('PRODUKTIVITAS'), numeric: true),
            const DataColumn(label: Text('TARGET'), numeric: true),
            const DataColumn(label: Text('REALISASI'), numeric: true),
            const DataColumn(label: Text('JAM EFEKTIF'), numeric: true),
          ],
          rows: _rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            return DataRow(
              cells: [
                DataCell(Text('${idx + 1}',
                    style: TextStyle(
                        fontSize: 13, color: context.themeColors.textSecondary))),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: context.themeColors.textPrimary)),
                      if (r.nik.isNotEmpty)
                        Text(r.nik,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.themeColors.textSecondary.withOpacity(0.7))),
                    ],
                  ),
                ),
                DataCell(Text(r.sto,
                    style: TextStyle(
                        fontSize: 13, color: context.themeColors.textPrimary))),
                ..._configs.map((c) => DataCell(Text(
                    '${r.categories[c.jenisKey] ?? 0}',
                    style: TextStyle(
                        fontSize: 13, color: context.themeColors.textPrimary)))),
                DataCell(Text('${r.totalTickets}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: context.themeColors.textPrimary))),
                DataCell(_produktivitasBadge(r.produktivitas)),
                DataCell(Text('${r.target}',
                    style: TextStyle(
                        fontSize: 13, color: context.themeColors.textPrimary))),
                DataCell(Text('${r.realisasi}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF0D9488)))),
                DataCell(Text('${r.jamEfektif}',
                    style: TextStyle(
                        fontSize: 13, color: context.themeColors.textPrimary))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _produktivitasBadge(double value) {
    Color bg, fg;
    if (value >= 20) {
      bg = Colors.green.shade100;
      fg = Colors.green.shade700;
    } else if (value >= 10) {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade700;
    } else {
      bg = Colors.red.shade100;
      fg = Colors.red.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(value.toStringAsFixed(2),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.trending_up, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Tidak ada data',
              style: TextStyle(
                  fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Belum ada data manhours untuk periode yang dipilih',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ManhoursRow {
  final String name;
  final String nik;
  final String sto;
  final Map<String, int> categories;
  final int totalTickets;
  final double realisasi;
  final double jamEfektif;
  final double produktivitas;
  final int target;

  _ManhoursRow({
    required this.name,
    required this.nik,
    required this.sto,
    required this.categories,
    required this.totalTickets,
    required this.realisasi,
    required this.jamEfektif,
    required this.produktivitas,
    required this.target,
  });
}

class _ManhourConfig {
  final String jenisKey;
  final String label;
  final int sortOrder;

  _ManhourConfig({
    required this.jenisKey,
    required this.label,
    required this.sortOrder,
  });
}
