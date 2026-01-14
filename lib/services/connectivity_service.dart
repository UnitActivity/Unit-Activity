import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Service untuk memantau koneksi internet secara real-time
/// Mendukung semua platform: Android, iOS, Web, Windows, macOS, Linux
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionStreamController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheckTimer;
  bool _isConnected = true;
  bool _isInitialized = false;

  /// Stream untuk mendengarkan perubahan status koneksi
  Stream<bool> get connectionStream {
    _connectionStreamController ??= StreamController<bool>.broadcast();
    return _connectionStreamController!.stream;
  }

  /// Status koneksi saat ini
  bool get isConnected => _isConnected;

  /// Cek apakah service sudah diinisialisasi
  bool get isInitialized => _isInitialized;

  /// Inisialisasi service dan mulai memantau koneksi
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Skip connectivity monitoring on web platform
    // Web has CORS restrictions that cause errors when checking connectivity
    if (kIsWeb) {
      _isConnected = true; // Always assume connected on web
      return;
    }

    // Pastikan stream controller sudah ada
    _connectionStreamController ??= StreamController<bool>.broadcast();

    // Check initial connection
    await checkConnection();

    // Listen to connection changes dari connectivity_plus
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        _updateConnectionStatus(false);
      } else {
        // Verify actual internet connectivity
        final hasInternet = await _verifyInternetConnection();
        _updateConnectionStatus(hasInternet);
      }
    });
  }

  /// Cek koneksi internet saat ini
  Future<bool> checkConnection() async {
    // On web, always return true to avoid CORS errors
    if (kIsWeb) {
      return true;
    }

    try {
      // Untuk platform native, gunakan connectivity_plus terlebih dahulu
      final results = await _connectivity.checkConnectivity();

      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        _updateConnectionStatus(false);
        return false;
      }

      // Verify actual internet connectivity
      final hasInternet = await _verifyInternetConnection();
      _updateConnectionStatus(hasInternet);
      return hasInternet;
    } catch (e) {
      debugPrint('Error checking connection: $e');
      // Fallback: coba verify internet langsung
      try {
        final hasInternet = await _verifyInternetConnection();
        _updateConnectionStatus(hasInternet);
        return hasInternet;
      } catch (_) {
        _updateConnectionStatus(false);
        return false;
      }
    }
  }

  /// Verifikasi koneksi internet dengan melakukan HTTP request
  /// Menggunakan beberapa endpoint sebagai fallback
  Future<bool> _verifyInternetConnection() async {
    final endpoints = [
      'https://www.google.com/generate_204',
      'https://clients3.google.com/generate_204',
      'https://www.cloudflare.com/cdn-cgi/trace',
      'https://connectivitycheck.gstatic.com/generate_204',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .get(Uri.parse(endpoint))
            .timeout(const Duration(seconds: 5));
        // Status 200 atau 204 (No Content) dianggap berhasil
        if (response.statusCode == 200 || response.statusCode == 204) {
          return true;
        }
      } catch (e) {
        debugPrint('Failed to reach $endpoint: $e');
        continue;
      }
    }
    return false;
  }

  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStreamController?.add(isConnected);
      debugPrint('Connection status changed: $isConnected');
    }
  }

  /// Force emit current status (berguna saat widget baru subscribe)
  void emitCurrentStatus() {
    _connectionStreamController?.add(_isConnected);
  }

  /// Dispose resources
  void dispose() {
    _periodicCheckTimer?.cancel();
    _subscription?.cancel();
    _connectionStreamController?.close();
    _connectionStreamController = null;
    _isInitialized = false;
  }
}
