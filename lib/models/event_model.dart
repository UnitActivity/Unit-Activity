class EventModel {
  final String? idEvents;
  final String namaEvent;
  final String? deskripsi;
  final DateTime? tanggalMulai;
  final DateTime? tanggalPendaftaran;
  final DateTime? tanggalAkhir;
  final String? lokasi;
  final String? jamMulai;
  final String? jamAkhir;
  final String? jamPertemuan;
  final int? anggotaPartisipasi;
  final int? maxParticipant;
  final String? tipevent;
  final String? qrCode;
  final String? qrTime;
  final String? logbook;
  final DateTime? createAt;
  final DateTime? updateAt;
  final bool? status;
  final String? idUkm;
  final String? idPeriode;
  final String? idUser;
  final String? statusProposal;
  final String? statusLpj;

  EventModel({
    this.idEvents,
    required this.namaEvent,
    this.deskripsi,
    this.tanggalMulai,
    this.tanggalPendaftaran,
    this.tanggalAkhir,
    this.lokasi,
    this.jamMulai,
    this.jamAkhir,
    this.jamPertemuan,
    this.anggotaPartisipasi,
    this.maxParticipant,
    this.tipevent,
    this.qrCode,
    this.qrTime,
    this.logbook,
    this.createAt,
    this.updateAt,
    this.status,
    this.idUkm,
    this.idPeriode,
    this.idUser,
    this.statusProposal,
    this.statusLpj,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      idEvents: json['id_events'],
      namaEvent: json['nama_event'] ?? '',
      deskripsi: json['deskripsi'],
      tanggalMulai: json['tanggal_mulai'] != null 
          ? DateTime.parse(json['tanggal_mulai']) 
          : null,
      tanggalPendaftaran: json['tanggal_pendaftaran'] != null 
          ? DateTime.parse(json['tanggal_pendaftaran']) 
          : null,
      tanggalAkhir: json['tanggal_akhir'] != null 
          ? DateTime.parse(json['tanggal_akhir']) 
          : null,
      lokasi: json['lokasi'],
      jamMulai: json['jam_mulai'],
      jamAkhir: json['jam_akhir'],
      jamPertemuan: json['jam_pertemuan'],
      anggotaPartisipasi: json['anggota_partisipasi'],
      maxParticipant: json['max_participant'],
      tipevent: json['tipevent'],
      qrCode: json['qr_code'],
      qrTime: json['qr_time'],
      logbook: json['logbook'],
      createAt: json['create_at'] != null 
          ? DateTime.parse(json['create_at']) 
          : null,
      updateAt: json['update_at'] != null 
          ? DateTime.parse(json['update_at']) 
          : null,
      status: json['status'],
      idUkm: json['id_ukm'],
      idPeriode: json['id_periode'],
      idUser: json['id_user'],
      statusProposal: json['status_proposal'],
      statusLpj: json['status_lpj'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (idEvents != null) json['id_events'] = idEvents;
    json['nama_event'] = namaEvent;
    if (deskripsi != null) json['deskripsi'] = deskripsi;
    if (tanggalMulai != null) json['tanggal_mulai'] = tanggalMulai!.toIso8601String();
    if (tanggalPendaftaran != null) json['tanggal_pendaftaran'] = tanggalPendaftaran!.toIso8601String();
    if (tanggalAkhir != null) json['tanggal_akhir'] = tanggalAkhir!.toIso8601String();
    if (lokasi != null) json['lokasi'] = lokasi;
    if (jamMulai != null) json['jam_mulai'] = jamMulai;
    if (jamAkhir != null) json['jam_akhir'] = jamAkhir;
    if (jamPertemuan != null) json['jam_pertemuan'] = jamPertemuan;
    if (anggotaPartisipasi != null) json['anggota_partisipasi'] = anggotaPartisipasi;
    if (maxParticipant != null) json['max_participant'] = maxParticipant;
    if (tipevent != null) json['tipevent'] = tipevent;
    if (qrCode != null) json['qr_code'] = qrCode;
    if (qrTime != null) json['qr_time'] = qrTime;
    if (logbook != null) json['logbook'] = logbook;
    if (status != null) json['status'] = status;
    if (idUkm != null) json['id_ukm'] = idUkm;
    if (idPeriode != null) json['id_periode'] = idPeriode;
    if (idUser != null) json['id_user'] = idUser;
    if (statusProposal != null) json['status_proposal'] = statusProposal;
    if (statusLpj != null) json['status_lpj'] = statusLpj;
    
    return json;
  }
}
