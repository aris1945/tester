class Ticket {
  final int idTicket;
  final String ticket;
  final String? summary;
  final String? reportedDate;
  final String? ownerGroup;
  final String? serviceType;
  final String? customerType;
  final String? ctype;
  final String? customerSegment;
  final String? serviceNo;
  final String? contactName;
  final String? contactPhone;
  final String? deviceName;
  final String? symptom;
  final String? workzone;
  final String? alamat;
  final String? status;
  final String? statusUpdate;
  final String? hasilVisit;
  final String? bookingDate;
  final String? sourceTicket;
  final String? jenisTiket;
  final String? maxTtrReguler;
  final String? maxTtrGold;
  final String? maxTtrPlatinum;
  final String? maxTtrDiamond;
  final String? flaggingManja;
  final String? guaranteeStatus;
  final String? pendingReason;
  final String? rca;
  final String? subRca;
  final String? descriptionActualSolution;
  final int? teknisiUserId;
  final String? technicianName;
  final String? closedAt;
  final String? syncDate;

  Ticket({
    required this.idTicket,
    required this.ticket,
    this.summary,
    this.reportedDate,
    this.ownerGroup,
    this.serviceType,
    this.customerType,
    this.ctype,
    this.customerSegment,
    this.serviceNo,
    this.contactName,
    this.contactPhone,
    this.deviceName,
    this.symptom,
    this.workzone,
    this.alamat,
    this.status,
    this.statusUpdate,
    this.hasilVisit,
    this.bookingDate,
    this.sourceTicket,
    this.jenisTiket,
    this.maxTtrReguler,
    this.maxTtrGold,
    this.maxTtrPlatinum,
    this.maxTtrDiamond,
    this.flaggingManja,
    this.guaranteeStatus,
    this.pendingReason,
    this.rca,
    this.subRca,
    this.descriptionActualSolution,
    this.teknisiUserId,
    this.technicianName,
    this.closedAt,
    this.syncDate,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      idTicket: json['idTicket'] as int? ?? 0,
      ticket: json['ticket'] as String? ?? '',
      summary: json['summary'] as String?,
      reportedDate: json['reportedDate'] as String?,
      ownerGroup: json['ownerGroup'] as String?,
      serviceType: json['serviceType'] as String?,
      customerType: json['customerType'] as String?,
      ctype: json['ctype'] as String?,
      customerSegment: json['customerSegment'] as String?,
      serviceNo: json['serviceNo'] as String?,
      contactName: json['contactName'] as String?,
      contactPhone: json['contactPhone'] as String?,
      deviceName: json['deviceName'] as String?,
      symptom: json['symptom'] as String?,
      workzone: json['workzone'] as String?,
      alamat: json['alamat'] as String?,
      status: json['status'] as String?,
      statusUpdate: json['STATUS_UPDATE'] as String?,
      hasilVisit: json['hasilVisit'] as String?,
      bookingDate: json['bookingDate'] as String?,
      sourceTicket: json['sourceTicket'] as String?,
      jenisTiket: json['jenisTiket'] as String?,
      maxTtrReguler: json['maxTtrReguler'] as String?,
      maxTtrGold: json['maxTtrGold'] as String?,
      maxTtrPlatinum: json['maxTtrPlatinum'] as String?,
      maxTtrDiamond: json['maxTtrDiamond'] as String?,
      flaggingManja: json['flaggingManja'] as String?,
      guaranteeStatus: json['guaranteeStatus'] as String?,
      pendingReason: json['pendingReason'] as String?,
      rca: json['rca'] as String?,
      subRca: json['subRca'] as String?,
      descriptionActualSolution: json['descriptionActualSolution'] as String?,
      teknisiUserId: json['teknisiUserId'] as int?,
      technicianName: json['technicianName'] as String?,
      closedAt: json['closedAt'] as String?,
      syncDate: json['syncDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTicket': idTicket,
      'ticket': ticket,
      'summary': summary,
      'reportedDate': reportedDate,
      'ownerGroup': ownerGroup,
      'serviceType': serviceType,
      'customerType': customerType,
      'ctype': ctype,
      'customerSegment': customerSegment,
      'serviceNo': serviceNo,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'deviceName': deviceName,
      'symptom': symptom,
      'workzone': workzone,
      'alamat': alamat,
      'status': status,
      'STATUS_UPDATE': statusUpdate,
      'hasilVisit': hasilVisit,
      'bookingDate': bookingDate,
      'sourceTicket': sourceTicket,
      'jenisTiket': jenisTiket,
      'flaggingManja': flaggingManja,
      'guaranteeStatus': guaranteeStatus,
      'pendingReason': pendingReason,
      'rca': rca,
      'subRca': subRca,
      'descriptionActualSolution': descriptionActualSolution,
      'teknisiUserId': teknisiUserId,
      'technicianName': technicianName,
      'closedAt': closedAt,
    };
  }

  /// Effective status for display
  String get effectiveStatus {
    if (statusUpdate != null && statusUpdate!.isNotEmpty) {
      return statusUpdate!.toUpperCase();
    }
    if (hasilVisit != null && hasilVisit!.isNotEmpty) {
      return hasilVisit!.toUpperCase();
    }
    return (status ?? 'OPEN').toUpperCase();
  }
}

/// Customer type display info
class CustomerTypeInfo {
  final String label;
  final String icon;

  const CustomerTypeInfo(this.label, this.icon);

  static const Map<String, CustomerTypeInfo> types = {
    'REGULER': CustomerTypeInfo('Reguler', '👤'),
    'HVC_GOLD': CustomerTypeInfo('HVC Gold', '🥇'),
    'HVC_PLATINUM': CustomerTypeInfo('HVC Platinum', '💎'),
    'HVC_DIAMOND': CustomerTypeInfo('HVC Diamond', '💠'),
  };

  static CustomerTypeInfo get(String? ctype) {
    if (ctype == null) return const CustomerTypeInfo('Unknown', '❓');
    return types[ctype.toUpperCase()] ??
        const CustomerTypeInfo('Unknown', '❓');
  }
}
