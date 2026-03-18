import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/data/models/ticket.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/providers/auth_provider.dart';
import 'package:dompis_app/widgets/ticket_card.dart';
import 'package:dompis_app/widgets/stat_card.dart';

// Ticket filter tabs (matching the web app)
enum TicketFilter { all, assigned, onProgress, pending, closed }

extension TicketFilterLabel on TicketFilter {
  String get label {
    switch (this) {
      case TicketFilter.all:
        return 'Semua';
      case TicketFilter.assigned:
        return 'Assigned';
      case TicketFilter.onProgress:
        return 'On Progress';
      case TicketFilter.pending:
        return 'Pending';
      case TicketFilter.closed:
        return 'Closed';
    }
  }
}

class TeknisiDashboard extends ConsumerStatefulWidget {
  const TeknisiDashboard({super.key});

  @override
  ConsumerState<TeknisiDashboard> createState() => _TeknisiDashboardState();
}

class _TeknisiDashboardState extends ConsumerState<TeknisiDashboard> {
  TicketFilter _filter = TicketFilter.all;
  String _searchQuery = '';
  bool _loading = true;
  List<Ticket> _tickets = [];
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _loading = true);
    try {
      final ticketApi = ref.read(ticketApiProvider);
      final data =
          await ticketApi.getTickets(limit: 100);

      if (data['success'] == true) {
        final list = data['data']?['data'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            [];
        setState(() {
          _tickets =
              list.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading tickets: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Ticket> get filteredTickets {
    var result = _tickets;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((t) => t.ticket.toLowerCase().contains(query))
          .toList();
    }

    // Status filter
    if (_filter != TicketFilter.all) {
      result = result.where((t) {
        final s = t.effectiveStatus;
        switch (_filter) {
          case TicketFilter.assigned:
            return s == 'ASSIGNED';
          case TicketFilter.onProgress:
            return s == 'ON_PROGRESS';
          case TicketFilter.pending:
            return s == 'PENDING';
          case TicketFilter.closed:
            return s == 'CLOSE' || s == 'CLOSED';
          default:
            return true;
        }
      }).toList();
    }

    return result;
  }

  List<Ticket> get paginatedTickets {
    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    final filtered = filteredTickets;
    if (start >= filtered.length) return [];
    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  int get totalPages => (filteredTickets.length / _pageSize).ceil();

  Map<String, int> get stats {
    int assigned = 0, onProgress = 0, pending = 0, closed = 0;
    for (final t in _tickets) {
      final s = t.effectiveStatus;
      if (s == 'ASSIGNED') assigned++;
      else if (s == 'ON_PROGRESS') onProgress++;
      else if (s == 'PENDING') pending++;
      else if (s == 'CLOSE' || s == 'CLOSED') closed++;
    }
    return {
      'total': _tickets.length,
      'assigned': assigned,
      'onProgress': onProgress,
      'pending': pending,
      'closed': closed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTickets,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Tickets',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage your assigned tickets',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Attendance button
                          _buildIconButton(
                            icon: Icons.access_time_rounded,
                            onTap: () => context.push('/teknisi/attendance'),
                          ),
                          const SizedBox(width: 8),
                          // Logout button
                          _buildIconButton(
                            icon: Icons.logout_rounded,
                            onTap: () {
                              ref.read(authProvider.notifier).logout();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: MiniStatCard(
                          label: 'Assigned',
                          value: stats['assigned'] ?? 0,
                          color: AppColors.assigned,
                          loading: _loading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Progress',
                          value: stats['onProgress'] ?? 0,
                          color: AppColors.onProgress,
                          loading: _loading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Pending',
                          value: stats['pending'] ?? 0,
                          color: AppColors.pending,
                          loading: _loading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Closed',
                          value: stats['closed'] ?? 0,
                          color: AppColors.closed,
                          loading: _loading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nomor tiket... (contoh: INC45671234)',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20,
                          color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Filter Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TicketFilter.values.map((filter) {
                        final isActive = _filter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _filter = filter;
                                _currentPage = 1;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Text(
                                filter.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Ticket List
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (filteredTickets.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _searchQuery.isNotEmpty ? '🔍' : '📋',
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tiket "$_searchQuery" tidak ditemukan'
                              : 'Tidak ada ticket',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Coba cek nomor tiket kembali'
                              : 'Ticket akan muncul ketika ditugaskan',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ticket = paginatedTickets[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TicketCard(
                            ticket: ticket,
                            onTap: () {
                              context.push(
                                  '/teknisi/ticket/${ticket.idTicket}');
                            },
                          ),
                        );
                      },
                      childCount: paginatedTickets.length,
                    ),
                  ),
                ),

              // Pagination
              if (!_loading && totalPages > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '$_currentPage / $totalPages',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        IconButton(
                          onPressed: _currentPage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
