class AbsenEventModel {
  final String? idAbsenE;
  final int? nim;
  final String? status;
  final String? jam;
  final String? hash;
  final String? qrCode;
  final DateTime? createAt;
  final DateTime? updateAt;
  final String? idUser;
  final String? idEvent;

  AbsenEventModel({
    this.idAbsenE,
    this.nim,
    this.status,
    this.jam,
    this.hash,
    this.qrCode,
    this.createAt,
    this.updateAt,
    this.idUser,
    this.idEvent,
  });

  factory AbsenEventModel.fromJson(Map<String, dynamic> json) {
    return AbsenEventModel(
      idAbsenE: json['id_absen_e'],
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
      idEvent: json['id_event'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_absen_e': idAbsenE,
      'nim': nim,
      'status': status,
      'jam': jam,
      'hash': hash,
      'qr_code': qrCode,
      'id_user': idUser,
      'id_event': idEvent,
    };
  }
}
