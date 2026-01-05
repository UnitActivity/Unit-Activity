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
  bool _showManualInput = false;
  late TextEditingController _manualInputController;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    _manualInputController = TextEditingController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    _manualInputController.dispose();
    super.dispose();
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

  void _handleManualInput() {
    final code = _manualInputController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan masukkan kode QR'),
          backgroundColor: Colors.orange[600],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onCodeScanned(code);
    _manualInputController.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogSize = screenSize.width > 500 ? 450.0 : screenSize.width - 40;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: dialogSize,
        child: Container(
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
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Camera or Manual Input
              if (!_showManualInput)
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Camera scanner
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _handleDetection,
                      ),

                      // Overlay dengan garis scanning
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              // Corner indicators
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.green[400]!,
                                        width: 3,
                                      ),
                                      left: BorderSide(
                                        color: Colors.green[400]!,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.green[400]!,
                                        width: 3,
                                      ),
                                      right: BorderSide(
                                        color: Colors.green[400]!,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.green[400]!,
                                        width: 3,
                                      ),
                                      left: BorderSide(
                                        color: Colors.green[400]!,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.green[400]!,
                                        width: 3,
                                      ),
                                      right: BorderSide(
                                        color: Colors.green[400]!,
                                        width: 3,
                                      ),
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
              else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Masukkan Kode QR Secara Manual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _manualInputController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan kode QR',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.blue[700],
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              // Info text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _showManualInput
                              ? 'Ketikkan kode QR yang ingin Anda scan'
                              : 'Arahkan kamera ke QR code untuk scan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _showManualInput = !_showManualInput);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _showManualInput
                              ? 'Scan Kamera'
                              : widget.manualInputLabel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_showManualInput) {
                            _handleManualInput();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showManualInput
                              ? Colors.green[700]
                              : Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _showManualInput
                              ? 'Submit'
                              : widget.cancelButtonLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
