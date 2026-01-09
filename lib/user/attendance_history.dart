import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';
import 'package:unit_activity/widgets/notification_bell_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:unit_activity/services/attendance_service.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/user/event.dart';
import 'package:unit_activity/user/ukm.dart';
import 'package:unit_activity/user/profile.dart';

/// Halaman History Absensi User
/// Menampilkan riwayat absensi event dan pertemuan UKM
class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage>
    with QRScannerMixin, SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceService _attendanceService = AttendanceService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _attendanceHistory = [];
  late TabController _tabController;
  String _selectedFilter = 'all'; // all, event, pertemuan

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = ['all', 'event', 'pertemuan'][_tabController.index];
        });
      }
    });
    _loadAttendanceHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() => _isLoading = true);

    try {
      final history = await _attendanceService.getUserAttendanceHistory();
      setState(() {
        _attendanceHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attendance history: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat absensi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == 'all') return _attendanceHistory;
    return _attendanceHistory
        .where((item) => item['type'] == _selectedFilter)
        .toList();
  }

  Future<void> _handleQRScan(String qrCode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _attendanceService.processQRCodeAttendance(qrCode);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result['success'] == true) {
        // Success
        _showSuccessDialog(result);
        // Reload history
        await _loadAttendanceHistory();
      } else {
        // Error
        _showErrorDialog(result['message'] ?? 'Gagal mencatat kehadiran');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Berhasil!', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ?? 'Absensi berhasil dicatat',
              style: const TextStyle(fontSize: 16),
            ),
            if (result['time'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Waktu: ${result['time']}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Gagal', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade100,
      drawer: UserSidebar(
        selectedMenu: 'histori',
        onMenuSelected: (menu) {
          Navigator.pop(context); // Close drawer
          if (menu == 'dashboard') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardUser()),
            );
          } else if (menu == 'event') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserEventPage()),
            );
          } else if (menu == 'ukm') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserUKMPage()),
            );
          } else if (menu == 'profile') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        onLogout: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Riwayat Absensi',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          buildQRScannerButton(
            onCodeScanned: _handleQRScan,
            icon: Icons.qr_code_scanner,
            tooltip: 'Scan QR Absensi',
          ),
          NotificationBellWidget(
            onViewAll: () {
              Navigator.pushNamed(context, '/user/notifikasi');
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF060A47),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF060A47),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Event'),
                Tab(text: 'Pertemuan'),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          openQRScannerDialog(
            onCodeScanned: _handleQRScan,
            title: 'Scan QR Absensi',
          );
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
        backgroundColor: const Color(0xFF060A47),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredList = _filteredHistory;

    if (filteredList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAttendanceHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final item = filteredList[index];
          return _buildAttendanceCard(item);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Belum ada riwayat absensi';
    String description = 'Scan QR Code untuk mencatat kehadiran Anda';

    if (_selectedFilter == 'event') {
      message = 'Belum ada absensi event';
      description = 'Absensi event Anda akan muncul di sini';
    } else if (_selectedFilter == 'pertemuan') {
      message = 'Belum ada absensi pertemuan';
      description = 'Absensi pertemuan UKM Anda akan muncul di sini';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              openQRScannerDialog(
                onCodeScanned: _handleQRScan,
                title: 'Scan QR Absensi',
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF060A47),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    final isEvent = item['type'] == 'event';
    final color = isEvent ? Colors.orange : Colors.blue;
    final icon = isEvent ? Icons.event : Icons.groups;

    // Parse date
    final recordedAt = DateTime.tryParse(item['recorded_at'] ?? '');
    final formattedDate = recordedAt != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(recordedAt)
        : '-';

    // Parse event/meeting date
    final eventDate = DateTime.tryParse(item['date'] ?? '');
    final formattedEventDate = eventDate != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(eventDate)
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Optional: Show detail dialog
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item['name'] ?? 'Kegiatan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isEvent ? 'Event' : 'Pertemuan UKM',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Details
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Tanggal Kegiatan: $formattedEventDate',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.access_time, 'Absen: $formattedDate'),
                    if (item['location'] != null &&
                        item['location'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.location_on, item['location']),
                    ],
                    const SizedBox(height: 8),
                    // Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['status']?.toString().toUpperCase() ??
                                    'HADIR',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
