import 'package:flutter/material.dart';
import 'qr_scanner_widget.dart';

/// Mixin untuk menambahkan fitur QR Scanner ke widget manapun
/// Menggunakan mixin ini akan menambahkan kemampuan scan QR dengan popup dialog
mixin QRScannerMixin<T extends StatefulWidget> on State<T> {
  /// Buka QR Scanner Dialog dengan akses kamera
  void openQRScannerDialog({
    required QRCodeCallback onCodeScanned,
    String title = 'Scan QR Code',
    String cancelButtonLabel = 'Batal',
    String manualInputLabel = 'Masukkan Manual',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QRScannerDialog(
        onCodeScanned: onCodeScanned,
        title: title,
        cancelButtonLabel: cancelButtonLabel,
        manualInputLabel: manualInputLabel,
      ),
    );
  }

  /// Icon button untuk membuka QR Scanner Dialog
  Widget buildQRScannerButton({
    required QRCodeCallback onCodeScanned,
    IconData icon = Icons.qr_code_2,
    String tooltip = 'Scan QR Code',
    String title = 'Scan QR Code',
    String cancelButtonLabel = 'Batal',
    String manualInputLabel = 'Masukkan Manual',
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => openQRScannerDialog(
        onCodeScanned: onCodeScanned,
        title: title,
        cancelButtonLabel: cancelButtonLabel,
        manualInputLabel: manualInputLabel,
      ),
    );
  }
}
