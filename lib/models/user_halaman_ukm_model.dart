class UserHalamanUkmModel {
  final String? idFollow;
  final DateTime? follow;
  final DateTime? unfollow;
  final String? status;
  final String? mediaSosial;
  final String? logbook;
  final String? deskripsi;
  final String? unfollowReason;
  final String? idUkm;
  final String? idUser;
  final String? idPeriode;
  final DateTime? createdAt;

  UserHalamanUkmModel({
    this.idFollow,
    this.follow,
    this.unfollow,
    this.status,
    this.mediaSosial,
    this.logbook,
    this.deskripsi,
    this.unfollowReason,
    this.idUkm,
    this.idUser,
    this.idPeriode,
    this.createdAt,
  });

  factory UserHalamanUkmModel.fromJson(Map<String, dynamic> json) {
    return UserHalamanUkmModel(
      idFollow: json['id_follow'],
      follow: json['follow'] != null 
          ? DateTime.parse(json['follow']) 
          : null,
      unfollow: json['unfollow'] != null 
          ? DateTime.parse(json['unfollow']) 
          : null,
      status: json['status'],
      mediaSosial: json['media_sosial'],
      logbook: json['logbook'],
      deskripsi: json['deskripsi'],
      unfollowReason: json['unfollow_reason'],
      idUkm: json['id_ukm'],
      idUser: json['id_user'],
      idPeriode: json['id_periode'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_follow': idFollow,
      'follow': follow?.toIso8601String(),
      'unfollow': unfollow?.toIso8601String(),
      'status': status,
      'media_sosial': mediaSosial,
      'logbook': logbook,
      'deskripsi': deskripsi,
      'unfollow_reason': unfollowReason,
      'id_ukm': idUkm,
      'id_user': idUser,
      'id_periode': idPeriode,
    };
  }
}
