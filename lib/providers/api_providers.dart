import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dompis_app/data/api/api_client.dart';
import 'package:dompis_app/data/api/auth_api.dart';
import 'package:dompis_app/data/api/ticket_api.dart';
import 'package:dompis_app/data/api/technician_api.dart';
import 'package:dompis_app/data/api/attendance_api.dart';
import 'package:dompis_app/data/api/token_storage.dart';

// Token Storage
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

// API Client
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage);
});

// API Services
final authApiProvider = Provider<AuthApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthApi(apiClient, tokenStorage);
});

final ticketApiProvider = Provider<TicketApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TicketApi(apiClient);
});

final technicianApiProvider = Provider<TechnicianApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TechnicianApi(apiClient);
});

final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AttendanceApi(apiClient);
});
