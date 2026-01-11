import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';

class DocumentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get detailed information about a proposal document
  Future<DocumentProposal> getProposalDetails(String proposalId) async {
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
    } catch (e) {
      throw Exception('Gagal memuat detail proposal: $e');
    }
  }

  /// Get detailed information about an LPJ document
  Future<DocumentLPJ> getLPJDetails(String lpjId) async {
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
    } catch (e) {
      throw Exception('Gagal memuat detail LPJ: $e');
    }
  }

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
            admin(username_admin, email_admin)
          ''')
          .eq('document_id', documentId)
          .eq('document_type', documentType)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DocumentRevision.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat riwayat revisi: $e');
    }
  }

  /// Get all comments for a document
  Future<List<DocumentComment>> getDocumentComments(
    String documentId,
    String documentType,
  ) async {
    try {
      final response = await _supabase
          .from('document_comments')
          .select('''
            *,
            admin(username_admin, email_admin)
          ''')
          .eq('document_id', documentId)
          .eq('document_type', documentType)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DocumentComment.fromJson(json))
          .toList();
    } catch (e) {
      print('⚠️ Error loading comments (table might not exist yet): $e');
      // Return empty list if table doesn't exist yet
      return [];
    }
  }

  /// Update proposal status with admin note
  Future<void> updateProposalStatus({
    required String proposalId,
    required String newStatus,
    required String adminNote,
    required String adminId,
    String? oldStatus,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    try {
      // PRIMARY: Update the proposal (MUST succeed)
      await _supabase
          .from('event_proposal')
          .update({
            'status': newStatus,
            'catatan_admin': adminNote,
            'tanggal_ditinjau': now,
            'admin_yang_meninjau': adminId,
            'updated_at': now,
          })
          .eq('id_proposal', proposalId);

      print('✅ Status updated to: $newStatus');

      // OPTIONAL: Try to save to document_comments & revision_history
      // DISABLED temporarily due to trigger issues
      /*
      try {
        await _supabase.from('document_comments').insert({
          'document_type': 'proposal',
          'document_id': proposalId,
          'id_admin': adminId,
          'comment': adminNote,
          'is_status_change': true,
          'status_from': oldStatus,
          'status_to': newStatus,
          'created_at': now,
        });
      } catch (commentError) {
        print('⚠️ Could not save to document_comments: $commentError');
      }

      try {
        await _supabase.from('document_revision_history').insert({
          'document_type': 'proposal',
          'document_id': proposalId,
          'id_admin': adminId,
          'catatan': adminNote,
          'status_sebelumnya': oldStatus,
          'status_setelahnya': newStatus,
          'created_at': now,
        });
      } catch (revisionError) {
        print('⚠️ Could not save to revision history: $revisionError');
      }
      */
    } catch (e) {
      print('❌ Error updating proposal: $e');
      throw Exception('Gagal memperbarui status proposal: $e');
    }
  }

  /// Update LPJ status with admin note
  Future<void> updateLPJStatus({
    required String lpjId,
    required String newStatus,
    required String adminNote,
    required String adminId,
    String? oldStatus,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    try {
      // PRIMARY: Update the LPJ (MUST succeed)
      await _supabase
          .from('event_lpj')
          .update({
            'status': newStatus,
            'catatan_admin': adminNote,
            'tanggal_ditinjau': now,
            'admin_yang_meninjau': adminId,
            'updated_at': now,
          })
          .eq('id_lpj', lpjId);

      print('✅ Status updated to: $newStatus');

      // OPTIONAL: Try to save to document_comments & revision_history
      // DISABLED temporarily due to trigger issues
      /*
      try {
        await _supabase.from('document_comments').insert({
          'document_type': 'lpj',
          'document_id': lpjId,
          'id_admin': adminId,
          'comment': adminNote,
          'is_status_change': true,
          'status_from': oldStatus,
          'status_to': newStatus,
          'created_at': now,
        });
      } catch (commentError) {
        print('⚠️ Could not save to document_comments: $commentError');
      }

      try {
        await _supabase.from('document_revision_history').insert({
          'document_type': 'lpj',
          'document_id': lpjId,
          'id_admin': adminId,
          'catatan': adminNote,
          'status_sebelumnya': oldStatus,
          'status_setelahnya': newStatus,
          'created_at': now,
        });
      } catch (revisionError) {
        print('⚠️ Could not save to revision history: $revisionError');
      }
      */
    } catch (e) {
      print('❌ Error updating LPJ: $e');
      throw Exception('Gagal memperbarui status LPJ: $e');
    }
  }

  /// Add a comment/note to a proposal
  Future<void> addProposalComment({
    required String proposalId,
    required String comment,
    required String adminId,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    try {
      // PRIMARY: Update catatan_admin in event_proposal (MUST succeed)
      await _supabase
          .from('event_proposal')
          .update({
            'catatan_admin': comment,
            'admin_yang_meninjau': adminId,
            'updated_at': now,
          })
          .eq('id_proposal', proposalId);

      print('✅ Comment saved to event_proposal.catatan_admin');

      // OPTIONAL: Try to save to document_comments (may fail, that's OK)
      // DISABLED temporarily due to trigger issues - enable after trigger is fixed
      /*
      try {
        await _supabase.from('document_comments').insert({
          'document_type': 'proposal',
          'document_id': proposalId,
          'id_admin': adminId,
          'comment': comment,
          'is_status_change': false,
          'created_at': now,
        });
        print('✅ Comment also saved to document_comments');
      } catch (commentError) {
        print('⚠️ Could not save to document_comments: $commentError');
      }
      */
    } catch (e) {
      print('❌ Error updating event_proposal: $e');
      throw Exception('Gagal menambahkan komentar: $e');
    }
  }

  /// Add a comment/note to an LPJ
  Future<void> addLPJComment({
    required String lpjId,
    required String comment,
    required String adminId,
  }) async {
    final now = DateTime.now().toIso8601String();
    
    try {
      // PRIMARY: Update catatan_admin in event_lpj (MUST succeed)
      await _supabase
          .from('event_lpj')
          .update({
            'catatan_admin': comment,
            'admin_yang_meninjau': adminId,
            'updated_at': now,
          })
          .eq('id_lpj', lpjId);

      print('✅ Comment saved to event_lpj.catatan_admin');

      // OPTIONAL: Try to save to document_comments (may fail, that's OK)
      // DISABLED temporarily due to trigger issues - enable after trigger is fixed
      /*
      try {
        await _supabase.from('document_comments').insert({
          'document_type': 'lpj',
          'document_id': lpjId,
          'id_admin': adminId,
          'comment': comment,
          'is_status_change': false,
          'created_at': now,
        });
        print('✅ Comment also saved to document_comments');
      } catch (commentError) {
        print('⚠️ Could not save to document_comments: $commentError');
      }
      */
    } catch (e) {
      print('❌ Error updating event_lpj: $e');
      throw Exception('Gagal menambahkan komentar: $e');
    }
  }

  /// Get public URL for a file in Supabase storage
  String getFileUrl(String filePath) {
    // Assuming files are stored in 'documents' bucket
    // Adjust bucket name based on your actual storage structure
    try {
      return _supabase.storage.from('documents').getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Gagal mendapatkan URL file: $e');
    }
  }

  /// Download a file (get signed URL for download)
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final signedUrl = await _supabase.storage
          .from('documents')
          .createSignedUrl(filePath, 3600); // Valid for 1 hour
      return signedUrl;
    } catch (e) {
      throw Exception('Gagal mendapatkan URL download: $e');
    }
  }

  /// Format file size to human readable format
  String formatFileSize(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get status color based on status string
  static Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return {
          'color': const Color(0xFF10B981),
          'label': 'Disetujui',
          'icon': Icons.check_circle,
        };
      case 'ditolak':
        return {
          'color': const Color(0xFFEF4444),
          'label': 'Ditolak',
          'icon': Icons.cancel,
        };
      case 'revisi':
        return {
          'color': const Color(0xFFF59E0B),
          'label': 'Perlu Revisi',
          'icon': Icons.edit,
        };
      default:
        return {
          'color': const Color(0xFF3B82F6),
          'label': 'Menunggu Review',
          'icon': Icons.schedule,
        };
    }
  }
}
