import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/data/models/ticket.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/widgets/ticket_card.dart';
import 'package:dompis_app/widgets/assign_technician_modal.dart';
import 'package:dompis_app/providers/theme_provider.dart';

// --- ENUMS for filters ---
enum TicketType { all, reguler, sqm, hvc, unspec }
enum TicketTypeB2B { all, sqmCcan, indibiz, datin, reseller, wifiId }
enum StatusUpdate { all, open, assigned, onProgress, pending, close }
enum FlaggingManja { all, p1, pPlus }
enum B2CTab { all, reguler, gold, platinum, diamond }

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  bool _loading = true;
  List<Ticket> _tickets = [];
  List<Ticket> _filteredTickets = [];

  // Global Filter State
  String _searchQuery = '';
  String _selectedWorkzone = 'All Workzone';
  List<String> _availableWorkzones = ['All Workzone'];

  // Stats
  int _total = 0, _unassigned = 0, _assigned = 0, _closed = 0;
  int _b2cCount = 0, _b2bCount = 0;
  List<_ServiceArea> _serviceAreas = [];

  // Accordion state
  bool _serviceAreasExpanded = false;
  bool _b2bExpanded = true;
  bool _b2cExpanded = true;

  // B2C Filter State
  B2CTab _b2cActiveTab = B2CTab.all;
  TicketType _b2cTicketType = TicketType.all;
  StatusUpdate _b2cStatusUpdate = StatusUpdate.all;
  FlaggingManja _b2cFlagging = FlaggingManja.all;

  // B2B Filter State
  TicketTypeB2B _b2bTicketType = TicketTypeB2B.all;
  StatusUpdate _b2bStatusUpdate = StatusUpdate.all;
  FlaggingManja _b2bFlagging = FlaggingManja.all;

  // Pagination (simple client side)
  int _b2cPage = 1;
  int _b2bPage = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(ticketApiProvider);
      final data = await api.getDailyTickets();

      if (data['success'] == true) {
        final list = data['data']?['data'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            [];
        _tickets =
            list.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();

        // Extract Workzones
        final w = <String>{};
        for (var t in _tickets) {
          if (t.workzone != null && t.workzone!.trim().isNotEmpty) w.add(t.workzone!.trim());
        }
        final sortedW = w.toList()..sort();
        _availableWorkzones = ['All Workzone', ...sortedW];
        if (!_availableWorkzones.contains(_selectedWorkzone)) {
          _selectedWorkzone = 'All Workzone';
        }

        _applyGlobalFilters();
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyGlobalFilters() {
    _filteredTickets = _tickets.where((t) {
      if (_selectedWorkzone != 'All Workzone' && t.workzone != _selectedWorkzone) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = (t.ticket).toLowerCase().contains(q);
        final matchName = (t.contactName ?? '').toLowerCase().contains(q);
        return matchCode || matchName;
      }
      return true;
    }).toList();

    _computeStats();
    _computeServiceAreas();
  }

  void _computeStats() {
    _total = _filteredTickets.length;
    _unassigned = _filteredTickets.where((t) {
      final s = (t.statusUpdate ?? '').toLowerCase();
      return s.isEmpty || s == 'open';
    }).length;
    _assigned = _filteredTickets.where((t) {
      final s = (t.statusUpdate ?? '').toLowerCase();
      return s == 'assigned' || s == 'on_progress' || s == 'pending';
    }).length;
    _closed = _filteredTickets.where((t) {
      final s = (t.statusUpdate ?? '').toLowerCase();
      return s == 'close' || s == 'closed';
    }).length;

    _b2cCount = _filteredTickets.where((t) => _isB2C(t)).length;
    _b2bCount = _filteredTickets.where((t) => _isB2B(t)).length;
  }

  void _computeServiceAreas() {
    final wzMap = <String, List<Ticket>>{};
    for (final t in _filteredTickets) {
      final wz = (t.workzone ?? '').trim();
      if (wz.isEmpty) continue;
      wzMap.putIfAbsent(wz, () => []).add(t);
    }

    _serviceAreas = wzMap.entries.map((entry) {
      final name = entry.key;
      final arr = entry.value;
      return _ServiceArea(
        name: name,
        total: arr.length,
        unassigned: arr.where((t) {
          final s = (t.statusUpdate ?? '').toLowerCase();
          return s.isEmpty || s == 'open';
        }).length,
        assigned: arr.where((t) {
          final s = (t.statusUpdate ?? '').toLowerCase();
          return s == 'assigned' || s == 'on_progress' || s == 'pending';
        }).length,
        closed: arr.where((t) {
          final s = (t.statusUpdate ?? '').toLowerCase();
          return s == 'close' || s == 'closed';
        }).length,
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    if (_serviceAreas.length > 5) {
      _serviceAreas = _serviceAreas.sublist(0, 5);
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

  String _normalizeJenisB2C(Ticket t) {
    final raw = (t.jenisTiket ?? '').toLowerCase();
    if (raw.contains('reguler')) return 'reguler';
    if (raw.contains('sqm')) return 'sqm';
    return 'unspec';
  }

  String _normalizeJenisB2B(Ticket t) {
    final raw = (t.jenisTiket ?? '').toLowerCase();
    if (raw.contains('ccan')) return 'sqm-ccan';
    if (raw.contains('indibiz')) return 'indibiz';
    if (raw.contains('datin')) return 'datin';
    if (raw.contains('reseller')) return 'reseller';
    if (raw.contains('wifi')) return 'wifi-id';
    return 'other';
  }

  bool _matchStatus(Ticket t, StatusUpdate filter) {
    if (filter == StatusUpdate.all) return true;
    final s = (t.statusUpdate ?? '').toLowerCase();
    switch (filter) {
      case StatusUpdate.open: return s.isEmpty || s == 'open';
      case StatusUpdate.assigned: return s == 'assigned';
      case StatusUpdate.onProgress: return s == 'on_progress';
      case StatusUpdate.pending: return s == 'pending';
      case StatusUpdate.close: return s == 'close' || s == 'closed';
      default: return true;
    }
  }

  bool _matchFlagging(Ticket t, FlaggingManja filter) {
    if (filter == FlaggingManja.all) return true;
    final f = (t.flaggingManja ?? '').toUpperCase();
    if (filter == FlaggingManja.p1 && f == 'P1') return true;
    if (filter == FlaggingManja.pPlus && f == 'P+') return true;
    return false;
  }

  // Helper to extract stats object from ticket list
  _CatStats _getStats(List<Ticket> list) {
    int total = list.length;
    int open = 0, assigned = 0, close = 0;
    int reg = 0, sqm = 0, unsc = 0;
    int ffg = 0, p1 = 0, pp = 0;

    for (final t in list) {
      final s = (t.statusUpdate ?? '').toLowerCase();
      if (s == 'close' || s == 'closed') close++;
      else if (s == 'assigned' || s == 'on_progress' || s == 'pending') assigned++;
      else open++;

      final jt = _normalizeJenisB2C(t);
      if (jt == 'reguler') reg++;
      else if (jt == 'sqm') sqm++;
      else unsc++;

      if (t.guaranteeStatus?.toLowerCase() == 'guarantee') ffg++;
      final flag = (t.flaggingManja ?? '').toUpperCase();
      if (flag == 'P1') p1++;
      if (flag == 'P+') pp++;
    }

    return _CatStats(
      total: total, open: open, assigned: assigned, close: close,
      regulerCount: reg, sqmCount: sqm, unspecCount: unsc,
      ffgCount: ffg, p1Count: p1, pPlusCount: pp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // ─── GLOBAL FILTERS ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: context.themeColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: context.themeColors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: context.themeColors.card,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.themeColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.themeColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                              _applyGlobalFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: context.themeColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.themeColors.border),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final themeMode = ref.watch(themeProvider);
                            return IconButton(
                              icon: Icon(
                                themeMode == ThemeMode.dark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                                color: themeMode == ThemeMode.dark ? Colors.amber : AppColors.textPrimary,
                              ),
                              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.themeColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.themeColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWorkzone,
                        isExpanded: true,
                        dropdownColor: context.themeColors.card,
                        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: context.themeColors.textMuted),
                        style: TextStyle(fontSize: 13, color: context.themeColors.textPrimary),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedWorkzone = newValue;
                              _applyGlobalFilters();
                            });
                          }
                        },
                        items: _availableWorkzones.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── HEADER + STATS ─────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: context.themeColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.themeColors.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Text(
                      'SEMANGAT PAGI PAGI PAGI ...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: context.themeColors.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        _StatCard(label: 'TOTAL', value: _total, accentColor: AppColors.primary, gradient: const [Color(0xFF3B82F6), Color(0xFF8B5CF6)], subInfo: 'B2C: $_b2cCount · B2B: $_b2bCount', loading: _loading),
                        _StatCard(label: 'UNASSIGNED', value: _unassigned, accentColor: const Color(0xFFEF4444), gradient: const [Color(0xFFEF4444), Color(0xFFEF4444)], subInfo: _total > 0 ? '${(_unassigned / _total * 100).toStringAsFixed(1)}%' : null, loading: _loading),
                        _StatCard(label: 'ASSIGNED', value: _assigned, accentColor: const Color(0xFFF59E0B), gradient: const [Color(0xFFF59E0B), Color(0xFFF59E0B)], loading: _loading),
                        _StatCard(label: 'CLOSE', value: _closed, accentColor: const Color(0xFF10B981), gradient: const [Color(0xFF10B981), Color(0xFF10B981)], loading: _loading),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── SERVICE AREAS ──────────────────────────────
          SliverToBoxAdapter(
            child: _AccordionSection(
              title: 'SERVICE AREAS',
              expanded: _serviceAreasExpanded,
              onToggle: () => setState(() => _serviceAreasExpanded = !_serviceAreasExpanded),
              child: _buildServiceAreasTable(),
            ),
          ),

          // ─── B2B CARDS ──────────────────────────────────
          SliverToBoxAdapter(
            child: _AccordionSection(
              title: 'B2B CARDS',
              expanded: _b2bExpanded,
              onToggle: () => setState(() => _b2bExpanded = !_b2bExpanded),
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                  : _buildB2BSection(),
            ),
          ),

          // ─── B2C CARDS ──────────────────────────────────
          SliverToBoxAdapter(
            child: _AccordionSection(
              title: 'B2C CARDS',
              expanded: _b2cExpanded,
              onToggle: () => setState(() => _b2cExpanded = !_b2cExpanded),
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                  : _buildB2CSection(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // --- B2C SECTION ---
  Widget _buildB2CSection() {
    final allB2C = _filteredTickets.where((t) => _isB2C(t)).toList();
    
    // Tab filtering (All vs Reguler/Gold/Plat/Diamond)
    final b2cTabMap = {
      B2CTab.all: allB2C,
      B2CTab.reguler: allB2C.where((t) => (t.customerType ?? '').toUpperCase() == 'REGULER').toList(),
      B2CTab.gold: allB2C.where((t) => (t.customerType ?? '').toUpperCase() == 'HVC_GOLD').toList(),
      B2CTab.platinum: allB2C.where((t) => (t.customerType ?? '').toUpperCase() == 'HVC_PLATINUM').toList(),
      B2CTab.diamond: allB2C.where((t) => (t.customerType ?? '').toUpperCase() == 'HVC_DIAMOND').toList(),
    };

    final filteredByTab = b2cTabMap[_b2cActiveTab]!;
    final statsForTab = _getStats(filteredByTab);
    final totalAllCount = allB2C.length;

    // Table display filtering
    final tableTickets = filteredByTab.where((t) {
      if (_b2cTicketType != TicketType.all) {
        final j = _normalizeJenisB2C(t);
        if (_b2cTicketType == TicketType.reguler && j != 'reguler') return false;
        if (_b2cTicketType == TicketType.sqm && j != 'sqm') return false;
        if (_b2cTicketType == TicketType.unspec && j != 'unspec') return false;
        // hvc pseudo-type not explicitly tracked here easily without breaking logic
      }
      if (!_matchStatus(t, _b2cStatusUpdate)) return false;
      if (!_matchFlagging(t, _b2cFlagging)) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // B2C Overview Header
        Row(
          children: [
            Container(
              height: 36, width: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('👥', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('B2C Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.themeColors.textPrimary)),
                Text('Customer Type Overview', style: TextStyle(fontSize: 10, color: context.themeColors.textSecondary)),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),

        // Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: context.themeColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.themeColors.border)),
            child: Row(
              children: B2CTab.values.map((tab) {
                final isActive = _b2cActiveTab == tab;
                final count = b2cTabMap[tab]!.length;
                final labels = {B2CTab.all: 'All', B2CTab.reguler: '👤 Reguler', B2CTab.gold: '⭐ Gold', B2CTab.platinum: '💎 Platinum', B2CTab.diamond: '🔷 Diamond'};
                return GestureDetector(
                  onTap: () => setState(() => _b2cActiveTab = tab),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? context.themeColors.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(labels[tab]!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? context.themeColors.textPrimary : context.themeColors.textSecondary)),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: isActive ? AppColors.primary : context.themeColors.textMuted, borderRadius: BorderRadius.circular(10)),
                          child: Text('$count', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // B2C Summary Card
        _buildB2CSummaryCard(statsForTab),
        const SizedBox(height: 16),

        // Type Cards Grid (only show if 'all' is active to unclutter, or show always)
        if (_b2cActiveTab == B2CTab.all) 
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10,
            childAspectRatio: 0.7,
            children: [
              _buildTypeCard('Reguler', '👤', _getStats(b2cTabMap[B2CTab.reguler]!), const Color(0xFF10B981), totalAllCount),
              _buildTypeCard('HVC Gold', '⭐', _getStats(b2cTabMap[B2CTab.gold]!), const Color(0xFFF59E0B), totalAllCount),
              _buildTypeCard('HVC Platinum', '💎', _getStats(b2cTabMap[B2CTab.platinum]!), const Color(0xFF8B5CF6), totalAllCount),
              _buildTypeCard('HVC Diamond', '🔷', _getStats(b2cTabMap[B2CTab.diamond]!), const Color(0xFF0EA5E9), totalAllCount),
            ],
          ),
        const SizedBox(height: 16),

        // Filter Bar B2C
        _buildB2CFilterBar(),
        const SizedBox(height: 16),

        // Tickets List
        ...tableTickets.take(10).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TicketCard(
                ticket: t,
                onAssignTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => AssignTechnicianModal(
                      ticketId: t.idTicket,
                      ticketCode: t.ticket,
                      ticketWorkzone: t.workzone,
                      currentTechnicianId: t.teknisiUserId,
                      currentTechnicianName: t.technicianName,
                      onAssign: () async {
                        _loadData();
                      },
                    ),
                  );
                },
              ),
            )),
        if (tableTickets.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No tickets found', style: TextStyle(color: context.themeColors.textSecondary)))),
        if (tableTickets.length > 10) Padding(padding: const EdgeInsets.only(top: 8), child: Center(child: Text('+ ${tableTickets.length - 10} more tickets', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))),
      ],
    );
  }

  Widget _buildB2CSummaryCard(_CatStats s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF312E81)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('B2C TOTAL SUMMARY', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text('${s.total}', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, height: 1)),
          const Text('Daily Operational Tickets', style: TextStyle(color: Colors.blueAccent, fontSize: 11)),
          const SizedBox(height: 20),
          
          Row(
            children: [
              _summaryCol('📋 Reguler', s.regulerCount, s.total > 0 ? (s.regulerCount / s.total * 100).toInt() : 0),
              const SizedBox(width: 24),
              _summaryCol('📊 SQM', s.sqmCount, s.total > 0 ? (s.sqmCount / s.total * 100).toInt() : 0),
              const SizedBox(width: 24),
              _summaryCol('❓ Unspec', s.unspecCount, s.total > 0 ? (s.unspecCount / s.total * 100).toInt() : 0),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statTextCol('${s.open}', 'Open', const Color(0xFFFBBF24)),
              const SizedBox(width: 28),
              _statTextCol('${s.assigned}', 'Assigned', const Color(0xFF60A5FA)),
              const SizedBox(width: 28),
              _statTextCol('${s.close}', 'Close', const Color(0xFF34D399)),
            ],
          ),
          if (s.ffgCount > 0 || s.p1Count > 0 || s.pPlusCount > 0) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                if (s.ffgCount > 0) _statTextCol('${s.ffgCount}', '🔥 FFG', const Color(0xFFA855F7)),
                if (s.ffgCount > 0) const SizedBox(width: 28),
                if (s.p1Count > 0) _statTextCol('${s.p1Count}', '⚡ P1', const Color(0xFFEF4444)),
                if (s.p1Count > 0) const SizedBox(width: 28),
                if (s.pPlusCount > 0) _statTextCol('${s.pPlusCount}', '⚡ P+', const Color(0xFFF59E0B)),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _summaryCol(String iconLabel, int count, int pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(iconLabel, style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
        Text('$count', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text('$pct% of total', style: TextStyle(color: Colors.blueAccent.withOpacity(0.7), fontSize: 9)),
      ],
    );
  }

  Widget _statTextCol(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: TextStyle(color: value == '0' ? color.withOpacity(0.4) : color, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: Colors.blueAccent.withOpacity(0.7), fontSize: 10)),
      ],
    );
  }

  Widget _buildTypeCard(String name, String icon, _CatStats s, Color accent, int totalAll) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(child: Text(name.toUpperCase(), style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
            ],
          ),
          const SizedBox(height: 8),
          Text('${s.total}', style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
          Text(totalAll > 0 ? '${(s.total/totalAll*100).toStringAsFixed(1)}% of total' : '0%', style: TextStyle(color: context.themeColors.textMuted, fontSize: 9)),
          const Spacer(),
          // Pills
          if (s.regulerCount > 0) _pill('📋 Reguler', s.regulerCount, accent),
          if (s.sqmCount > 0) _pill('📊 SQM', s.sqmCount, accent),
          if (s.unspecCount > 0) _pill('❓ Unspec', s.unspecCount, accent),
          const SizedBox(height: 4),
          // Progress bars
          if (s.regulerCount > 0) _miniBar('Reguler', s.regulerCount, s.total, accent),
          if (s.sqmCount > 0) _miniBar('SQM', s.sqmCount, s.total, accent),
          if (s.unspecCount > 0) _miniBar('Unspec', s.unspecCount, s.total, accent),
          const SizedBox(height: 6),
          // Dots
          Wrap(
            spacing: 6,
            children: [
              _dotLabel(s.open, 'Open', Colors.amber),
              _dotLabel(s.assigned, 'Assign', Colors.blue),
              _dotLabel(s.close, 'Close', Colors.green),
            ],
          )
        ],
      ),
    );
  }

  Widget _pill(String label, int val, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text('$label: $val', style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _miniBar(String label, int val, int total, Color c) {
    double pct = total > 0 ? val / total : 0;
    return Row(
      children: [
        SizedBox(width: 32, child: Text(label, style: TextStyle(fontSize: 8, color: context.themeColors.textMuted))),
        Expanded(
          child: Container(
            height: 4, decoration: BoxDecoration(color: context.themeColors.border, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: pct, child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)))),
          ),
        ),
        SizedBox(width: 24, child: Text('${(pct*100).toInt()}%', textAlign: TextAlign.right, style: TextStyle(fontSize: 8, color: context.themeColors.textSecondary))),
      ],
    );
  }

  Widget _dotLabel(int val, String lbl, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$val $lbl', style: TextStyle(fontSize: 8, color: context.themeColors.textSecondary)),
      ],
    );
  }

  Widget _buildB2CFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: context.themeColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.themeColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterRow<TicketType>('Jenis', TicketType.values, _b2cTicketType, (v) => setState(() => _b2cTicketType = v), (v) => v.name),
          const Divider(height: 12),
          _filterRow<StatusUpdate>('Status', StatusUpdate.values, _b2cStatusUpdate, (v) => setState(() => _b2cStatusUpdate = v), (v) => v.name),
          const Divider(height: 12),
          _filterRow<FlaggingManja>('Flagging', FlaggingManja.values, _b2cFlagging, (v) => setState(() => _b2cFlagging = v), (v) => v.name),
        ],
      ),
    );
  }

  // --- B2B SECTION ---
  Widget _buildB2BSection() {
    final allB2B = _filteredTickets.where((t) => _isB2B(t)).toList();
    
    // Group breakdowns
    final map = {
      'SQM-CCAN': _getStats(allB2B.where((t) => _normalizeJenisB2B(t) == 'sqm-ccan').toList()),
      'Indibiz': _getStats(allB2B.where((t) => _normalizeJenisB2B(t) == 'indibiz').toList()),
      'Datin': _getStats(allB2B.where((t) => _normalizeJenisB2B(t) == 'datin').toList()),
      'Reseller': _getStats(allB2B.where((t) => _normalizeJenisB2B(t) == 'reseller').toList()),
      'WiFi-ID': _getStats(allB2B.where((t) => _normalizeJenisB2B(t) == 'wifi-id').toList()),
    };

    final tableTickets = allB2B.where((t) {
      if (_b2bTicketType != TicketTypeB2B.all) {
        final j = _normalizeJenisB2B(t);
        if (_b2bTicketType == TicketTypeB2B.sqmCcan && j != 'sqm-ccan') return false;
        if (_b2bTicketType == TicketTypeB2B.indibiz && j != 'indibiz') return false;
        if (_b2bTicketType == TicketTypeB2B.datin && j != 'datin') return false;
        if (_b2bTicketType == TicketTypeB2B.reseller && j != 'reseller') return false;
        if (_b2bTicketType == TicketTypeB2B.wifiId && j != 'wifi-id') return false;
      }
      if (!_matchStatus(t, _b2bStatusUpdate)) return false;
      if (!_matchFlagging(t, _b2bFlagging)) return false;
      return true;
    }).toList();

    final totalAllB2BStats = _getStats(allB2B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildB2BSummaryCard(totalAllB2BStats),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _buildB2BCategoryCard('SQM-CCAN', '📡', '4', map['SQM-CCAN']!, const Color(0xFF8B5CF6), totalAllB2BStats.total),
            _buildB2BCategoryCard('INDIBIZ', '🏢', '4', map['Indibiz']!, const Color(0xFF3B82F6), totalAllB2BStats.total),
            _buildB2BCategoryCard('DATIN', '🔷', '1.5', map['Datin']!, const Color(0xFF06B6D4), totalAllB2BStats.total),
            _buildB2BCategoryCard('RESELLER', '🏠', '8', map['Reseller']!, const Color(0xFFF97316), totalAllB2BStats.total),
            _buildB2BCategoryCard('WIFI-ID', '📶', '4', map['WiFi-ID']!, const Color(0xFF10B981), totalAllB2BStats.total),
          ],
        ),
        const SizedBox(height: 16),
        _buildB2BFilterBar(),
        const SizedBox(height: 16),
        ...tableTickets.take(10).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TicketCard(
                ticket: t,
                onAssignTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assign Technician modal coming soon')),
                  );
                },
              ),
            )),
        if (tableTickets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No tickets found',
                style: TextStyle(color: context.themeColors.textSecondary),
              ),
            ),
          ),
        if (tableTickets.length > 10) Padding(padding: const EdgeInsets.only(top: 8), child: Center(child: Text('+ ${tableTickets.length - 10} more tickets', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))),
      ],
    );
  }

  Widget _buildB2BSummaryCard(_CatStats s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF312E81)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('🏢', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              const Text('B2B', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${s.total}', style: const TextStyle(color: Colors.blueAccent, fontSize: 44, fontWeight: FontWeight.w900, height: 1)),
          const Text('Total Tickets', style: TextStyle(color: Colors.blueAccent, fontSize: 11)),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _summaryCol('📋 Reguler', s.regulerCount, s.total > 0 ? (s.regulerCount / s.total * 100).toInt() : 0),
                const SizedBox(width: 24),
                _summaryCol('📊 SQM', s.sqmCount, s.total > 0 ? (s.sqmCount / s.total * 100).toInt() : 0),
                if (s.ffgCount > 0) const SizedBox(width: 24),
                if (s.ffgCount > 0) _summaryCol('🛡️ FFG', s.ffgCount, s.total > 0 ? (s.ffgCount / s.total * 100).toInt() : 0),
                if (s.p1Count > 0) const SizedBox(width: 24),
                if (s.p1Count > 0) _summaryCol('⚠️ P1', s.p1Count, s.total > 0 ? (s.p1Count / s.total * 100).toInt() : 0),
                if (s.pPlusCount > 0) const SizedBox(width: 24),
                if (s.pPlusCount > 0) _summaryCol('📈 P+', s.pPlusCount, s.total > 0 ? (s.pPlusCount / s.total * 100).toInt() : 0),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statTextCol('${s.open}', 'Open', const Color(0xFFFBBF24)),
              const SizedBox(width: 28),
              _statTextCol('${s.assigned}', 'Assigned', const Color(0xFF60A5FA)),
              const SizedBox(width: 28),
              _statTextCol('${s.close}', 'Close', const Color(0xFF34D399)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Open • Assigned • Close', style: TextStyle(color: Colors.white54, fontSize: 10)),
              Text('${s.total} total', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildB2BCategoryCard(String name, String icon, String sla, _CatStats s, Color accent, int totalAll) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Text(icon, style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(name.toUpperCase(), style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 10, color: accent),
                    const SizedBox(width: 2),
                    Text('$sla Jam', style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text('${s.total}', style: TextStyle(color: accent, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
          Text(totalAll > 0 ? '${(s.total/totalAll*100).toStringAsFixed(1)}% of group' : '0% of group', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 12),
          // Progress bar line
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(color: context.themeColors.border, borderRadius: BorderRadius.circular(2)),
            child: Row(
              children: [
                if (s.total > 0 && s.open > 0)
                  Expanded(flex: s.open, child: Container(decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2)))),
                if (s.total > 0 && s.assigned > 0)
                  Expanded(flex: s.assigned, child: Container(decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2)))),
                if (s.total > 0 && s.close > 0)
                  Expanded(flex: s.close, child: Container(decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2)))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dotLabel(s.open, 'Open', Colors.amber),
              _dotLabel(s.assigned, 'Assigned', Colors.blue),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildB2BFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: context.themeColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.themeColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterRow<TicketTypeB2B>('Jenis', TicketTypeB2B.values, _b2bTicketType, (v) => setState(() => _b2bTicketType = v), (v) => v.name),
          const Divider(height: 12),
          _filterRow<StatusUpdate>('Status', StatusUpdate.values, _b2bStatusUpdate, (v) => setState(() => _b2bStatusUpdate = v), (v) => v.name),
          const Divider(height: 12),
          _filterRow<FlaggingManja>('Flagging', FlaggingManja.values, _b2bFlagging, (v) => setState(() => _b2bFlagging = v), (v) => v.name),
        ],
      ),
    );
  }

  // --- Core filter row builder ---
  Widget _filterRow<T>(String label, List<T> values, T current, ValueChanged<T> onSelect, String Function(T) nameBuilder) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: values.map((v) {
                final isSelected = v == current;
                return GestureDetector(
                  onTap: () => onSelect(v),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      border: Border.all(color: isSelected ? AppColors.primary.withOpacity(0.5) : Colors.transparent),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(nameBuilder(v).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }

  // ... (Other helpers _ServiceArea, _StatCard, _AccordionSection) ...

  Widget _buildServiceAreasTable() {
    // Exact same as before
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_serviceAreas.isEmpty) return const Center(child: Text('No service areas found', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(context.themeColors.surface),
        headingTextStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.themeColors.textSecondary),
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('SERVICE AREA')),
          DataColumn(label: Text('TOTAL'), numeric: true),
          DataColumn(label: Text('ASSIGNED'), numeric: true),
          DataColumn(label: Text('CLOSE'), numeric: true),
          DataColumn(label: Text('UNASSIGNED'), numeric: true),
        ],
        rows: _serviceAreas.map((a) => DataRow(cells: [
          DataCell(Row(children: [const Icon(Icons.circle, size: 8, color: AppColors.textMuted), const SizedBox(width: 8), Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))])),
          DataCell(Text('${a.total}', style: const TextStyle(fontWeight: FontWeight.w700))),
          DataCell(Text('${a.assigned}', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade600))),
          DataCell(Text('${a.closed}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF10B981)))),
          DataCell(Text('${a.unassigned}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444)))),
        ])).toList(),
      ),
    );
  }
}

