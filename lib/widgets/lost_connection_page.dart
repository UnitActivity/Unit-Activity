import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/connectivity_service.dart';

/// Halaman Lost Connection dengan animasi Lottie dan auto-reconnect
/// Mendukung semua platform: Android, iOS, Web, Windows, macOS, Linux
class LostConnectionPage extends StatefulWidget {
  /// Callback yang dipanggil ketika koneksi pulih
  final VoidCallback? onReconnected;

  /// Nama halaman sebelumnya untuk ditampilkan
  final String? previousPageName;

  const LostConnectionPage({
    super.key,
    this.onReconnected,
    this.previousPageName,
  });

  @override
  State<LostConnectionPage> createState() => _LostConnectionPageState();
}

class _LostConnectionPageState extends State<LostConnectionPage>
    with TickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectionSubscription;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _retryTimer;
  int _retryCount = 0;
  bool _isRetrying = false;
  bool _isReconnecting = false;
  int _countdown = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    // Pulse animation untuk indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Fade animation untuk transisi halaman
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _startAutoReconnect();
    _listenToConnection();
  }

  void _listenToConnection() {
    _connectionSubscription = _connectivityService.connectionStream.listen((
      isConnected,
    ) {
      if (isConnected && mounted) {
        _onReconnected();
      }
    });
  }

  void _startAutoReconnect() {
    _countdown = 5;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) {
            _countdown = 5;
            _tryReconnect();
          }
        });
      }
    });
  }

  Future<void> _tryReconnect() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    final isConnected = await _connectivityService.checkConnection();

    if (mounted) {
      setState(() => _isRetrying = false);

      if (isConnected) {
        _onReconnected();
      }
    }
  }

  void _onReconnected() {
    if (_isReconnecting) return;
    _isReconnecting = true;

    _countdownTimer?.cancel();
    _retryTimer?.cancel();

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Koneksi berhasil dipulihkan!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    // Fade out animation sebelum kembali
    _fadeController.reverse().then((_) {
      if (widget.onReconnected != null) {
        widget.onReconnected!();
      } else {
        // Default: pop this page
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _connectionSubscription?.cancel();
    _retryTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Mendapatkan nama platform untuk ditampilkan
  String get _platformName {
    if (kIsWeb) return 'Web';
    return 'Application';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 24 : 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Platform info badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _platformName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lottie Animation
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? 280 : 400,
                      maxHeight: isMobile ? 280 : 400,
                    ),
                    child: Lottie.asset(
                      'assets/404.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 40),

                  // Title
                  Text(
                    'Koneksi Terputus',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Tidak dapat terhubung ke server.\nMemeriksa koneksi internet Anda...',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 16,
                      color: const Color(0xFF64748B),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 32 : 48),

                  // Auto reconnect indicator
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4169E1).withValues(
                                alpha: 0.1 + (_pulseController.value * 0.1),
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF4169E1).withValues(
                              alpha: 0.2 + (_pulseController.value * 0.3),
                            ),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRetrying)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4169E1),
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.wifi_find_rounded,
                                color: const Color(0xFF4169E1),
                                size: isMobile ? 20 : 24,
                              ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isRetrying
                                      ? 'Mencoba menghubungkan...'
                                      : 'Auto reconnect dalam $_countdown detik',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4169E1),
                                  ),
                                ),
                                if (_retryCount > 0)
                                  Text(
                                    'Percobaan ke-$_retryCount',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isMobile ? 24 : 32),

                  // Manual retry button
                  SizedBox(
                    width: isMobile ? double.infinity : 280,
                    child: ElevatedButton.icon(
                      onPressed: _isRetrying ? null : _tryReconnect,
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: isMobile ? 18 : 20,
                      ),
                      label: Text(
                        'Coba Hubungkan Sekarang',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4169E1),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 14 : 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  // Previous page info
                  if (widget.previousPageName != null) ...[
                    SizedBox(height: isMobile ? 16 : 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kembali ke: ${widget.previousPageName}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget wrapper untuk memantau koneksi dan menampilkan LostConnectionPage
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final String? currentPageName;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.currentPageName,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _subscription;
  bool _showLostConnection = false;

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize();
    _subscription = _connectivityService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _showLostConnection = !isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLostConnection) {
      return LostConnectionPage(
        previousPageName: widget.currentPageName,
        onReconnected: () {
          setState(() {
            _showLostConnection = false;
          });
        },
      );
    }
    return widget.child;
  }
}
