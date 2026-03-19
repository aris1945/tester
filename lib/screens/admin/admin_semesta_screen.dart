import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/providers/theme_provider.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/data/models/ticket.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/widgets/stat_card.dart';
import 'package:dompis_app/widgets/ticket_card.dart';

class AdminSemestaScreen extends ConsumerStatefulWidget {
  const AdminSemestaScreen({super.key});

  @override
  ConsumerState<AdminSemestaScreen> createState() => _AdminSemestaScreenState();
}

class _AdminSemestaScreenState extends ConsumerState<AdminSemestaScreen> {
  bool _loading = true;
  List<Ticket> _allTickets = [];
  List<Ticket> _filteredTickets = [];
  List<Ticket> _tickets = [];

  // Stats
  int _total = 0, _open = 0, _inProgress = 0, _closed = 0;

  // Filters
  String _deptFilter = 'all';
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _ctypeFilter = 'all';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  static const _deptOptions = [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'b2b', 'label': 'B2B'},
    {'key': 'b2c', 'label': 'B2C'},
  ];

  static const _typeOptions = [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'reguler', 'label': 'Reguler'},
    {'key': 'sqm', 'label': 'SQM'},
    {'key': 'unspec', 'label': 'Unspec'},
  ];

  static const _statusOptions = [
    {'key': 'all', 'label': 'Semua Status'},
    {'key': 'OPEN', 'label': 'Open'},
    {'key': 'ASSIGNED', 'label': 'Assigned'},
    {'key': 'ON_PROGRESS', 'label': 'On Progress'},
    {'key': 'PENDING', 'label': 'Pending'},
    {'key': 'ESCALATED', 'label': 'Escalated'},
    {'key': 'CLOSE', 'label': 'Closed'},
  ];

  static const _ctypeOptions = [
    {'key': 'all', 'label': 'Semua Customer'},
    {'key': 'REGULER', 'label': 'Reguler'},
    {'key': 'HVC_GOLD', 'label': 'HVC Gold'},
    {'key': 'HVC_PLATINUM', 'label': 'HVC Platinum'},
    {'key': 'HVC_DIAMOND', 'label': 'HVC Diamond'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(ticketApiProvider);

      // Fetch all tickets dynamically
      final data = await api.getDailyTickets();

      if (data['success'] == true) {
        final list = data['data']?['data'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            [];
        _allTickets =
            list.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
      }

      _applyFilters();
    } catch (e) {
      debugPrint('Semesta load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isB2C(Ticket t) {
    final jenis = (t.jenisTiket ?? '').toLowerCase();
    return jenis.contains('reguler') ||
        (jenis.contains('sqm') && !jenis.contains('ccan')) ||
        jenis.contains('hvc') ||
        jenis.isEmpty;
  }

  bool _isB2B(Ticket t) {
    final jenis = (t.jenisTiket ?? '').toLowerCase();
    return jenis.contains('ccan') ||
        jenis.contains('indibiz') ||
        jenis.contains('datin') ||
        jenis.contains('reseller') ||
        jenis.contains('wifi');
  }

  void _applyFilters() {
    _filteredTickets = _allTickets.where((t) {
      // Dept filter
      if (_deptFilter == 'b2b' && !_isB2B(t)) return false;
      if (_deptFilter == 'b2c' && !_isB2C(t)) return false;

      // Type filter
      if (_typeFilter != 'all') {
        final rawJenis = (t.jenisTiket ?? '').toLowerCase();
        if (_typeFilter == 'reguler' && !rawJenis.contains('reguler')) return false;
        if (_typeFilter == 'sqm' && (!rawJenis.contains('sqm') || rawJenis.contains('ccan'))) return false;
        if (_typeFilter == 'unspec' && (rawJenis.contains('reguler') || rawJenis.contains('sqm'))) return false;
      }

      // Status filter
      if (_statusFilter != 'all') {
        final s = (t.statusUpdate ?? '').toLowerCase();
        if (_statusFilter == 'OPEN' && s.isNotEmpty && s != 'open') return false;
        if (_statusFilter == 'ASSIGNED' && s != 'assigned') return false;
        if (_statusFilter == 'ON_PROGRESS' && s != 'on_progress') return false;
        if (_statusFilter == 'PENDING' && s != 'pending') return false;
        if (_statusFilter == 'ESCALATED' && s != 'escalated') return false;
        if (_statusFilter == 'CLOSE' && s != 'close' && s != 'closed') return false;
      }

      // Customer type filter
      if (_ctypeFilter != 'all') {
        final ctype = (t.customerType ?? '').toUpperCase();
        if (_ctypeFilter == 'REGULER' && ctype != 'REGULER') return false;
        if (_ctypeFilter == 'HVC_GOLD' && ctype != 'HVC GOLD' && ctype != 'HVC_GOLD') return false;
        if (_ctypeFilter == 'HVC_PLATINUM' && ctype != 'HVC PLATINUM' && ctype != 'HVC_PLATINUM') return false;
        if (_ctypeFilter == 'HVC_DIAMOND' && ctype != 'HVC DIAMOND' && ctype != 'HVC_DIAMOND') return false;
      }

      return true;
    }).toList();

    _totalCount = _filteredTickets.length;
    _totalPages = (_totalCount / 20).ceil();
    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) _currentPage = 1;

    _total = _totalCount;
    _open = _filteredTickets.where((t) {
      final s = (t.statusUpdate ?? '').toLowerCase();
      return s.isEmpty || s == 'open';
    }).length;
    _inProgress = _filteredTickets.where((t) {
      final s = (t.statusUpdate ?? '').toLowerCase();
      return s == 'assigned' || s == 'on_progress' || s == 'pending';
    }).length;
    _closed = _filteredTickets.where((t) {
      final s = (t.statusUpdate ?? '').toLowerCase();
      return s == 'close' || s == 'closed';
    }).length;

    // Pagination slice
    final startIndex = (_currentPage - 1) * 20;
    int endIndex = startIndex + 20;
    if (endIndex > _totalCount) endIndex = _totalCount;
    _tickets = _filteredTickets.sublist(startIndex, endIndex);
  }

  void _onFilterChanged() {
    setState(() {
      _currentPage = 1;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dompis Analytics',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: context.themeColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Unified view of tickets, workload, and trend.',
                              style: TextStyle(
                                  fontSize: 13, color: context.themeColors.textMuted)),
                        ],
                      ),
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
                ],
              ),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.themeColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.themeColors.border),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDropdown('Dept', _deptFilter, _deptOptions,
                        (v) => setState(() { _deptFilter = v; _onFilterChanged(); })),
                    _buildDropdown('Jenis', _typeFilter, _typeOptions,
                        (v) => setState(() { _typeFilter = v; _onFilterChanged(); })),
                    _buildDropdown('Status', _statusFilter, _statusOptions,
                        (v) => setState(() { _statusFilter = v; _onFilterChanged(); })),
                    _buildDropdown('Customer', _ctypeFilter, _ctypeOptions,
                        (v) => setState(() { _ctypeFilter = v; _onFilterChanged(); })),
                    if (_deptFilter != 'all' ||
                        _typeFilter != 'all' ||
                        _statusFilter != 'all' ||
                        _ctypeFilter != 'all')
                      InkWell(
                        onTap: () {
                          setState(() {
                            _deptFilter = 'all';
                            _typeFilter = 'all';
                            _statusFilter = 'all';
                            _ctypeFilter = 'all';
                          });
                          _onFilterChanged();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 14, color: Colors.red.shade400),
                              const SizedBox(width: 4),
                              Text('Reset',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade400)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Stats cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GridView.count(
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
                      label: 'In Progress',
                      value: _inProgress,
                      color: AppColors.assigned,
                      loading: _loading),
                  StatCard(
                      label: 'Closed',
                      value: _closed,
                      color: AppColors.closed,
                      loading: _loading),
                ],
              ),
            ),
          ),

          // Ticket list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Ticket List',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.themeColors.textPrimary)),
                  ),
                  Text('$_totalCount tiket',
                      style: TextStyle(
                          fontSize: 12, color: context.themeColors.textMuted)),
                ],
              ),
            ),
          ),

          // Ticket list
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_tickets.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 48, color: context.themeColors.textMuted),
                    const SizedBox(height: 12),
                    Text('Tidak ada tiket ditemukan',
                        style: TextStyle(
                            fontSize: 16, color: context.themeColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TicketCard(ticket: _tickets[index]),
                  ),
                  childCount: _tickets.length,
                ),
              ),
            ),

          // Pagination
          if (!_loading && _totalPages > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                                _applyFilters();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < _totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                                _applyFilters();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value,
      List<Map<String, String>> options, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.themeColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.themeColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: (v) => onChanged(v!),
          dropdownColor: context.themeColors.card,
          items: options
              .map((opt) => DropdownMenuItem(
                    value: opt['key']!,
                    child: Text(opt['label']!,
                        style: TextStyle(fontSize: 12, color: context.themeColors.textPrimary)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
