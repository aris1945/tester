import 'package:dio/dio.dart';
import 'package:dompis_app/core/constants.dart';
import 'package:dompis_app/data/api/api_client.dart';
import 'package:dompis_app/data/models/ticket.dart';

class TicketApi {
  final Dio _dio;

  TicketApi(ApiClient apiClient) : _dio = apiClient.dio;

  /// Get tickets list (paginated)
  Future<Map<String, dynamic>> getTickets({
    String? search,
    int? limit,
    int? page,
    String? workzone,
    String? ctype,
    String? statusUpdate,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (limit != null) params['limit'] = limit;
    if (page != null) params['page'] = page;
    if (workzone != null && workzone.isNotEmpty) params['workzone'] = workzone;
    if (ctype != null && ctype.isNotEmpty) params['ctype'] = ctype;
    if (statusUpdate != null && statusUpdate.isNotEmpty) {
      params['statusUpdate'] = statusUpdate;
    }

    final response =
        await _dio.get(ApiConstants.tickets, queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  /// Get daily tickets
  Future<Map<String, dynamic>> getDailyTickets({
    String? search,
    int page = 1,
    String? workzone,
    String? ctype,
    String? dept,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (workzone != null && workzone.isNotEmpty) params['workzone'] = workzone;
    if (ctype != null && ctype.isNotEmpty) params['ctype'] = ctype;
    if (dept != null && dept.isNotEmpty) params['dept'] = dept;

    final response =
        await _dio.get(ApiConstants.ticketsDaily, queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  /// Get ticket stats
  Future<Map<String, dynamic>> getTicketStats({
    String? workzone,
    String? dept,
  }) async {
    final params = <String, dynamic>{};
    if (workzone != null && workzone.isNotEmpty) params['workzone'] = workzone;
    if (dept != null && dept.isNotEmpty) params['dept'] = dept;

    final response =
        await _dio.get(ApiConstants.ticketsStats, queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  /// Get ticket detail
  Future<Map<String, dynamic>> getTicketDetail(int ticketId) async {
    final response = await _dio.get(ApiConstants.ticketDetail(ticketId));
    return response.data as Map<String, dynamic>;
  }

  /// Get ticket evidence
  Future<Map<String, dynamic>> getTicketEvidence(int ticketId) async {
    final response = await _dio.get(ApiConstants.ticketEvidence(ticketId));
    return response.data as Map<String, dynamic>;
  }

  /// Pickup a ticket
  Future<Map<String, dynamic>> pickupTicket(int ticketId) async {
    final response = await _dio.post(
      ApiConstants.ticketsPickup,
      data: {'ticketId': ticketId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Update a ticket
  Future<Map<String, dynamic>> updateTicket(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.ticketsUpdate, data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Close a ticket
  Future<Map<String, dynamic>> closeTicket(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.ticketsClose, data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Assign a ticket to a technician
  Future<Map<String, dynamic>> assignTicket({
    required int ticketId,
    required int teknisiUserId,
  }) async {
    final response = await _dio.post(
      ApiConstants.ticketsAssign,
      data: {
        'ticketId': ticketId,
        'teknisiUserId': teknisiUserId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Unassign a ticket
  Future<Map<String, dynamic>> unassignTicket(int ticketId) async {
    final response = await _dio.post(
      ApiConstants.ticketsUnassign,
      data: {'ticketId': ticketId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Upload evidence
  Future<Map<String, dynamic>> uploadEvidence(FormData formData) async {
    final response = await _dio.post(
      ApiConstants.ticketsUploadEvidence,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get expired tickets
  Future<Map<String, dynamic>> getExpiredTickets({
    String? workzone,
    String? dept,
  }) async {
    final params = <String, dynamic>{};
    if (workzone != null && workzone.isNotEmpty) params['workzone'] = workzone;
    if (dept != null && dept.isNotEmpty) params['dept'] = dept;

    final response =
        await _dio.get(ApiConstants.ticketsExpired, queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  /// Get ticket technicians for assignment
  Future<Map<String, dynamic>> getTicketTechnicians(
    int ticketId, {
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dio.get(
      ApiConstants.ticketTechnicians(ticketId),
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats({String? type}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;

    final response =
        await _dio.get(ApiConstants.dashboardStats, queryParameters: params);
    return response.data as Map<String, dynamic>;
  }
}
