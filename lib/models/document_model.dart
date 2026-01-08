// ============================================================================
// UNIFIED DOCUMENT MODEL
// Menggabungkan DocumentProposal dan DocumentLPJ menjadi 1 class
// ============================================================================

class EventDocument {
  final String idDocument;
  final String documentType; // 'proposal' atau 'lpj'
  final String idEvent;
  final String idUkm;
  final String idUser;

  // Proposal fields (digunakan ketika documentType = 'proposal')
  final String? fileProposal;
  final String? originalFilenameProposal;
  final int? fileSizeProposal;

  // LPJ fields (digunakan ketika documentType = 'lpj')
  final String? fileLaporan;
  final String? fileKeuangan;
  final String? originalFilenameLaporan;
  final String? originalFilenameKeuangan;
  final int? fileSizeLaporan;
  final int? fileSizeKeuangan;

  // Common fields
  final String? catatanAdmin;
  final String status; // menunggu, disetujui, ditolak, revisi
  final DateTime tanggalPengajuan;
  final DateTime? tanggalDitinjau;
  final String? adminYangMeninjau;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final Map<String, dynamic>? event;
  final Map<String, dynamic>? ukm;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? admin;

  EventDocument({
    required this.idDocument,
    required this.documentType,
    required this.idEvent,
    required this.idUkm,
    required this.idUser,
    this.fileProposal,
    this.originalFilenameProposal,
    this.fileSizeProposal,
    this.fileLaporan,
    this.fileKeuangan,
    this.originalFilenameLaporan,
    this.originalFilenameKeuangan,
    this.fileSizeLaporan,
    this.fileSizeKeuangan,
    this.catatanAdmin,
    required this.status,
    required this.tanggalPengajuan,
    this.tanggalDitinjau,
    this.adminYangMeninjau,
    required this.createdAt,
    required this.updatedAt,
    this.event,
    this.ukm,
    this.user,
    this.admin,
  });

