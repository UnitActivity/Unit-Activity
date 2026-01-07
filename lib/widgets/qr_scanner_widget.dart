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
    Key? key,
    required this.onCodeScanned,
    this.title = 'Scan QR Code',
    this.cancelButtonLabel = 'Batal',
    this.manualInputLabel = 'Masukkan Manual',
  }) : super(key: key);

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  late MobileScannerController cameraController;
  bool _isFlashlightOn = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _toggleFlashlight() async {
    await cameraController.toggleTorch();
    setState(() {
      _isFlashlightOn = !_isFlashlightOn;
    });
  }

  void _handleDetection(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue ?? '';
      if (code.isNotEmpty) {
        widget.onCodeScanned(code);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

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
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
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
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
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
