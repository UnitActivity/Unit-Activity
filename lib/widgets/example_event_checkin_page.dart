/// CONTOH IMPLEMENTASI QR SCANNER DI HALAMAN EVENT
///
/// File ini menunjukkan bagaimana mengintegrasikan QR Scanner
/// untuk check-in event. Ini adalah use case yang paling umum.

import 'package:flutter/material.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';

class EventCheckInPage extends StatefulWidget {
  const EventCheckInPage({Key? key}) : super(key: key);

  @override
  State<EventCheckInPage> createState() => _EventCheckInPageState();
}

class _EventCheckInPageState extends State<EventCheckInPage>
    with QRScannerMixin {
  final List<Map<String, dynamic>> _checkedInUsers = [];
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Check-in'),
        centerTitle: true,
        actions: [
          // QR Scanner button di app bar
          buildQRScannerButton(
            onCodeScanned: _handleCheckIn,
            icon: Icons.qr_code_2,
            tooltip: 'Scan Kode Peserta',
            title: 'Check-in Event',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Statistics header
        _buildStatisticsCard(),
        const SizedBox(height: 16),

        // List of checked-in users
        Expanded(
          child: _checkedInUsers.isEmpty
              ? _buildEmptyState()
              : _buildCheckedInList(),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.verified_user,
            label: 'Check-in',
            value: _checkedInUsers.length.toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.qr_code_2,
            label: 'Total',
            value: (_checkedInUsers.length + 5)
                .toString(), // Sample: total 5 + checked in
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.person_outline,
            label: 'Belum',
            value: (5 - _checkedInUsers.length).toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.qr_code_2, size: 48, color: Colors.blue[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada peserta yang check-in',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol QR di atas untuk mulai scan',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => openQRScannerDialog(
              onCodeScanned: _handleCheckIn,
              title: 'Check-in Event',
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Mulai Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedInList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checkedInUsers.length,
      itemBuilder: (context, index) {
        final user = _checkedInUsers[index];
        return _buildCheckedInCard(user, index);
      },
    );
  }

  Widget _buildCheckedInCard(Map<String, dynamic> user, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  (index + 1).toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${user['code']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Check icon dan time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(height: 4),
                Text(
                  user['time'] ?? '--:--',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),

            // Delete button
            IconButton(
              onPressed: () => _undoCheckIn(index),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red[400],
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckIn(String code) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Simulasi validasi ke server
      await Future.delayed(const Duration(milliseconds: 800));

      // Check duplikat
      if (_checkedInUsers.any((user) => user['code'] == code)) {
        _showWarning('Peserta ini sudah check-in sebelumnya');
        setState(() => _isProcessing = false);
        return;
      }

      // Get current time
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Simulasi get user data from server
      final userData = {
        'code': code,
        'name': 'Peserta ${_checkedInUsers.length + 1}', // Placeholder
        'time': timeStr,
      };

      // Add to list
      setState(() {
        _checkedInUsers.add(userData);
        _isProcessing = false;
      });

      // Show success message
      _showSuccess('Check-in berhasil untuk peserta: $code');

      // Auto close scanner (dialog akan di-close otomatis di QRScannerDialog)
    } catch (e) {
      _showError('Error: ${e.toString()}');
      setState(() => _isProcessing = false);
    }
  }

  void _undoCheckIn(int index) {
    final user = _checkedInUsers[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Batalkan check-in untuk ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _checkedInUsers.removeAt(index);
              });
              Navigator.pop(context);
              _showSuccess('Check-in dibatalkan');
            },
            child: const Text('Ya', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
