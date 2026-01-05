/// CONTOH IMPLEMENTASI QR SCANNER DI HALAMAN LAIN
///
/// File ini menunjukkan bagaimana mengintegrasikan QR Scanner widget
/// ke dalam halaman yang berbeda. Anda dapat menyalin pola ini ke halaman lain.

import 'package:flutter/material.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';

class ExampleQRScannerPage extends StatefulWidget {
  const ExampleQRScannerPage({Key? key}) : super(key: key);

  @override
  State<ExampleQRScannerPage> createState() => _ExampleQRScannerPageState();
}

class _ExampleQRScannerPageState extends State<ExampleQRScannerPage>
    with QRScannerMixin {
  final List<String> _scannedCodes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contoh QR Scanner'),
        actions: [
          // Add QR Scanner button to app bar
          buildQRScannerButton(
            onCodeScanned: _handleQRCodeScanned,
            icon: Icons.qr_code_2,
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR Codes Scanned',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _scannedCodes.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada kode QR yang di-scan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Klik tombol QR di atas untuk mulai scan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
        if (_scannedCodes.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    title: const Text('QR Code'),
                    subtitle: Text(_scannedCodes[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeCode(index),
                    ),
                  ),
                ),
              );
            }, childCount: _scannedCodes.length),
          ),
      ],
    );
  }

  void _handleQRCodeScanned(String code) {
    // Contoh: tambahkan validasi
    if (code.isEmpty) {
      _showError('Kode tidak valid');
      return;
    }

    // Tambahkan ke list
    setState(() {
      _scannedCodes.add(code);
    });

    // Validasi dan simpan
    _validateAndSaveCode(code);
  }

  Future<void> _validateAndSaveCode(String code) async {
    try {
      // Simulasi validasi ke server
      await Future.delayed(const Duration(milliseconds: 500));

      // Contoh: cek duplikat
      if (_scannedCodes.where((c) => c == code).length > 1) {
        _showWarning('Kode ini sudah di-scan sebelumnya');
        return;
      }

      _showSuccess('Kode berhasil disimpan: $code');
    } catch (e) {
      _showError('Error: ${e.toString()}');
      // Hapus dari list jika ada error
      setState(() {
        _scannedCodes.remove(code);
      });
    }
  }

  void _removeCode(int index) {
    setState(() {
      _scannedCodes.removeAt(index);
    });
    _showSuccess('Kode dihapus');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// ALTERNATIF: Implementasi dengan Dialog (tanpa overlay)
///
/// Jika Anda ingin menggunakan QR Scanner dalam dialog modal,
/// Anda bisa menggunakan widget langsung tanpa mixin:

// import 'package:unit_activity/widgets/qr_scanner_widget.dart';
//
// void _showQRScannerDialog() {
//   showDialog(
//     context: context,
//     builder: (context) => Dialog(
//       child: QRScannerWidget(
//         onCodeScanned: (code) {
//           _handleQRCodeScanned(code);
//           Navigator.pop(context);
//         },
//         onClose: () => Navigator.pop(context),
//         title: 'Scan QR Code',
//       ),
//     ),
//   );
// }
