class TechnicianAttendance {
  final int id;
  final int technicianId;
  final String checkInAt;
  final String? checkOutAt;
  final String date;
  final int month;
  final int year;
  final int workzoneId;
  final String status;
  final String? notes;
  final String? technicianName;
  final String? technicianNik;
  final String? workzoneName;

  TechnicianAttendance({
    required this.id,
    required this.technicianId,
    required this.checkInAt,
    this.checkOutAt,
    required this.date,
    required this.month,
    required this.year,
    required this.workzoneId,
    required this.status,
    this.notes,
    this.technicianName,
    this.technicianNik,
    this.workzoneName,
  });

  factory TechnicianAttendance.fromJson(Map<String, dynamic> json) {
    return TechnicianAttendance(
      id: json['id'] as int? ?? 0,
      technicianId: json['technician_id'] as int? ?? 0,
      checkInAt: json['check_in_at'] as String? ?? '',
      checkOutAt: json['check_out_at'] as String?,
      date: json['date'] as String? ?? '',
      month: json['month'] as int? ?? 0,
      year: json['year'] as int? ?? 0,
      workzoneId: json['workzone_id'] as int? ?? 0,
      status: json['status'] as String? ?? 'PRESENT',
      notes: json['notes'] as String?,
      technicianName: json['technician_name'] as String?,
      technicianNik: json['technician_nik'] as String?,
      workzoneName: json['workzone_name'] as String?,
    );
  }
}

class TodayAttendanceStatus {
  final bool checkedIn;
  final bool checkedOut;
  final String? checkInAt;
  final String? checkOutAt;
  final String? status;
  final int? workzoneId;

  TodayAttendanceStatus({
    this.checkedIn = false,
    this.checkedOut = false,
    this.checkInAt,
    this.checkOutAt,
    this.status,
    this.workzoneId,
  });

  factory TodayAttendanceStatus.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceStatus(
      checkedIn: json['checked_in'] as bool? ?? false,
      checkedOut: json['checked_out'] as bool? ?? false,
      checkInAt: json['check_in_at'] as String?,
      checkOutAt: json['check_out_at'] as String?,
      status: json['status'] as String?,
      workzoneId: json['workzone_id'] as int?,
    );
  }
}
