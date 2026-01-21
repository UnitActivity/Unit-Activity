class InformasiModel {
  final String? idInformasi;
  final String judul;
  final String? deskripsi;
  final String? gambar;
  final String? status;
  final DateTime? objek;
  final DateTime? dond;
  final String? createBy;
  final DateTime? createAt;
  final DateTime? updateAt;
  final bool? statusAktif;
  final String? idUkm;
  final String? idPeriode;
  final String? idUser;

  InformasiModel({
    this.idInformasi,
    required this.judul,
    this.deskripsi,
    this.gambar,
    this.status,
    this.objek,
    this.dond,
    this.createBy,
    this.createAt,
    this.updateAt,
    this.statusAktif,
    this.idUkm,
    this.idPeriode,
    this.idUser,
  });

  factory InformasiModel.fromJson(Map<String, dynamic> json) {
    return InformasiModel(
      idInformasi: json['id_informasi'],
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'],
      gambar: json['gambar'],
      status: json['status'],
      objek: json['objek'] != null 
          ? DateTime.parse(json['objek']) 
          : null,
      dond: json['dond'] != null 
          ? DateTime.parse(json['dond']) 
          : null,
      createBy: json['create_by'],
      createAt: json['create_at'] != null 
          ? DateTime.parse(json['create_at']) 
          : null,
      updateAt: json['update_at'] != null 
          ? DateTime.parse(json['update_at']) 
          : null,
      statusAktif: json['status_aktif'],
      idUkm: json['id_ukm'],
      idPeriode: json['id_periode'],
      idUser: json['id_user'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (idInformasi != null) json['id_informasi'] = idInformasi;
    json['judul'] = judul;
    if (deskripsi != null) json['deskripsi'] = deskripsi;
    if (gambar != null) json['gambar'] = gambar;
    if (status != null) json['status'] = status;
    if (objek != null) json['objek'] = objek!.toIso8601String();
    if (dond != null) json['dond'] = dond!.toIso8601String();
    if (createBy != null) json['create_by'] = createBy;
    if (statusAktif != null) json['status_aktif'] = statusAktif;
    if (idUkm != null) json['id_ukm'] = idUkm;
    if (idPeriode != null) json['id_periode'] = idPeriode;
    if (idUser != null) json['id_user'] = idUser;
    
    return json;
  }
}
