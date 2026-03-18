class ApiConstants {
  static const String baseUrl = 'https://dompis.ta-branchsby.co.id';

  // Auth
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';

  // Tickets
  static const String tickets = '/api/tickets';
  static const String ticketsDaily = '/api/tickets/daily';
  static const String ticketsStats = '/api/tickets/stats';
  static const String ticketsExpired = '/api/tickets/expired';
  static const String ticketsUpdate = '/api/tickets/update';
  static const String ticketsPickup = '/api/tickets/pickup';
  static const String ticketsClose = '/api/tickets/close';
  static const String ticketsUploadEvidence = '/api/tickets/upload-evidence';

  static String ticketDetail(int id) => '/api/tickets/$id/detail';
  static String ticketEvidence(int id) => '/api/tickets/$id/evidence';
  static String ticketTechnicians(int id) => '/api/tickets/$id/technicians';

  // Users
  static const String usersMe = '/api/users/me';
  static const String usersMeSa = '/api/users/me/sa';
  static String usersByRole(int roleId) => '/api/users/role/$roleId';

  // Technicians
  static const String technicians = '/api/technicians';
  static String technicianById(int id) => '/api/technicians/$id';
  static const String attendanceStatus = '/api/technicians/attendance/status';
  static const String attendance = '/api/technicians/attendance';

  // Dashboard
  static const String dashboardStats = '/api/dashboard/stats';

  // Dropdowns
  static const String area = '/api/area';
  static const String sa = '/api/sa';
  static const String workzone = '/api/workzone';
}
