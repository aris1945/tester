import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/data/models/ticket.dart';
import 'package:dompis_app/providers/api_providers.dart';

import 'package:dompis_app/widgets/stat_card.dart';
import 'package:dompis_app/widgets/ticket_card.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  bool _loading = true;
  List<Ticket> _tickets = [];
  int _total = 0, _open = 0, _assigned = 0, _closed = 0;

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

        _total = _tickets.length;
        _open = _tickets.where((t) {
          final s = (t.statusUpdate ?? '').toLowerCase();
          return s.isEmpty || s == 'open';
        }).length;
        _assigned = _tickets.where((t) {
          final s = (t.statusUpdate ?? '').toLowerCase();
          return s == 'assigned' || s == 'on_progress' || s == 'pending';
        }).length;
        _closed = _tickets.where((t) {
          final s = (t.statusUpdate ?? '').toLowerCase();
          return s == 'close' || s == 'closed';
        }).length;
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
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Admin Dashboard',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text('Monitor & manage tickets',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),

              // Stats
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
                        loading: _loading,
                      ),
                      StatCard(
                        label: 'Unassigned',
                        value: _open,
                        color: AppColors.open,
                        loading: _loading,
                      ),
                      StatCard(
                        label: 'Assigned',
                        value: _assigned,
                        color: AppColors.assigned,
                        loading: _loading,
                      ),
                      StatCard(
                        label: 'Closed',
                        value: _closed,
                        color: AppColors.closed,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),
              ),

              // Ticket list header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text('Recent Tickets',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
              ),

              // Ticket list
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
                        final ticket =
                            _tickets.length > 20
                                ? _tickets.sublist(0, 20)[index]
                                : _tickets[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TicketCard(ticket: ticket),
                        );
                      },
                      childCount: _tickets.length > 20
                          ? 20
                          : _tickets.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
    );
  }
}
