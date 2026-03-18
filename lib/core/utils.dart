import 'package:intl/intl.dart';

class AppUtils {
  /// Format date string to a readable format
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format date to short format
  static String formatDateShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format phone number for WhatsApp link
  static String formatWhatsAppNumber(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0'), '62');
  }

  /// Get WhatsApp URL for a phone number
  static String getWhatsAppUrl(String phone) {
    return 'https://wa.me/${formatWhatsAppNumber(phone)}';
  }

  /// Normalize status for display
  static String normalizeStatus(String? status) {
    if (status == null || status.isEmpty) return 'OPEN';
    return status.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Check if a ticket is closed
  static bool isTicketClosed(String? statusUpdate) {
    if (statusUpdate == null) return false;
    final s = statusUpdate.trim().toLowerCase();
    return s == 'close' || s == 'closed';
  }

  /// Normalize jenis tiket
  static String normalizeJenis(String? jenis) {
    if (jenis == null || jenis.isEmpty) return 'unspec';
    final j = jenis.trim().toLowerCase();
    if (j.contains('sqm') && j.contains('ccan')) return 'sqm-ccan';
    if (j.contains('sqm')) return 'sqm';
    if (j.contains('reguler') || j.contains('regular')) return 'reguler';
    if (j.contains('hvc')) return 'hvc';
    if (j.contains('indibiz')) return 'indibiz';
    if (j.contains('datin')) return 'datin';
    if (j.contains('reseller')) return 'reseller';
    if (j.contains('wifi')) return 'wifi-id';
    return 'unspec';
  }

  /// Check if jenis is B2C
  static bool isB2CJenis(String? jenis) {
    final normalized = normalizeJenis(jenis);
    return ['reguler', 'sqm', 'hvc', 'unspec'].contains(normalized);
  }

  /// Check if jenis is B2B
  static bool isB2BJenis(String? jenis) {
    final normalized = normalizeJenis(jenis);
    return ['sqm-ccan', 'indibiz', 'datin', 'reseller', 'wifi-id']
        .contains(normalized);
  }
}
