import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/services/dynamic_qr_service.dart';

/// Widget untuk menampilkan QR Code dinamis yang auto-refresh setiap 10 detik
class DynamicQRCodeWidget extends StatefulWidget {
  final String type; // 'EVENT' atau 'PERTEMUAN'
  final String id; // ID event atau pertemuan
  final String? title; // Judul untuk ditampilkan
  final double size; // Ukuran QR code
  final Color? foregroundColor;
  final Color? backgroundColor;
  final bool showTimer; // Tampilkan countdown timer

  const DynamicQRCodeWidget({
    super.key,
    required this.type,
    required this.id,
    this.title,
    this.size = 250,
    this.foregroundColor,
    this.backgroundColor,
    this.showTimer = true,
  });

  @override
  State<DynamicQRCodeWidget> createState() => _DynamicQRCodeWidgetState();
}

class _DynamicQRCodeWidgetState extends State<DynamicQRCodeWidget> {
  late String _currentQRCode;
  late Timer _refreshTimer;
  late Timer _countdownTimer;
  int _remainingSeconds = 10;

  @override
  void initState() {
    super.initState();
    _generateNewQRCode();
    _startRefreshTimer();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _countdownTimer.cancel();
    super.dispose();
  }

  void _generateNewQRCode() {
    setState(() {
      _currentQRCode = DynamicQRService.generateDynamicQR(
        type: widget.type,
        id: widget.id,
        additionalData: null,
      );
      _remainingSeconds = DynamicQRService.validityWindow;
    });
    print('🔄 New QR Code generated: $_currentQRCode');
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(
      Duration(seconds: DynamicQRService.validityWindow),
      (timer) {
        _generateNewQRCode();
      },
    );
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = DynamicQRService.validityWindow;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan QR Code untuk absensi',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: QrImageView(
              data: _currentQRCode,
              version: QrVersions.auto,
              size: widget.size,
              foregroundColor: widget.foregroundColor ?? Colors.black,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              padding: const EdgeInsets.all(0),
            ),
          ),

          if (widget.showTimer) ...[
            const SizedBox(height: 16),

            // Timer bar
            Container(
              width: widget.size,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor:
                    _remainingSeconds / DynamicQRService.validityWindow,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _remainingSeconds <= 3
                          ? [Colors.red, Colors.orange]
                          : [Colors.blue, Colors.green],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Countdown text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh,
                  size: 16,
                  color: _remainingSeconds <= 3 ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  'QR Code baru dalam $_remainingSeconds detik',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _remainingSeconds <= 3
                        ? Colors.red
                        : Colors.grey[700],
                    fontWeight: _remainingSeconds <= 3
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Info text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'QR Code berganti otomatis setiap ${DynamicQRService.validityWindow} detik untuk keamanan',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.blue[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog untuk menampilkan QR Code dengan fullscreen
class DynamicQRCodeDialog extends StatelessWidget {
  final String type;
  final String id;
  final String title;

  const DynamicQRCodeDialog({
    super.key,
    required this.type,
    required this.id,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 500,
          maxHeight: isMobile ? double.infinity : 700,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),

            // QR Code content
            Padding(
              padding: const EdgeInsets.all(24),
              child: DynamicQRCodeWidget(
                type: type,
                id: id,
                size: isMobile ? 250 : 300,
                showTimer: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show QR Code dialog
  static Future<void> show({
    required BuildContext context,
    required String type,
    required String id,
    required String title,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          DynamicQRCodeDialog(type: type, id: id, title: title),
    );
  }
}
