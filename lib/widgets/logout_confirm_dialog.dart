import 'package:flutter/material.dart';
import 'package:dompis_app/core/theme.dart';

class LogoutConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool loading;

  const LogoutConfirmDialog({
    super.key,
    required this.onConfirm,
    this.loading = false,
  });

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LogoutConfirmDialog(
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.themeColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.themeColors.border),
      ),
      title: Row(
        children: [
          const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 10),
          Text(
            'Keluar dari aplikasi?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.themeColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'Anda harus login kembali untuk mengakses aplikasi.',
        style: TextStyle(color: context.themeColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Batal',
            style: TextStyle(
              color: context.themeColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: loading ? null : onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Ya, keluar'),
        ),
      ],
    );
  }
}
