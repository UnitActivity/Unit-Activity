class AbsenPertemuanModel {
  final String? idAbsenP;
  final int? nim;
  final String? status;
  final String? jam;
  final String? hash;
  final String? qrCode;
  final DateTime? createAt;
  final DateTime? updateAt;
  final String? idUser;
  final String? idPertemuan;

  AbsenPertemuanModel({
    this.idAbsenP,
    this.nim,
    this.status,
    this.jam,
    this.hash,
    this.qrCode,
    this.createAt,
    this.updateAt,
    this.idUser,
    this.idPertemuan,
  });

  factory AbsenPertemuanModel.fromJson(Map<String, dynamic> json) {
    return AbsenPertemuanModel(
      idAbsenP: json['id_absen_p'],
      nim: json['nim'],
      status: json['status'],
      jam: json['jam'],
      hash: json['hash'],
      qrCode: json['qr_code'],
      createAt: json['create_at'] != null 
          ? DateTime.parse(json['create_at']) 
          : null,
      updateAt: json['update_at'] != null 
          ? DateTime.parse(json['update_at']) 
          : null,
      idUser: json['id_user'],
      idPertemuan: json['id_pertemuan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_absen_p': idAbsenP,
      'nim': nim,
      'status': status,
      'jam': jam,
      'hash': hash,
      'qr_code': qrCode,
      'id_user': idUser,
      'id_pertemuan': idPertemuan,
    };
  }
}
