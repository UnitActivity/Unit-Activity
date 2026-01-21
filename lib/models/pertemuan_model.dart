class PertemuanModel {
  final String? idPertemuan;
  final String? topik;
  final String? tipe;
  final DateTime? tanggal;
  final String? waktu;
  final String? jamMulai;
  final String? jamAkhir;
  final String? jamPertemuan;
  final DateTime? tanggalPertemuan;
  final String? lokasi;
  final String? qrCode;
  final String? qrTime;
  final DateTime? createAt;
  final DateTime? updateAt;
  final String? idUkm;
  final String? idPeriode;

  PertemuanModel({
    this.idPertemuan,
    this.topik,
    this.tipe,
    this.tanggal,
    this.waktu,
    this.jamMulai,
    this.jamAkhir,
    this.jamPertemuan,
    this.tanggalPertemuan,
    this.lokasi,
    this.qrCode,
    this.qrTime,
    this.createAt,
    this.updateAt,
    this.idUkm,
    this.idPeriode,
  });

  factory PertemuanModel.fromJson(Map<String, dynamic> json) {
    return PertemuanModel(
      idPertemuan: json['id_pertemuan'],
      topik: json['topik'],
      tipe: json['tipe'],
      tanggal: json['tanggal'] != null ? DateTime.parse(json['tanggal']) : null,
      waktu: json['waktu'],
      jamMulai: json['jam_mulai'],
      jamAkhir: json['jam_akhir'],
      jamPertemuan: json['jam_pertemuan'],
      tanggalPertemuan: json['tanggal_pertemuan'] != null 
          ? DateTime.parse(json['tanggal_pertemuan']) 
          : null,
      lokasi: json['lokasi'],
      qrCode: json['qr_code'],
      qrTime: json['qr_time'],
      createAt: json['create_at'] != null 
          ? DateTime.parse(json['create_at']) 
          : null,
      updateAt: json['update_at'] != null 
          ? DateTime.parse(json['update_at']) 
          : null,
      idUkm: json['id_ukm'],
      idPeriode: json['id_periode'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (idPertemuan != null) json['id_pertemuan'] = idPertemuan;
    if (topik != null) json['topik'] = topik;
    if (tipe != null) json['tipe'] = tipe;
    if (tanggal != null) json['tanggal'] = tanggal!.toIso8601String();
    if (waktu != null) json['waktu'] = waktu;
    if (jamMulai != null) json['jam_mulai'] = jamMulai;
    if (jamAkhir != null) json['jam_akhir'] = jamAkhir;
    if (jamPertemuan != null) json['jam_pertemuan'] = jamPertemuan;
    if (tanggalPertemuan != null) json['tanggal_pertemuan'] = tanggalPertemuan!.toIso8601String();
    if (lokasi != null) json['lokasi'] = lokasi;
    if (qrCode != null) json['qr_code'] = qrCode;
    if (qrTime != null) json['qr_time'] = qrTime;
    if (idUkm != null) json['id_ukm'] = idUkm;
    if (idPeriode != null) json['id_periode'] = idPeriode;
    
    return json;
  }
}
