import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dompis_app/providers/api_providers.dart';
import 'package:dompis_app/providers/auth_provider.dart';
import 'package:dompis_app/data/models/user.dart';
import 'dart:async';

class AttendanceCheckScreen extends ConsumerStatefulWidget {
  const AttendanceCheckScreen({super.key});

  @override
  ConsumerState<AttendanceCheckScreen> createState() => _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState extends ConsumerState<AttendanceCheckScreen> {
  DateTime _now = DateTime.now();
  Timer? _timer;
  List<ServiceArea> _serviceAreas = [];
  int? _selectedWorkzoneId;
  bool _loading = true;
  bool _actionLoading = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final attendanceApi = ref.read(attendanceApiProvider);
      final apiClient = ref.read(apiClientProvider);

      final results = await Future.wait([
        attendanceApi.getUserServiceAreas(),
        apiClient.dio.get('/api/users/me'),
      ]);

      final saData = results[0] as Map<String, dynamic>;
      final profileData = (results[1] as dynamic).data as Map<String, dynamic>;

      if (saData['success'] == true && saData['data'] != null) {
        final list = saData['data'] as List<dynamic>;
        _serviceAreas = list
            .map((e) => ServiceArea.fromJson(e as Map<String, dynamic>))
            .toList();
        if (_serviceAreas.isNotEmpty) {
          _selectedWorkzoneId = _serviceAreas.first.idSa;
        }
      }

      if (profileData['success'] == true && profileData['data'] != null) {
        _userName = profileData['data']['nama'];
      }
    } catch (e) {
      debugPrint('Error loading initial attendance data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleCheckIn() async {
    if (_selectedWorkzoneId == null) return;
    setState(() => _actionLoading = true);
    try {
      final api = ref.read(attendanceApiProvider);
      final data = await api.checkIn(_selectedWorkzoneId!);
      
      if (data['success'] == true) {
        // Save ID locally for check-out later
        final tokenStorage = ref.read(tokenStorageProvider);
        await tokenStorage.saveActiveWorkzoneId(_selectedWorkzoneId!);

        if (mounted) {
          // Update auth state so router redirects to dashboard
          ref.read(authProvider.notifier).markAttendanceChecked();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal check-in')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_now);
    final timeStr = DateFormat('HH : mm : ss').format(_now);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome Header
              Text(
                'Selamat Datang,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (_userName ?? 'Teknisi').toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 48),

              // Main Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Lighter Slate Card
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    // Clock
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Workzone field
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Workzone:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedWorkzoneId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                          items: _serviceAreas.map((sa) {
                            return DropdownMenuItem<int>(
                              value: sa.idSa,
                              child: Text(
                                sa.namaSa ?? 'Unknown',
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedWorkzoneId = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Status Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444), // Red dot
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Belum Absen',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _actionLoading ? null : _handleCheckIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Vibrant Green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _actionLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'ABSEN MASUK',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Footer information
              Text(
                'Anda harus absen terlebih dahulu\nuntuk mengakses sistem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
