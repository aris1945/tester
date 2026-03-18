class Technician {
  final int idUser;
  final String nama;
  final String? nik;
  final String? workzone;
  final String? avatarUrl;
  final List<TechnicianTicket> assignedTickets;
  final List<TechnicianTicket>? closedTicketsToday;
  final int totalAssigned;
  final int totalClosedToday;
  final double? averageResolveTimeHours;
  final TechnicianOrderCounts? orderCounts;

  Technician({
    required this.idUser,
    required this.nama,
    this.nik,
    this.workzone,
    this.avatarUrl,
    this.assignedTickets = const [],
    this.closedTicketsToday,
    this.totalAssigned = 0,
    this.totalClosedToday = 0,
    this.averageResolveTimeHours,
    this.orderCounts,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      idUser: json['id_user'] as int? ?? 0,
      nama: json['nama'] as String? ?? '',
      nik: json['nik'] as String?,
      workzone: json['workzone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      assignedTickets: (json['assigned_tickets'] as List<dynamic>?)
              ?.map((e) =>
                  TechnicianTicket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      closedTicketsToday: (json['closed_tickets_today'] as List<dynamic>?)
          ?.map(
              (e) => TechnicianTicket.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAssigned: json['total_assigned'] as int? ?? 0,
      totalClosedToday: json['total_closed_today'] as int? ?? 0,
      averageResolveTimeHours:
          (json['average_resolve_time_hours'] as num?)?.toDouble(),
      orderCounts: json['order_counts'] != null
          ? TechnicianOrderCounts.fromJson(
              json['order_counts'] as Map<String, dynamic>)
          : null,
    );
  }

  String get statusLabel {
    if (totalAssigned == 0) return 'IDLE';
    if (totalAssigned >= 5) return 'OVERLOAD';
    return 'AKTIF';
  }
}

class TechnicianTicket {
  final int idTicket;
  final String ticket;
  final String? contactName;
  final String? ctype;
  final String? serviceNo;
  final String? reportedDate;
  final String? hasilVisit;
  final String? age;
  final double? ageHours;
  final String? closedAt;

  TechnicianTicket({
    required this.idTicket,
    required this.ticket,
    this.contactName,
    this.ctype,
    this.serviceNo,
    this.reportedDate,
    this.hasilVisit,
    this.age,
    this.ageHours,
    this.closedAt,
  });

  factory TechnicianTicket.fromJson(Map<String, dynamic> json) {
    return TechnicianTicket(
      idTicket: json['idTicket'] as int? ?? 0,
      ticket: json['ticket'] as String? ?? '',
      contactName: json['contactName'] as String?,
      ctype: json['ctype'] as String?,
      serviceNo: json['serviceNo'] as String?,
      reportedDate: json['reportedDate'] as String?,
      hasilVisit: json['hasilVisit'] as String?,
      age: json['age'] as String?,
      ageHours: (json['ageHours'] as num?)?.toDouble(),
      closedAt: json['closedAt'] as String?,
    );
  }
}

class TechnicianOrderCounts {
  final int assigned;
  final int onProgress;
  final int pending;
  final int closed;

  TechnicianOrderCounts({
    this.assigned = 0,
    this.onProgress = 0,
    this.pending = 0,
    this.closed = 0,
  });

  factory TechnicianOrderCounts.fromJson(Map<String, dynamic> json) {
    return TechnicianOrderCounts(
      assigned: json['assigned'] as int? ?? 0,
      onProgress: json['on_progress'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      closed: json['closed'] as int? ?? 0,
    );
  }
}

class TechnicianSummary {
  final int totalActive;
  final int totalAssigned;
  final int overloadCount;
  final int idleCount;

  TechnicianSummary({
    this.totalActive = 0,
    this.totalAssigned = 0,
    this.overloadCount = 0,
    this.idleCount = 0,
  });

  factory TechnicianSummary.fromJson(Map<String, dynamic> json) {
    return TechnicianSummary(
      totalActive: json['total_active'] as int? ?? 0,
      totalAssigned: json['total_assigned'] as int? ?? 0,
      overloadCount: json['overload_count'] as int? ?? 0,
      idleCount: json['idle_count'] as int? ?? 0,
    );
  }
}