  factory EventDocument.fromJson(Map<String, dynamic> json) {
    return EventDocument(
      idDocument: json['id_document']?.toString() ?? '',
      documentType: json['document_type'] as String? ?? 'proposal',
      idEvent: json['id_event']?.toString() ?? '',
      idUkm: json['id_ukm']?.toString() ?? '',
      idUser: json['id_user']?.toString() ?? '',
      fileProposal: json['file_proposal'] as String?,
      originalFilenameProposal: json['original_filename_proposal'] as String?,
      fileSizeProposal: json['file_size_proposal'] as int?,
      fileLaporan: json['file_laporan'] as String?,
      fileKeuangan: json['file_keuangan'] as String?,
      originalFilenameLaporan: json['original_filename_laporan'] as String?,
      originalFilenameKeuangan: json['original_filename_keuangan'] as String?,
      fileSizeLaporan: json['file_size_laporan'] as int?,
      fileSizeKeuangan: json['file_size_keuangan'] as int?,
      catatanAdmin: json['catatan_admin'] as String?,
      status: json['status'] as String? ?? 'menunggu',
      tanggalPengajuan: DateTime.parse(json['tanggal_pengajuan'] as String),
      tanggalDitinjau: json['tanggal_ditinjau'] != null
          ? DateTime.parse(json['tanggal_ditinjau'] as String)
          : null,
      adminYangMeninjau: json['admin_yang_meninjau'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      event: json['events'] as Map<String, dynamic>?,
      ukm: json['ukm'] as Map<String, dynamic>?,
      user: json['users'] as Map<String, dynamic>?,
      admin: json['admin'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_document': idDocument,
      'document_type': documentType,
      'id_event': idEvent,
      'id_ukm': idUkm,
      'id_user': idUser,
      'file_proposal': fileProposal,
      'original_filename_proposal': originalFilenameProposal,
      'file_size_proposal': fileSizeProposal,
      'file_laporan': fileLaporan,
      'file_keuangan': fileKeuangan,
      'original_filename_laporan': originalFilenameLaporan,
      'original_filename_keuangan': originalFilenameKeuangan,
      'file_size_laporan': fileSizeLaporan,
      'file_size_keuangan': fileSizeKeuangan,
      'catatan_admin': catatanAdmin,
      'status': status,
      'tanggal_pengajuan': tanggalPengajuan.toIso8601String(),
      'tanggal_ditinjau': tanggalDitinjau?.toIso8601String(),
      'admin_yang_meninjau': adminYangMeninjau,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isProposal => documentType == 'proposal';
  bool get isLPJ => documentType == 'lpj';

  String getPrimaryFile() {
    if (isProposal) return fileProposal ?? '';
    return fileLaporan ?? '';
  }

  String? getOriginalFilename() {
    if (isProposal) return originalFilenameProposal;
    return originalFilenameLaporan;
  }

  int? getFileSize() {
    if (isProposal) return fileSizeProposal;
    return fileSizeLaporan;
  }

  String getStatusLabel() {
    switch (status) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'revisi':
        return 'Perlu Revisi';
      default:
        return 'Menunggu Review';
    }
  }

  String getEventName() => event?['nama_event'] as String? ?? 'Event';
  String getUkmName() => ukm?['nama_ukm'] as String? ?? 'UKM';
  String getUserName() => user?['username'] as String? ?? 'User';
  String? getAdminName() => admin?['username_admin'] as String?;
}

// ============================================================================
// LEGACY CLASSES - Untuk backward compatibility
// ============================================================================

class DocumentProposal {
  final String idProposal;
  final String idEvent;
  final String idUkm;
  final String idUser;
  final String fileProposal;
  final String? originalFilename;
  final int? fileSize;
  final String? catatanAdmin;
  final String status;
  final DateTime tanggalPengajuan;
  final DateTime? tanggalDitinjau;
  final String? adminYangMeninjau;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? event;
  final Map<String, dynamic>? ukm;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? admin;

  DocumentProposal({
    required this.idProposal,
    required this.idEvent,
    required this.idUkm,
    required this.idUser,
    required this.fileProposal,
    this.originalFilename,
    this.fileSize,
    this.catatanAdmin,
    required this.status,
    required this.tanggalPengajuan,
    this.tanggalDitinjau,
    this.adminYangMeninjau,
    required this.createdAt,
    required this.updatedAt,
    this.event,
    this.ukm,
    this.user,
    this.admin,
  });

  // Convert from EventDocument
  factory DocumentProposal.fromEventDocument(EventDocument doc) {
    return DocumentProposal(
      idProposal: doc.idDocument,
      idEvent: doc.idEvent,
      idUkm: doc.idUkm,
      idUser: doc.idUser,
      fileProposal: doc.fileProposal ?? '',
      originalFilename: doc.originalFilenameProposal,
      fileSize: doc.fileSizeProposal,
      catatanAdmin: doc.catatanAdmin,
      status: doc.status,
      tanggalPengajuan: doc.tanggalPengajuan,
      tanggalDitinjau: doc.tanggalDitinjau,
      adminYangMeninjau: doc.adminYangMeninjau,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      event: doc.event,
      ukm: doc.ukm,
      user: doc.user,
      admin: doc.admin,
    );
  }

  factory DocumentProposal.fromJson(Map<String, dynamic> json) {
    return DocumentProposal(
      idProposal:
          json['id_proposal']?.toString() ??
          json['id_document']?.toString() ??
          '',
      idEvent: json['id_event']?.toString() ?? '',
      idUkm: json['id_ukm']?.toString() ?? '',
      idUser: json['id_user']?.toString() ?? '',
      fileProposal: json['file_proposal']?.toString() ?? '',
      originalFilename:
          json['original_filename'] as String? ??
          json['original_filename_proposal'] as String?,
      fileSize: json['file_size'] as int? ?? json['file_size_proposal'] as int?,
      catatanAdmin: json['catatan_admin'] as String?,
      status: json['status'] as String? ?? 'menunggu',
      tanggalPengajuan: DateTime.parse(json['tanggal_pengajuan'] as String),
      tanggalDitinjau: json['tanggal_ditinjau'] != null
          ? DateTime.parse(json['tanggal_ditinjau'] as String)
          : null,
      adminYangMeninjau: json['admin_yang_meninjau'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      event: json['events'] as Map<String, dynamic>?,
      ukm: json['ukm'] as Map<String, dynamic>?,
      user: json['users'] as Map<String, dynamic>?,
      admin: json['admin'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_proposal': idProposal,
      'id_event': idEvent,
      'id_ukm': idUkm,
      'id_user': idUser,
      'file_proposal': fileProposal,
      'original_filename': originalFilename,
      'file_size': fileSize,
      'catatan_admin': catatanAdmin,
      'status': status,
      'tanggal_pengajuan': tanggalPengajuan.toIso8601String(),
      'tanggal_ditinjau': tanggalDitinjau?.toIso8601String(),
      'admin_yang_meninjau': adminYangMeninjau,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String getStatusLabel() {
    switch (status) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'revisi':
        return 'Perlu Revisi';
      default:
        return 'Menunggu Review';
    }
  }

  String getEventName() => event?['nama_event'] as String? ?? 'Event';
  String getUkmName() => ukm?['nama_ukm'] as String? ?? 'UKM';
  String getUserName() => user?['username'] as String? ?? 'User';
  String? getAdminName() => admin?['username_admin'] as String?;
}

class DocumentLPJ {
  final String idLpj;
  final String idEvent;
  final String idUkm;
  final String idUser;
  final String fileLaporan;
  final String fileKeuangan;
  final String? originalFilenameLaporan;
  final String? originalFilenameKeuangan;
  final int? fileSizeLaporan;
  final int? fileSizeKeuangan;
  final String? catatanAdmin;
  final String status;
  final DateTime tanggalPengajuan;
  final DateTime? tanggalDitinjau;
  final String? adminYangMeninjau;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? event;
  final Map<String, dynamic>? ukm;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? admin;

  DocumentLPJ({
    required this.idLpj,
    required this.idEvent,
    required this.idUkm,
    required this.idUser,
    required this.fileLaporan,
    required this.fileKeuangan,
    this.originalFilenameLaporan,
    this.originalFilenameKeuangan,
    this.fileSizeLaporan,
    this.fileSizeKeuangan,
    this.catatanAdmin,
    required this.status,
    required this.tanggalPengajuan,
    this.tanggalDitinjau,
    this.adminYangMeninjau,
    required this.createdAt,
    required this.updatedAt,
    this.event,
    this.ukm,
    this.user,
    this.admin,
  });

  // Convert from EventDocument
  factory DocumentLPJ.fromEventDocument(EventDocument doc) {
    return DocumentLPJ(
      idLpj: doc.idDocument,
      idEvent: doc.idEvent,
      idUkm: doc.idUkm,
      idUser: doc.idUser,
      fileLaporan: doc.fileLaporan ?? '',
      fileKeuangan: doc.fileKeuangan ?? '',
      originalFilenameLaporan: doc.originalFilenameLaporan,
      originalFilenameKeuangan: doc.originalFilenameKeuangan,
      fileSizeLaporan: doc.fileSizeLaporan,
      fileSizeKeuangan: doc.fileSizeKeuangan,
      catatanAdmin: doc.catatanAdmin,
      status: doc.status,
      tanggalPengajuan: doc.tanggalPengajuan,
      tanggalDitinjau: doc.tanggalDitinjau,
      adminYangMeninjau: doc.adminYangMeninjau,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      event: doc.event,
      ukm: doc.ukm,
      user: doc.user,
      admin: doc.admin,
    );
  }

  factory DocumentLPJ.fromJson(Map<String, dynamic> json) {
    return DocumentLPJ(
      idLpj:
          json['id_lpj']?.toString() ?? json['id_document']?.toString() ?? '',
      idEvent: json['id_event']?.toString() ?? '',
      idUkm: json['id_ukm']?.toString() ?? '',
      idUser: json['id_user']?.toString() ?? '',
      fileLaporan: json['file_laporan']?.toString() ?? '',
      fileKeuangan: json['file_keuangan']?.toString() ?? '',
      originalFilenameLaporan: json['original_filename_laporan'] as String?,
      originalFilenameKeuangan: json['original_filename_keuangan'] as String?,
      fileSizeLaporan: json['file_size_laporan'] as int?,
      fileSizeKeuangan: json['file_size_keuangan'] as int?,
      catatanAdmin: json['catatan_admin'] as String?,
      status: json['status'] as String? ?? 'menunggu',
      tanggalPengajuan: DateTime.parse(json['tanggal_pengajuan'] as String),
      tanggalDitinjau: json['tanggal_ditinjau'] != null
          ? DateTime.parse(json['tanggal_ditinjau'] as String)
          : null,
      adminYangMeninjau: json['admin_yang_meninjau'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      event: json['events'] as Map<String, dynamic>?,
      ukm: json['ukm'] as Map<String, dynamic>?,
      user: json['users'] as Map<String, dynamic>?,
      admin: json['admin'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_lpj': idLpj,
      'id_event': idEvent,
      'id_ukm': idUkm,
      'id_user': idUser,
      'file_laporan': fileLaporan,
      'file_keuangan': fileKeuangan,
      'original_filename_laporan': originalFilenameLaporan,
      'original_filename_keuangan': originalFilenameKeuangan,
      'file_size_laporan': fileSizeLaporan,
      'file_size_keuangan': fileSizeKeuangan,
      'catatan_admin': catatanAdmin,
      'status': status,
      'tanggal_pengajuan': tanggalPengajuan.toIso8601String(),
      'tanggal_ditinjau': tanggalDitinjau?.toIso8601String(),
      'admin_yang_meninjau': adminYangMeninjau,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String getStatusLabel() {
    switch (status) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'revisi':
        return 'Perlu Revisi';
      default:
        return 'Menunggu Review';
    }
  }

  String getEventName() => event?['nama_event'] as String? ?? 'Event';
  String getUkmName() => ukm?['nama_ukm'] as String? ?? 'UKM';
  String getUserName() => user?['username'] as String? ?? 'User';
  String? getAdminName() => admin?['username_admin'] as String?;
}

class DocumentRevision {
  final String idRevision;
  final String documentType; // 'proposal' or 'lpj'
  final String documentId;
  final String? idUser;
  final String? idAdmin;
  final String? catatan;
  final String? fileSebelumnya;
  final String? fileBaru;
  final String? statusSebelumnya;
  final String? statusSetelahnya;
  final DateTime createdAt;

  // Related data
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? admin;

  DocumentRevision({
    required this.idRevision,
    required this.documentType,
    required this.documentId,
    this.idUser,
    this.idAdmin,
    this.catatan,
    this.fileSebelumnya,
    this.fileBaru,
    this.statusSebelumnya,
    this.statusSetelahnya,
    required this.createdAt,
    this.user,
    this.admin,
  });

  factory DocumentRevision.fromJson(Map<String, dynamic> json) {
    return DocumentRevision(
      idRevision: json['id_revision']?.toString() ?? '',
      documentType: json['document_type']?.toString() ?? '',
      documentId: json['document_id']?.toString() ?? '',
      idUser: json['id_user'] as String?,
      idAdmin: json['id_admin'] as String?,
      catatan: json['catatan'] as String?,
      fileSebelumnya: json['file_sebelumnya'] as String?,
      fileBaru: json['file_baru'] as String?,
      statusSebelumnya: json['status_sebelumnya'] as String?,
      statusSetelahnya: json['status_setelahnya'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['users'] as Map<String, dynamic>?,
      admin: json['admin'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_revision': idRevision,
      'document_type': documentType,
      'document_id': documentId,
      'id_user': idUser,
      'id_admin': idAdmin,
      'catatan': catatan,
      'file_sebelumnya': fileSebelumnya,
      'file_baru': fileBaru,
      'status_sebelumnya': statusSebelumnya,
      'status_setelahnya': statusSetelahnya,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getAuthorName() {
    if (admin != null) {
      return admin!['username_admin'] as String? ?? 'Admin';
    } else if (user != null) {
      return user!['username'] as String? ?? 'User';
    }
    return 'Unknown';
  }

  String getStatusChangeText() {
    if (statusSebelumnya != null && statusSetelahnya != null) {
      return 'Status diubah dari "$statusSebelumnya" ke "$statusSetelahnya"';
    }
    return 'Revisi dokumen';
  }
}

class DocumentComment {
  final String idComment;
  final String documentType; // 'proposal' or 'lpj'
  final String documentId;
  final String? idAdmin;
  final String? idUser; // For regular user comments
  final String? idUkm; // For UKM comments
  final String comment;
  final bool isStatusChange;
  final String? statusFrom;
  final String? statusTo;
  final DateTime createdAt;

  // Related data
  final Map<String, dynamic>? admin;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? ukm;

  DocumentComment({
    required this.idComment,
    required this.documentType,
    required this.documentId,
    this.idAdmin,
    this.idUser,
    this.idUkm,
    required this.comment,
    required this.isStatusChange,
    this.statusFrom,
    this.statusTo,
    required this.createdAt,
    this.admin,
    this.user,
    this.ukm,
  });

  factory DocumentComment.fromJson(Map<String, dynamic> json) {
    return DocumentComment(
      idComment: json['id_comment']?.toString() ?? '',
      documentType: json['document_type']?.toString() ?? '',
      documentId: json['document_id']?.toString() ?? '',
      idAdmin: json['id_admin'] as String?,
      idUser: json['id_user'] as String?,
      idUkm: json['id_ukm'] as String?,
      comment: json['comment']?.toString() ?? '',
      isStatusChange: json['is_status_change'] as bool? ?? false,
      statusFrom: json['status_from'] as String?,
      statusTo: json['status_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      admin: json['admin'] as Map<String, dynamic>?,
      user: json['users'] as Map<String, dynamic>?,
      ukm: json['ukm'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_comment': idComment,
      'document_type': documentType,
      'document_id': documentId,
      'id_admin': idAdmin,
      'id_user': idUser,
      'id_ukm': idUkm,
      'comment': comment,
      'is_status_change': isStatusChange,
      'status_from': statusFrom,
      'status_to': statusTo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String getAdminName() {
    return admin?['username_admin'] as String? ?? 'Admin';
  }

  String getAdminEmail() {
    return admin?['email_admin'] as String? ?? '';
  }

  String getUserName() {
    return user?['username'] as String? ?? 'User';
  }

  String getUserEmail() {
    return user?['email'] as String? ?? '';
  }

  String getUserPicture() {
    return user?['picture'] as String? ?? '';
  }

  String getUkmName() {
    return ukm?['nama_ukm'] as String? ?? 'UKM';
  }

  String getUkmEmail() {
    return ukm?['email'] as String? ?? '';
  }

  String getUkmLogo() {
    return ukm?['logo'] as String? ?? '';
  }

  // Get commenter name (admin, user, or UKM)
  String getCommenterName() {
    if (idAdmin != null) {
      return getAdminName();
    } else if (idUkm != null) {
      return getUkmName();
    } else if (idUser != null) {
      return getUserName();
    }
    return 'Unknown';
  }

  // Check if comment is from admin
  bool isAdminComment() {
    return idAdmin != null;
  }

  // Check if comment is from UKM
  bool isUkmComment() {
    return idUkm != null;
  }

  // Check if comment is from regular user
  bool isUserComment() {
    return idUser != null;
  }

  String getDisplayText() {
    if (isStatusChange && statusFrom != null && statusTo != null) {
      return 'Status diubah dari "$statusFrom" ke "$statusTo"\n\nCatatan: $comment';
    }
    return comment;
  }
}
