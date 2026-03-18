import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/core/utils.dart';
import 'package:dompis_app/data/models/ticket.dart';
import 'package:dompis_app/providers/api_providers.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  Ticket? _ticket;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(ticketApiProvider);
      final data = await api.getTicketDetail(widget.ticketId);
      if (data['success'] == true && data['data'] != null) {
        setState(() {
          _ticket = Ticket.fromJson(data['data'] as Map<String, dynamic>);
        });
      }
    } catch (e) {
      debugPrint('Error loading ticket: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickupTicket() async {
    setState(() => _actionLoading = true);
    try {
      final api = ref.read(ticketApiProvider);
      final data = await api.pickupTicket(widget.ticketId);
      if (data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tiket berhasil di-pickup!'),
              backgroundColor: AppColors.closed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal pickup: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _closeTicket() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Tiket'),
        content: const Text('Yakin ingin menutup tiket ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tutup'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      final api = ref.read(ticketApiProvider);
      final data = await api.closeTicket({
        'ticketId': widget.ticketId,
      });
      if (data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tiket berhasil ditutup! 🎉'),
              backgroundColor: AppColors.closed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal close: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          _ticket?.ticket ?? 'Detail Tiket',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _ticket == null
              ? const Center(child: Text('Tiket tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        _buildStatusBadge(_ticket!.effectiveStatus),
                        const SizedBox(height: 16),

                        // Customer info card
                        _buildCard(
                          title: 'Informasi Pelanggan',
                          children: [
                            _buildRow('Nama', _ticket!.contactName),
                            _buildRow('No HP', _ticket!.contactPhone,
                                isPhone: true),
                            _buildRow('Service No', _ticket!.serviceNo),
                            _buildRow('Tipe', CustomerTypeInfo.get(
                                _ticket!.ctype ?? _ticket!.customerType)
                                .label),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Ticket info card
                        _buildCard(
                          title: 'Detail Tiket',
                          children: [
                            _buildRow('Incident', _ticket!.ticket),
                            _buildRow('Summary', _ticket!.summary),
                            _buildRow('Symptom', _ticket!.symptom),
                            _buildRow('Workzone', _ticket!.workzone),
                            _buildRow('Alamat', _ticket!.alamat),
                            _buildRow('Reported',
                                AppUtils.formatDate(_ticket!.reportedDate)),
                            _buildRow('Jenis', _ticket!.jenisTiket),
                            if (_ticket!.technicianName != null)
                              _buildRow('Teknisi', _ticket!.technicianName),
                            if (_ticket!.pendingReason != null)
                              _buildRow('Pending Reason', _ticket!.pendingReason),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        if (!AppUtils.isTicketClosed(_ticket!.statusUpdate))
                          _buildActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'ASSIGNED':
        color = AppColors.assigned;
        break;
      case 'ON_PROGRESS':
        color = AppColors.onProgress;
        break;
      case 'PENDING':
        color = AppColors.pending;
        break;
      case 'CLOSE':
      case 'CLOSED':
        color = AppColors.closed;
        break;
      default:
        color = AppColors.open;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String? value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: isPhone && value != null && value.isNotEmpty
                ? GestureDetector(
                    onTap: () => launchUrl(
                        Uri.parse(AppUtils.getWhatsAppUrl(value))),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final status = _ticket!.effectiveStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'ASSIGNED')
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _actionLoading ? null : _pickupTicket,
              icon: _actionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: const Text('Pickup Tiket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (status == 'ON_PROGRESS') ...[
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _actionLoading ? null : _closeTicket,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Close Tiket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.closed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
