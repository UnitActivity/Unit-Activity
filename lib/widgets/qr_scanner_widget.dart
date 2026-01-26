import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef QRCodeCallback = void Function(String code);

/// Widget QR Code Scanner dengan popup dialog dan akses kamera real
/// Berbentuk kotak seimbang di tengah layar
class QRScannerDialog extends StatefulWidget {
  final QRCodeCallback onCodeScanned;
  final String title;
  final String cancelButtonLabel;
  final String manualInputLabel;

  const QRScannerDialog({
    super.key,
    required this.onCodeScanned,
    this.title = 'Scan QR Code',
    this.cancelButtonLabel = 'Batal',
    this.manualInputLabel = 'Masukkan Manual',
  });

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  late MobileScannerController cameraController;
  final TextEditingController _manualInputController = TextEditingController();
  bool _isFlashlightOn = false;
  bool _isManualInputMode = false;
  bool _isDesktop = false;

  @override
  void initState() {
    super.initState();
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        _isDesktop = true;
        _isManualInputMode = true; // Default to manual input on desktop
      }
    } catch (e) {
      // Fallback if Platform check fails (e.g. web)
      _isDesktop = false;
    }

    // Initialize camera controller even on desktop to avoid null errors if accessed,
    // though we won't use it.
    cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _toggleFlashlight() async {
    if (_isDesktop) return;
    await cameraController.toggleTorch();
    setState(() {
      _isFlashlightOn = !_isFlashlightOn;
    });
  }

  bool _isProcessingSource = false;

  void _handleDetection(BarcodeCapture capture) {
    if (_isProcessingSource) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue ?? '';
      if (code.isNotEmpty) {
        _submitCode(code);
        break; // Only process the first valid barcode
      }
    }
  }

  void _submitCode(String code) {
    if (_isProcessingSource) return;
    
    // Simple validation
    if (code.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode tidak boleh kosong')),
      );
      return;
    }

    setState(() {
      _isProcessingSource = true;
    });
    widget.onCodeScanned(code);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    // If manual input is active or we are on desktop
    if (_isManualInputMode) {
      return _buildManualInput(context);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Full screen camera for mobile, dialog for desktop
          isMobile
              ? SizedBox(
                  width: screenSize.width,
                  height: screenSize.height,
                  child: Stack(
                    children: [
                      // Camera scanner full screen
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _handleDetection,
                      ),

                      // Overlay - transparent center with smooth corners
                      Center(
                        child: CustomPaint(
                          size: const Size(250, 250),
                          painter: _ScannerOverlayPainter(),
                        ),
                      ),

                      // Header with title
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 8,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Button to switch to manual input
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isManualInputMode = true;
                                  });
                                },
                                icon: const Icon(Icons.keyboard, color: Colors.white),
                                label: const Text(
                                  "Manual",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom controls with flashlight
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 20,
                            top: 24,
                            left: 20,
                            right: 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Arahkan kamera ke QR code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              // Flashlight button
                              Material(
                                color: _isFlashlightOn
                                    ? Colors.amber[600]
                                    : Colors.white.withOpacity(0.3),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _toggleFlashlight,
                                  borderRadius: BorderRadius.circular(32),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Icon(
                                      _isFlashlightOn
                                          ? Icons.flash_on
                                          : Icons.flash_off,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: 450,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                     setState(() {
                                      _isManualInputMode = true;
                                    });
                                  },
                                  tooltip: "Input Manual",
                                  icon: const Icon(Icons.keyboard, color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Camera
                      SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            // Camera scanner
                            MobileScanner(
                              controller: cameraController,
                              onDetect: _handleDetection,
                            ),

                            // Overlay - transparent center with smooth corners
                            Center(
                              child: CustomPaint(
                                size: const Size(250, 250),
                                painter: _ScannerOverlayPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildManualInput(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.manualInputLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 16),
              if (_isDesktop)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Fitur scan kamera tidak tersedia di Desktop. Silakan masukkan kode secara manual.",
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _manualInputController,
                decoration: InputDecoration(
                  labelText: 'Kode QR / Token',
                  hintText: 'Masukkan kode di sini',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                onSubmitted: _submitCode,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _submitCode(_manualInputController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Simpan & Lanjutkan'),
              ),
              if (!_isDesktop) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isManualInputMode = false;
                    });
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Gunakan Kamera'),
                ),
              ],
            ],
          ),
        ),
      );
  }
}

/// Custom painter for smooth rounded corner scanner overlay
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = 35.0;
    final cornerRadius = 16.0;

    // Top-left corner
    final topLeftPath = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(topLeftPath, paint);

    // Top-right corner
    final topRightPath = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(topRightPath, paint);

    // Bottom-left corner
    final bottomLeftPath = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - cornerRadius)
      ..quadraticBezierTo(0, size.height, cornerRadius, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(bottomLeftPath, paint);

    // Bottom-right corner
    final bottomRightPath = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - cornerRadius, size.height)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - cornerRadius,
      )
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
