import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';

/// ============================================================================
/// DOCUMENT SERVICE - UNIFIED TABLE VERSION
/// Menggunakan table event_documents untuk proposal dan LPJ
/// ============================================================================

class DocumentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========== UNIFIED DOCUMENT METHODS ==========

  /// Get all documents with optional filters
  Future<List<EventDocument>> getDocuments({
    String? documentType, // 'proposal' atau 'lpj'
    String? status,
    String? idUkm,
  }) async {
    try {
      var query = _supabase.from('event_documents').select('''
            *,
            events(nama_event, tanggal_mulai, lokasi),
            ukm(nama_ukm, logo),
            users(username, email),
            admin(username_admin, email_admin)
          ''');

      if (documentType != null) {
        query = query.eq('document_type', documentType);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (idUkm != null) {
        query = query.eq('id_ukm', idUkm);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => EventDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat dokumen: $e');
    }
  }

  /// Get single document by ID
  Future<EventDocument> getDocument(String documentId) async {
    try {
      final response = await _supabase
          .from('event_documents')
          .select('''
            *,
            events(nama_event, tanggal_mulai, lokasi),
            ukm(nama_ukm, logo),
            users(username, email),
            admin(username_admin, email_admin)
          ''')
          .eq('id_document', documentId)
          .single();

      return EventDocument.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat detail dokumen: $e');
    }
  }

  /// Add comment to document (UNIFIED - NO MORE TRIGGER ERROR)
  Future<void> addComment({
    required String documentId,
    required String comment,
    required String adminId,
  }) async {
    final now = DateTime.now().toIso8601String();

    try {
      // Get document type first
      final docResponse = await _supabase
          .from('event_documents')
          .select('document_type')
          .eq('id_document', documentId)
          .single();

      final documentType = docResponse['document_type'] as String;

      // 1. Update catatan_admin in event_documents (latest comment)
      await _supabase
          .from('event_documents')
          .update({
            'catatan_admin': comment,
            'admin_yang_meninjau': adminId,
            'updated_at': now,
          })
          .eq('id_document', documentId);

      // 2. INSERT into document_comments (comment history)
      final insertData = {
        'document_id': documentId,
        'document_type': documentType,
        'id_admin': adminId, // CHANGED: Try id_admin instead of admin_id
        'comment': comment,
        'created_at': now,
      };

      print('📝 Inserting comment data: $insertData');

      final insertResult = await _supabase
          .from('document_comments')
          .insert(insertData)
          .select();

      print('✅ Insert result: $insertResult');
      print('✅ Comment saved to both event_documents and document_comments');
    } catch (e) {
      print('❌ Error adding comment: $e');
      throw Exception('Gagal menambahkan komentar: $e');
    }
  }

  /// Update document status (UNIFIED - NO MORE TRIGGER ERROR)
  Future<void> updateStatus({
    required String documentId,
    required String newStatus,
    required String adminId,
    String? catatan,
  }) async {
    final now = DateTime.now().toIso8601String();

    try {
      // Get current status and document type
      final docResponse = await _supabase
          .from('event_documents')
          .select('status, document_type')
          .eq('id_document', documentId)
          .single();

      final oldStatus = docResponse['status'] as String;
      final documentType = docResponse['document_type'] as String;

      // 1. Update status in event_documents
      await _supabase
          .from('event_documents')
          .update({
            'status': newStatus,
            'catatan_admin': catatan,
            'admin_yang_meninjau': adminId,
            'tanggal_ditinjau': now,
            'updated_at': now,
          })
          .eq('id_document', documentId);

      // 2. INSERT into document_revision_history
      await _supabase.from('document_revision_history').insert({
        'document_id': documentId,
        'document_type': documentType,
        'old_status': oldStatus,
        'new_status': newStatus,
        'admin_id': adminId,
        'catatan': catatan,
        'created_at': now,
      });

      // 3. INSERT into document_comments if there's a catatan
      if (catatan != null && catatan.isNotEmpty) {
        await _supabase.from('document_comments').insert({
          'document_id': documentId,
          'document_type': documentType,
          'id_admin': adminId, // CHANGED: Use id_admin
          'comment': catatan,
          'is_status_change': true,
          'status_from': oldStatus,
          'status_to': newStatus,
          'created_at': now,
        }).select();
      }

      print(
        '✅ Document status updated from $oldStatus to $newStatus with history',
      );
    } catch (e) {
      print('❌ Error updating status: $e');
      throw Exception('Gagal update status: $e');
    }
  }

  // ========== LEGACY METHODS (Backward Compatible) ==========

  /// Get proposal details (Legacy wrapper)
  Future<DocumentProposal> getProposalDetails(String proposalId) async {
    try {
      final doc = await getDocument(proposalId);
      return DocumentProposal.fromEventDocument(doc);
    } catch (e) {
      // Fallback to old table if migration not done yet
      try {
        final response = await _supabase
            .from('event_proposal')
            .select('''
              *,
              events(nama_event, tanggal_mulai, lokasi),
              ukm(nama_ukm, logo),
              users(username, email),
              admin(username_admin, email_admin)
            ''')
            .eq('id_proposal', proposalId)
            .single();

        return DocumentProposal.fromJson(response);
      } catch (e2) {
        throw Exception('Gagal memuat detail proposal: $e2');
      }
    }
  }

  /// Get LPJ details (Legacy wrapper)
  Future<DocumentLPJ> getLPJDetails(String lpjId) async {
    try {
      final doc = await getDocument(lpjId);
      return DocumentLPJ.fromEventDocument(doc);
    } catch (e) {
      // Fallback to old table if migration not done yet
      try {
        final response = await _supabase
            .from('event_lpj')
            .select('''
              *,
              events(nama_event, tanggal_mulai, lokasi),
              ukm(nama_ukm, logo),
              users(username, email),
              admin(username_admin, email_admin)
            ''')
            .eq('id_lpj', lpjId)
            .single();

        return DocumentLPJ.fromJson(response);
      } catch (e2) {
        throw Exception('Gagal memuat detail LPJ: $e2');
      }
    }
  }

  /// Add comment to proposal (Legacy wrapper)
  Future<void> addProposalComment({
    required String proposalId,
    required String comment,
    required String adminId,
  }) async {
    return addComment(
      documentId: proposalId,
      comment: comment,
      adminId: adminId,
    );
  }

  /// Add comment to LPJ (Legacy wrapper)
  Future<void> addLPJComment({
    required String lpjId,
    required String comment,
    required String adminId,
  }) async {
    return addComment(documentId: lpjId, comment: comment, adminId: adminId);
  }

  /// Update proposal status (Legacy wrapper)
  Future<void> updateProposalStatus({
    required String proposalId,
    required String newStatus,
    required String adminId,
    String? catatan,
  }) async {
    return updateStatus(
      documentId: proposalId,
      newStatus: newStatus,
      adminId: adminId,
      catatan: catatan,
    );
  }

  /// Update LPJ status (Legacy wrapper)
  Future<void> updateLPJStatus({
    required String lpjId,
    required String newStatus,
    required String adminId,
    String? catatan,
  }) async {
    return updateStatus(
      documentId: lpjId,
      newStatus: newStatus,
      adminId: adminId,
      catatan: catatan,
    );
  }

  // ========== COMMENT MANAGEMENT ==========

  /// Update a comment (only by the admin who created it)
  Future<void> updateComment({
    required String commentId,
    required String newComment,
    required String adminId,
  }) async {
    try {
      // Verify the comment belongs to this admin
      final existing = await _supabase
          .from('document_comments')
          .select('id_admin')
          .eq('id_comment', commentId)
          .single();

      if (existing['id_admin'] != adminId) {
        throw Exception('Anda hanya bisa mengedit komentar Anda sendiri');
      }

      await _supabase
          .from('document_comments')
          .update({
            'comment': newComment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_comment', commentId);

      print('✅ Comment updated successfully');
    } catch (e) {
      print('❌ Error updating comment: $e');
      throw Exception('Gagal mengupdate komentar: $e');
    }
  }

  /// Delete a comment (only by the admin who created it)
  Future<void> deleteComment({
    required String commentId,
    required String adminId,
  }) async {
    try {
      // Verify the comment belongs to this admin
      final existing = await _supabase
          .from('document_comments')
          .select('id_admin')
          .eq('id_comment', commentId)
          .single();

      if (existing['id_admin'] != adminId) {
        throw Exception('Anda hanya bisa menghapus komentar Anda sendiri');
      }

      await _supabase
          .from('document_comments')
          .delete()
          .eq('id_comment', commentId);

      print('✅ Comment deleted successfully');
    } catch (e) {
      print('❌ Error deleting comment: $e');
      throw Exception('Gagal menghapus komentar: $e');
    }
  }

  /// Rollback document status (used when deleting status change comment)
  Future<void> rollbackStatus({
    required String documentId,
    required String rollbackToStatus,
    required String adminId,
  }) async {
    try {
      print('⏪ Rolling back status to: $rollbackToStatus');

      final now = DateTime.now().toIso8601String();

      // Update status in event_documents
      await _supabase
          .from('event_documents')
          .update({
            'status': rollbackToStatus,
            'admin_yang_meninjau': adminId,
            'tanggal_ditinjau': now,
            'updated_at': now,
          })
          .eq('id_document', documentId);

      print('✅ Status rolled back successfully to: $rollbackToStatus');
    } catch (e) {
      print('❌ Error rolling back status: $e');
      throw Exception('Gagal mengembalikan status: $e');
    }
  }

  // ========== REVISION HISTORY & COMMENTS ==========

  /// Get revision history for a document
  Future<List<DocumentRevision>> getRevisionHistory(
    String documentId,
    String documentType,
  ) async {
    try {
      final response = await _supabase
          .from('document_revision_history')
          .select('''
            *,
            users(username, email),
            admin!document_revision_history_admin_id_fkey(username_admin, email_admin)
          ''')
          .eq('document_id', documentId)
          .eq('document_type', documentType)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DocumentRevision.fromJson(json))
          .toList();
    } catch (e) {
      print('⚠️ Error loading revision history: $e');
      return [];
    }
  }

  /// Get all comments for a document
  Future<List<DocumentComment>> getDocumentComments(
    String documentId,
    String documentType,
  ) async {
    try {
      print(
        '🔍 Loading comments for document: $documentId, type: $documentType',
      );

      final response = await _supabase
          .from('document_comments')
          .select('''
            *,
            admin!document_comments_admin_id_fkey(username_admin, email_admin)
          ''')
          .eq('document_id', documentId)
          .eq('document_type', documentType)
          .order('created_at', ascending: false);

      print('📦 Comments response: $response');
      print('📊 Comments count: ${(response as List).length}');

      return (response as List)
          .map((json) => DocumentComment.fromJson(json))
          .toList();
    } catch (e) {
      print('⚠️ Error loading comments: $e');
      return [];
    }
  }

  // ========== STATISTICS & UTILITIES ==========

  /// Get document statistics by UKM
  Future<Map<String, int>> getDocumentStatsByUkm(String idUkm) async {
    try {
      final allDocs = await getDocuments(idUkm: idUkm);

      return {
        'total': allDocs.length,
        'proposals': allDocs.where((d) => d.isProposal).length,
        'lpj': allDocs.where((d) => d.isLPJ).length,
        'menunggu': allDocs.where((d) => d.status == 'menunggu').length,
        'disetujui': allDocs.where((d) => d.status == 'disetujui').length,
        'ditolak': allDocs.where((d) => d.status == 'ditolak').length,
        'revisi': allDocs.where((d) => d.status == 'revisi').length,
      };
    } catch (e) {
      throw Exception('Gagal memuat statistik dokumen: $e');
    }
  }

  /// Get pending documents (status = menunggu)
  Future<List<EventDocument>> getPendingDocuments() async {
    return getDocuments(status: 'menunggu');
  }

  /// Get approved documents
  Future<List<EventDocument>> getApprovedDocuments() async {
    return getDocuments(status: 'disetujui');
  }

  /// Get rejected documents
  Future<List<EventDocument>> getRejectedDocuments() async {
    return getDocuments(status: 'ditolak');
  }

  /// Get documents needing revision
  Future<List<EventDocument>> getRevisionDocuments() async {
    return getDocuments(status: 'revisi');
  }

  // ========== STATUS STYLING ==========

  /// Get status style for UI (color, icon, label)
  static Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return {
          'color': Colors.green,
          'icon': Icons.check_circle,
          'label': 'Disetujui',
          'bgColor': Colors.green.withOpacity(0.1),
        };
      case 'ditolak':
        return {
          'color': Colors.red,
          'icon': Icons.cancel,
          'label': 'Ditolak',
          'bgColor': Colors.red.withOpacity(0.1),
        };
      case 'revisi':
        return {
          'color': Colors.orange,
          'icon': Icons.edit,
          'label': 'Perlu Revisi',
          'bgColor': Colors.orange.withOpacity(0.1),
        };
      default: // menunggu
        return {
          'color': Colors.blue,
          'icon': Icons.schedule,
          'label': 'Menunggu Review',
          'bgColor': Colors.blue.withOpacity(0.1),
        };
    }
  }

  /// Format file size untuk display
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 KB';

    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }
}
