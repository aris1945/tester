import 'package:flutter/material.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/core/utils.dart';
import 'package:dompis_app/data/models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final VoidCallback? onAssignTap;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.onAssignTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = ticket.effectiveStatus;
    final statusColor = _getStatusColor(status);
    final ctypeInfo =
        CustomerTypeInfo.get(ticket.ctype ?? ticket.customerType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.themeColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.themeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ticket number + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Customer type icon
                      Text(ctypeInfo.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.ticket,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: context.themeColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Customer name and contact
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14,
                    color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticket.contactName ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.themeColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Service No
            Row(
              children: [
                const Icon(Icons.router_outlined, size: 14,
                    color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  ticket.serviceNo ?? '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.themeColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Bottom row: workzone + reported date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (ticket.workzone != null && ticket.workzone!.isNotEmpty)
                  Flexible(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13,
                            color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ticket.workzone!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  AppUtils.formatDateShort(ticket.reportedDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: context.themeColors.border),
            const SizedBox(height: 12),

            // Technician and Assign Button section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Technician',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (ticket.technicianName != null &&
                          ticket.technicianName!.isNotEmpty)
                        Text(
                          ticket.technicianName!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.themeColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const Text(
                          'Unassigned',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Jenis tiket: ${ticket.jenisTiket?.toUpperCase() ?? 'UNSPEC'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAssignTap != null)
                  ElevatedButton(
                    onPressed: onAssignTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // Blue 600
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.person_add_alt_1, size: 20),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ASSIGNED':
        return AppColors.assigned;
      case 'ON_PROGRESS':
        return AppColors.onProgress;
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
