class User {
  final int idUser;
  final String? nik;
  final String? nama;
  final String? jabatan;
  final String? username;
  final int? roleId;
  final String? roleName;
  final int? areaId;

  User({
    required this.idUser,
    this.nik,
    this.nama,
    this.jabatan,
    this.username,
    this.roleId,
    this.roleName,
    this.areaId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser: json['id_user'] as int? ?? json['idUser'] as int? ?? 0,
      nik: json['nik'] as String?,
      nama: json['nama'] as String?,
      jabatan: json['jabatan'] as String?,
      username: json['username'] as String?,
      roleId: json['role_id'] as int? ?? json['roleId'] as int?,
      roleName: json['role_name'] as String? ?? json['roleName'] as String?,
      areaId: json['area_id'] as int? ?? json['areaId'] as int?,
    );
  }
}

class ServiceArea {
  final int idSa;
  final String? namaSa;
  final int? areaId;

  ServiceArea({
    required this.idSa,
    this.namaSa,
    this.areaId,
  });

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      idSa: json['id_sa'] as int? ?? json['idSa'] as int? ?? 0,
      namaSa: json['nama_sa'] as String? ?? json['namaSa'] as String?,
      areaId: json['area_id'] as int? ?? json['areaId'] as int?,
    );
  }
}
