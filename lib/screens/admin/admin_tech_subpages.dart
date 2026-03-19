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
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          const Text('Rekap Absensi Teknisi',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Lihat rekap absensi teknisi per bulan',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Month picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 180),
                alignment: Alignment.center,
                child: Text(
                  '${_months[_month - 1]} $_year',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overview stats row
          Row(
            children: [
              Expanded(
                  child: _overviewCard(
                      Icons.calendar_today, 'Hari Kerja', '$_totalWorkingDays',
                      Colors.blue)),
              const SizedBox(width: 8),
              Expanded(
                  child: _overviewCard(
                      Icons.check_circle_outline, 'Rata-rata',
                      '${_avgPercentage.round()}%', Colors.green)),
              const SizedBox(width: 8),
              Expanded(
                  child: _overviewCard(
                      Icons.people_outline, 'Teknisi', '${_summaries.length}',
                      Colors.orange)),
            ],
          ),
          const SizedBox(height: 20),

          // Table
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_summaries.isEmpty)
            _emptyState('Tidak ada data absensi')
          else
            _buildTable(),
        ],
      ),
    );
  }

  Widget _overviewCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              AppColors.surfaceLight),
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Teknisi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
            DataColumn(label: Text('Workzone',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
            DataColumn(label: Text('Hadir',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                numeric: true),
            DataColumn(label: Text('Terlambat',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                numeric: true),
            DataColumn(label: Text('Persentase',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                numeric: true),
          ],
          rows: _summaries.map((s) => DataRow(cells: [
            DataCell(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.name, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
                if (s.nik.isNotEmpty)
                  Text(s.nik, style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              ],
            )),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s.workzone,
                  style: const TextStyle(fontSize: 11)),
            )),
            DataCell(Text('${s.present}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.green))),
            DataCell(Text('${s.late}',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700))),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s.percentage / 100,
                      backgroundColor: AppColors.borderLight,
                      color: _percentageColor(s.percentage),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${s.percentage}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _percentageColor(s.percentage))),
              ],
            )),
          ])).toList(),
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
              style: const TextStyle(
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
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          const Text('Performa Teknisi (Bulanan)',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Rekap pekerjaan teknisi per bulan',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Month picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 180),
                alignment: Alignment.center,
                child: Text(
                  '${_months[_month - 1]} $_year',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_error!,
                  style: TextStyle(
                      fontSize: 13, color: Colors.red.shade600)),
            ),

          // Table
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_rows.isEmpty && _error == null)
            _emptyState('Tidak ada data')
          else
            _buildTable(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              AppColors.surfaceLight),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Nama',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
            DataColumn(label: Text('NIK',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
            DataColumn(label: Text('Workzone',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
            DataColumn(label: Text('Closed',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                numeric: true),
            DataColumn(label: Text('Avg Resolve (h)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                numeric: true),
          ],
          rows: _rows.map((r) => DataRow(cells: [
            DataCell(Text(r.name,
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(r.nik.isEmpty ? '-' : r.nik,
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(r.workzone,
                style: const TextStyle(fontSize: 12))),
            DataCell(Text('${r.closedCount}',
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(
              r.avgResolveHours != null
                  ? r.avgResolveHours!.toStringAsFixed(1)
                  : '-',
              style: const TextStyle(fontSize: 12),
            )),
          ])).toList(),
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
              style: const TextStyle(
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
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          const Text('Produktivitas ManHours Teknisi',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text(
            'Monitoring produktivitas berdasarkan realisasi manhours per kategori tiket',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Filter section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _dateField('Dari', _dateFrom, (v) {
                      setState(() => _dateFrom = v);
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _dateField('Sampai', _dateTo, (v) {
                      setState(() => _dateTo = v);
                    })),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStoDropdown(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Nama Teknisi',
                          labelStyle: const TextStyle(fontSize: 12),
                          hintText: 'Cari nama...',
                          hintStyle: const TextStyle(fontSize: 12),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          suffixIcon: const Icon(Icons.search, size: 18),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (v) => _nameSearch = v,
                        onSubmitted: (_) => _fetchData(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _fetchData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_loading ? 'Loading...' : 'Tampilkan',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary stats
          if (_rows.isNotEmpty) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _summaryCard(Icons.people, 'Total Teknisi',
                    '$_totalTeknisi', Colors.blue),
                _summaryCard(Icons.emoji_events, 'Total Tiket Closed',
                    '$_totalTiket', Colors.purple),
                _summaryCard(Icons.trending_up, 'Total Realisasi MH',
                    '$_totalRealisasi', Colors.green),
                _summaryCard(Icons.timer, 'Avg Produktivitas',
                    _avgProduktivitas.toStringAsFixed(2), Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Text(_error!,
                      style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _fetchData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),

          // Table
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_rows.isEmpty && _error == null)
            _emptyState()
          else
            _buildTable(),
        ],
      ),
    );
  }

  Widget _dateField(String label, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1)),
        const SizedBox(height: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: const TextStyle(fontSize: 13)),
                ),
                const Icon(Icons.calendar_today, size: 14,
                    color: AppColors.textMuted),
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
        const Text('STO',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: _sto.isEmpty ? null : _sto,
            hint: const Text('Semua STO',
                style: TextStyle(fontSize: 13)),
            isExpanded: true,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: [
              const DropdownMenuItem(value: '', child: Text('Semua STO')),
              ..._stoOptions.map((s) =>
                  DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: (v) => setState(() => _sto = v ?? ''),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              const Color(0xFF14B8A6)),
          headingTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
          columnSpacing: 14,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 56,
          columns: [
            const DataColumn(label: Text('No')),
            const DataColumn(label: Text('Nama')),
            const DataColumn(label: Text('STO')),
            ..._configs.map((c) => DataColumn(
                label: Text(c.label), numeric: true)),
            const DataColumn(label: Text('Total'), numeric: true),
            const DataColumn(label: Text('Produktivitas'), numeric: true),
            const DataColumn(label: Text('Target'), numeric: true),
            const DataColumn(label: Text('Realisasi'), numeric: true),
            const DataColumn(label: Text('Jam Efektif'), numeric: true),
          ],
          rows: _rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            return DataRow(cells: [
              DataCell(Text('${idx + 1}')),
              DataCell(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.name, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
                  if (r.nik.isNotEmpty)
                    Text(r.nik, style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
                ],
              )),
              DataCell(Text(r.sto, style: const TextStyle(fontSize: 12))),
              ..._configs.map((c) => DataCell(
                Text('${r.categories[c.jenisKey] ?? 0}',
                    style: const TextStyle(fontSize: 12)),
              )),
              DataCell(Text('${r.totalTickets}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12))),
              DataCell(_produktivitasBadge(r.produktivitas)),
              DataCell(Text('${r.target}',
                  style: const TextStyle(fontSize: 12))),
              DataCell(Text('${r.realisasi}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12))),
              DataCell(Text('${r.jamEfektif}',
                  style: const TextStyle(fontSize: 12))),
            ]);
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
