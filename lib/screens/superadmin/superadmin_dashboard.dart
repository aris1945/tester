import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/data/models/ticket.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/widgets/stat_card.dart';
import 'package:dompis_app/providers/theme_provider.dart';

class SuperadminDashboard extends ConsumerStatefulWidget {
  const SuperadminDashboard({super.key});

  @override
  ConsumerState<SuperadminDashboard> createState() =>
      _SuperadminDashboardState();
}

class _SuperadminDashboardState extends ConsumerState<SuperadminDashboard> {
  bool _loading = true;
  List<Ticket> _tickets = [];
  int _total = 0, _open = 0, _inProgress = 0, _closed = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(ticketApiProvider);
      final results = await Future.wait([
        api.getTickets(),
        api.getDashboardStats(type: 'stats'),
      ]);

      final ticketsData = results[0];
      final statsData = results[1];

      if (ticketsData['success'] == true) {
        final list = ticketsData['data']?['data'] as List<dynamic>? ??
            ticketsData['data'] as List<dynamic>? ??
            [];
        _tickets =
            list.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
      }

      if (statsData['success'] == true && statsData['data'] != null) {
        final s = statsData['data'] as Map<String, dynamic>;
        _total = s['totalTickets'] as int? ?? 0;
        _closed = s['completedTickets'] as int? ?? 0;
        _inProgress = s['unfinishedTickets'] as int? ?? 0;
        _open = _total - _closed - _inProgress;
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
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
                          Text('Superadmin',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: context.themeColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('System overview',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: context.themeColors.textSecondary)),
                        ],
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final mode = ref.watch(themeProvider);
                          return IconButton(
                            icon: Icon(
                              mode == ThemeMode.dark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                              color: mode == ThemeMode.dark ? Colors.amber : context.themeColors.textPrimary,
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text('Recent Tickets',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.themeColors.textPrimary)),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ticket = _tickets[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.themeColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: context.themeColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.ticket,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: context.themeColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.contactName ?? '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.themeColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                      ticket.effectiveStatus)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ticket.effectiveStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(
                                    ticket.effectiveStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount:
                      _tickets.length > 10 ? 10 : _tickets.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ASSIGNED':
      case 'ON_PROGRESS':
        return AppColors.assigned;
      case 'PENDING':
        return AppColors.pending;
      case 'CLOSE':
      case 'CLOSED':
        return AppColors.closed;
      default:
        return AppColors.open;
    }
  }
}
