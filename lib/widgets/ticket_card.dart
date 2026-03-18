import 'package:flutter/material.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/core/utils.dart';
import 'package:dompis_app/data/models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            // Technician name (if assigned)
            if (ticket.technicianName != null &&
                ticket.technicianName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.engineering_outlined, size: 13,
                      color: AppColors.closed),
                  const SizedBox(width: 4),
                  Text(
                    ticket.technicianName!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.closed,
                    ),
                  ),
                ],
              ),
            ],
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
