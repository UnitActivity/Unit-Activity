import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'dart:typed_data';

class FileUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload file to Supabase Storage using bytes
  /// Returns the public URL of the uploaded file
  Future<String> uploadFileFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String bucket,
    required String filePath,
  }) async {
    try {
      print('========== UPLOAD FILE FROM BYTES ==========');
      print('Bucket: $bucket');
      print('Path: $filePath');
      print('File name: $fileName');
      print('File size: ${fileBytes.length} bytes');

      // Get file extension
      final fileExtension = path.extension(fileName);

      // Detect MIME type from file name
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      print('MIME type: $mimeType');

      // Upload to Supabase Storage
      final uploadPath = '$filePath$fileExtension';
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            uploadPath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true, // Overwrite if exists
            ),
          );

      print('✅ File uploaded successfully');

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(uploadPath);
      print('Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Delete file from Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      print('========== DELETE FILE ==========');
      print('Bucket: $bucket');
      print('Path: $filePath');

      await _supabase.storage.from(bucket).remove([filePath]);

      print('✅ File deleted successfully');
    } catch (e) {
      print('❌ Error deleting file: $e');
      rethrow;
    }
  }

  /// Get public URL for a file
  String getPublicUrl({required String bucket, required String filePath}) {
    return _supabase.storage.from(bucket).getPublicUrl(filePath);
  }

  /// Upload event proposal from bytes
  Future<String> uploadProposalFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String eventId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'proposals/${eventId}_$timestamp';

    return await uploadFileFromBytes(
      fileBytes: fileBytes,
      fileName: fileName,
      bucket: 'event-proposals',
      filePath: filePath,
    );
  }

  /// Upload event LPJ from bytes
  Future<String> uploadLPJFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String eventId,
    required String type, // 'laporan' or 'keuangan'
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'lpj/${eventId}_${type}_$timestamp';

    return await uploadFileFromBytes(
      fileBytes: fileBytes,
      fileName: fileName,
      bucket: 'event-lpj',
      filePath: filePath,
    );
  }

  /// Upload image from bytes (for events, informasi, etc)
  Future<String> uploadImageFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String folder, // 'events', 'informasi', etc
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = path.extension(fileName);
    final cleanFileName = fileName.replaceAll(' ', '_');
    
    // For informasi, use informasi-images bucket with simple filename
    // For events, use event-proposals bucket
    final bucket = folder == 'informasi' ? 'informasi-images' : 'event-proposals';
    final filePath = '${timestamp}_$cleanFileName';

    final fullUrl = await uploadFileFromBytes(
      fileBytes: fileBytes,
      fileName: fileName,
      bucket: bucket,
      filePath: filePath,
    );
    
    // Return only the path (filename) for informasi, full URL for others
    if (folder == 'informasi') {
      return filePath; // Just the filename for consistency with admin
    }
    return fullUrl;
  }

  /// Validate file type for proposals (PDF, DOC, DOCX) by file name
  bool isValidProposalFileName(String fileName) {
    final mimeType = lookupMimeType(fileName);
    final validTypes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ];

    return mimeType != null && validTypes.contains(mimeType);
  }

  /// Validate file size (max 10MB) from bytes
  bool isValidFileSizeFromBytes(Uint8List fileBytes, {int maxSizeMB = 10}) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return fileBytes.length <= maxSizeBytes;
  }
}
