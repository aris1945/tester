import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/core/theme.dart';
import 'package:dompis_app/core/utils.dart';
import 'package:dompis_app/data/models/attendance.dart';
import 'package:dompis_app/data/models/user.dart';
import 'package:dompis_app/providers/api_providers.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  TodayAttendanceStatus? _status;
  List<ServiceArea> _serviceAreas = [];
  int? _selectedWorkzoneId;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final attendanceApi = ref.read(attendanceApiProvider);

      // Fetch status and service areas
      final statusData = await attendanceApi.getStatus();
      final saData = await attendanceApi.getUserServiceAreas();

      if (statusData['success'] == true && statusData['data'] != null) {
        _status = TodayAttendanceStatus.fromJson(
            statusData['data'] as Map<String, dynamic>);
      }

      if (saData['success'] == true && saData['data'] != null) {
        final list = saData['data'] as List<dynamic>;
        _serviceAreas = list
            .map((e) => ServiceArea.fromJson(e as Map<String, dynamic>))
            .toList();
        if (_serviceAreas.isNotEmpty) {
          _selectedWorkzoneId = _serviceAreas.first.idSa;
        }
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    if (_selectedWorkzoneId == null) return;
    setState(() => _actionLoading = true);
    try {
      final api = ref.read(attendanceApiProvider);
      final data = await api.checkIn(_selectedWorkzoneId!);
      if (data['success'] == true) {
        // Save ID locally for check-out later
        final tokenStorage = ref.read(tokenStorageProvider);
        await tokenStorage.saveActiveWorkzoneId(_selectedWorkzoneId!);
        
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Check-in berhasil! ✅'),
              backgroundColor: AppColors.closed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal check-in: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _checkOut() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    int? workzoneId = _status?.workzoneId ?? await tokenStorage.getActiveWorkzoneId();

    if (workzoneId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Workzone ID tidak ditemukan')),
        );
      }
      return;
    }
    
    setState(() => _actionLoading = true);
    try {
      final api = ref.read(attendanceApiProvider);
      final data = await api.checkOut(workzoneId);
      if (data['success'] == true) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Check-out berhasil! 👋'),
              backgroundColor: AppColors.closed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal check-out: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeColors.surface,
      appBar: AppBar(
        title: Text('Absensi',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.themeColors.textPrimary)),
        backgroundColor: context.themeColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: context.themeColors.border,
            height: 1,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _status?.checkedIn == true
                            ? [
                                AppColors.closed.withOpacity(0.9),
                                AppColors.closed
                              ]
                            : [
                                AppColors.primary.withOpacity(0.9),
                                AppColors.primary
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _status?.checkedIn == true
                              ? Icons.check_circle_rounded
                              : Icons.access_time_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _status?.checkedIn == true
                              ? 'Sudah Check-in'
                              : 'Belum Check-in',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_status?.checkInAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Check-in: ${AppUtils.formatDate(_status!.checkInAt)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (_status?.checkOutAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Check-out: ${AppUtils.formatDate(_status!.checkOutAt)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (_status?.status != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _status!.status!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Workzone selector (for check-in)
                  if (_status?.checkedIn != true && _serviceAreas.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.themeColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.themeColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Workzone',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.themeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedWorkzoneId,
                            dropdownColor: context.themeColors.card,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: context.themeColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.themeColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.themeColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: TextStyle(color: context.themeColors.textPrimary),
                            items: _serviceAreas.map((sa) {
                              return DropdownMenuItem<int>(
                                value: sa.idSa,
                                child: Text(sa.namaSa ?? 'Unknown'),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedWorkzoneId = v),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Action button
                  if (_status?.checkedOut != true)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _actionLoading
                            ? null
                            : (_status?.checkedIn == true
                                ? _checkOut
                                : _checkIn),
                        icon: _actionLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_status?.checkedIn == true
                                ? Icons.logout_rounded
                                : Icons.login_rounded),
                        label: Text(
                          _status?.checkedIn == true ? 'Check Out' : 'Check In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _status?.checkedIn == true
                              ? AppColors.open
                              : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                  if (_status?.checkedOut == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.themeColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.themeColors.border),
                      ),
                      child: Column(
                        children: [
                          const Text('✅',
                              style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            'Anda sudah check-out hari ini',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.themeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
