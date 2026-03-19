import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/data/models/technician.dart';

class AssignTechnicianModal extends ConsumerStatefulWidget {
  final int ticketId;
  final String ticketCode;
  final String? ticketWorkzone;
  final int? currentTechnicianId;
  final String? currentTechnicianName;
  final Future<void> Function() onAssign;

  const AssignTechnicianModal({
    super.key,
    required this.ticketId,
    required this.ticketCode,
    this.ticketWorkzone,
    this.currentTechnicianId,
    this.currentTechnicianName,
    required this.onAssign,
  });

  @override
  ConsumerState<AssignTechnicianModal> createState() => _AssignTechnicianModalState();
}

class _AssignTechnicianModalState extends ConsumerState<AssignTechnicianModal> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  
  List<Technician> _technicians = [];
  int? _selectedId;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentTechnicianId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTechnicians();
    });
  }

  Future<void> _fetchTechnicians() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ref.read(ticketApiProvider).getTicketTechnicians(widget.ticketId);
      if (res['success'] == true) {
        final dataObj = res['data'] as Map<String, dynamic>?;
        final List<dynamic> dataList = dataObj?['technicians'] as List<dynamic>? ?? [];
        final techs = dataList.map((e) => Technician.fromJson(e)).toList();
        setState(() {
          _technicians = techs;
          _loading = false;
        });

        // Validate selected ID is eligible
        if (widget.currentTechnicianId != null) {
          final isEligible = techs.any((t) => t.idUser == widget.currentTechnicianId);
          if (!isEligible) {
            setState(() {
              _selectedId = null;
            });
          }
        }
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load technicians';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load technicians: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedId == null) {
      setState(() => _error = 'Please select a technician');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await ref.read(ticketApiProvider).assignTicket(
        ticketId: widget.ticketId,
        teknisiUserId: _selectedId!,
      );

      if (res['success'] == true) {
        await widget.onAssign();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _error = res['message'] ?? 'Failed to assign ticket');
      }
    } catch (e) {
      setState(() => _error = 'Assignment failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleUnassign() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await ref.read(ticketApiProvider).unassignTicket(widget.ticketId);

      if (res['success'] == true) {
        await widget.onAssign();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _error = res['message'] ?? 'Failed to unassign ticket');
      }
    } catch (e) {
      setState(() => _error = 'Unassign failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _technicians.where((t) {
      final search = _searchTerm.toLowerCase();
      final name = (t.nama).toLowerCase();
      final nik = (t.nik ?? '').toLowerCase();
      return name.contains(search) || nik.contains(search);
    }).toList();

    final isCurrentAssigned = widget.currentTechnicianId != null;
    final isSelectedCurrent = _selectedId == widget.currentTechnicianId;
    final isEligible = isCurrentAssigned && _technicians.any((t) => t.idUser == widget.currentTechnicianId);

    // Using MaxHeight logic to not exceed 85% of screen
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Technician',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.ticketCode.isNotEmpty ? '${widget.ticketCode} - ' : ''}Ticket ID #${widget.ticketId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('Workzone', widget.ticketWorkzone ?? '-'),
                _buildTag('Eligible', '${_technicians.length}'),
                if (isCurrentAssigned)
                  _buildTag('Current', widget.currentTechnicianName ?? '#${widget.currentTechnicianId}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),

          // Messages / Errors
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red[800], fontSize: 13),
                ),
              ),
            ),

          if (!_loading && isCurrentAssigned && !isEligible && _technicians.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current technician does not match this ticket workzone. Pick an eligible technician or remove the assignment.',
                  style: TextStyle(color: Colors.amber[800], fontSize: 13),
                ),
              ),
            ),

          // Content body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Search
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or NIK...',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() {
                                  _searchTerm = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchTerm = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // List
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text('No technician found', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                                    SizedBox(height: 4),
                                    Text('Try a different keyword', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final tech = filtered[i];
                                  final isSelected = _selectedId == tech.idUser;
                                  final isCurrent = widget.currentTechnicianId == tech.idUser;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedId = tech.idUser;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.blue[50] : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tech.nama,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'NIK: ${tech.nik ?? '-'}',
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (isCurrent) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[50],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Currently assigned',
                                                      style: TextStyle(
                                                        color: Colors.green[700],
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 24,
                                            width: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? AppColors.primary : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                                : null,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: AppColors.borderLight),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitting || _loading || _selectedId == null || isSelectedCurrent
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                            elevation: 0,
                          ),
                          child: Text(
                            _submitting
                                ? 'Processing...'
                                : isCurrentAssigned
                                    ? 'Reassign'
                                    : 'Assign',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isCurrentAssigned) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _handleUnassign,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.red[200]!),
                        ),
                        child: Text('Remove Assignment', style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