class _CatStats {
  final int total, open, assigned, close;
  final int regulerCount, sqmCount, unspecCount;
  final int ffgCount, p1Count, pPlusCount;

  _CatStats({
    required this.total, required this.open, required this.assigned, required this.close,
    required this.regulerCount, required this.sqmCount, required this.unspecCount,
    required this.ffgCount, required this.p1Count, required this.pPlusCount,
  });
}

class _ServiceArea {
  final String name;
  final int total, unassigned, assigned, closed;
  _ServiceArea({required this.name, required this.total, required this.unassigned, required this.assigned, required this.closed});
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color accentColor;
  final List<Color> gradient;
  final String? subInfo;
  final bool loading;
  const _StatCard({required this.label, required this.value, required this.accentColor, required this.gradient, this.subInfo, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.themeColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.themeColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, width: double.infinity, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(2))),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
          const Spacer(),
          loading ? SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)) : Text('$value', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: accentColor, height: 1)),
          if (subInfo != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subInfo!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted))),
        ],
      ),
    );
  }
}

class _AccordionSection extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  const _AccordionSection({required this.title, required this.expanded, required this.onToggle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(color: context.themeColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.themeColors.border)),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                  const Spacer(),
                  AnimatedRotation(turns: expanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: child),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
