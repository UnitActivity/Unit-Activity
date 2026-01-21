import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get proper public URL for a file in Supabase storage
  /// Handles different input formats:
  /// - Full URL: returns as-is
  /// - Path with bucket: constructs URL
  /// - Filename only: constructs URL with auto-detected bucket
  String getProperFileUrl(String? filePath, {String? bucket}) {
    if (filePath == null || filePath.isEmpty) {
      throw Exception('File path is empty');
    }

    // If already a full URL, return it
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    // Auto-detect bucket if not provided
    if (bucket == null) {
      // Check if path contains indicators
      final lowerPath = filePath.toLowerCase();
      if (lowerPath.contains('proposal')) {
        bucket = 'event-proposals';
      } else if (lowerPath.contains('lpj') ||
          lowerPath.contains('laporan') ||
          lowerPath.contains('keuangan')) {
        bucket = 'event-lpj';
      } else {
        // Default to event-proposals
        bucket = 'event-proposals';
      }
    }

    // Remove leading slash if present
    final cleanPath = filePath.startsWith('/')
        ? filePath.substring(1)
        : filePath;

    // Construct public URL
    try {
      return _supabase.storage.from(bucket).getPublicUrl(cleanPath);
    } catch (e) {
      throw Exception('Failed to construct file URL from bucket "$bucket": $e');
    }
  }

  /// Download file and save to device
  /// Returns the local file path
  Future<String> downloadFile({
    required String fileUrl,
    required String fileName,
    String? bucket,
    Function(double)? onProgress,
  }) async {
    try {
      // Request permission on Android
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Download file
      final response = await http.get(
        Uri.parse(fileUrl),
        headers: {'Accept': '*/*'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      // Get save directory
      Directory saveDir;
      if (kIsWeb) {
        throw Exception('Web download should use browser download');
      } else if (Platform.isAndroid) {
        // Try to get downloads directory, fallback to app documents
        try {
          final dir = await getExternalStorageDirectory();
          saveDir = Directory('${dir!.path}/Download');
          if (!await saveDir.exists()) {
            saveDir = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          saveDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        saveDir = await getApplicationDocumentsDirectory();
      } else {
        saveDir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Save file
      final filePath = '${saveDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  /// Download and open file with system app
  Future<void> downloadAndOpenFile({
    required String fileUrl,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      // Download file
      final filePath = await downloadFile(
        fileUrl: fileUrl,
        fileName: fileName,
        onProgress: onProgress,
      );

      // Open file
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('Failed to open file: ${result.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// For web: trigger browser download
  Future<void> downloadFileWeb({
    required String fileUrl,
    required String fileName,
  }) async {
    if (!kIsWeb) {
      throw Exception('This method is only for web platform');
    }

    // For web, we'll use url_launcher to open in new tab
    // The browser will handle the download
    // This is handled in the UI layer
  }

  /// Check if file is accessible
  Future<bool> isFileAccessible(String fileUrl) async {
    try {
      final response = await http.head(Uri.parse(fileUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get file extension from URL or filename
  String getFileExtension(String fileUrl) {
    final uri = Uri.parse(fileUrl);
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot + 1).toLowerCase().split('?').first;
  }

  /// Get file name from URL
  String getFileNameFromUrl(String fileUrl) {
    final uri = Uri.parse(fileUrl);
    final segments = uri.pathSegments;
    if (segments.isEmpty) return 'document';
    return segments.last.split('?').first;
  }

  /// Format file size
  String formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
