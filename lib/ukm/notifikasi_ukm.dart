import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/ukm/send_notifikasi_ukm_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';
import 'package:intl/intl.dart';

class NotifikasiUKMPage extends StatefulWidget {
  const NotifikasiUKMPage({super.key});

  @override
  State<NotifikasiUKMPage> createState() => _NotifikasiUKMPageState();
}

class _NotifikasiUKMPageState extends State<NotifikasiUKMPage> {
  final _supabase = Supabase.instance.client;
  final _dashboardService = UkmDashboardService();

  int _currentPage = 1;
  List<Map<String, dynamic>> _notifikasiList = [];
  bool _isLoading = true;
  String? _currentUkmId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Get current UKM
      final ukmDetails = await _dashboardService.getCurrentUkmDetails();
      if (ukmDetails != null) {
        _currentUkmId = ukmDetails['id_ukm'];

        // Load notifications sent by this UKM
        final notifications = await _supabase
            .from('notification_preference')
            .select('*')
            .eq('id_ukm', _currentUkmId!)
            .order('create_at', ascending: false);

        setState(() {
          _notifikasiList = List<Map<String, dynamic>>.from(notifications);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height for calculating container height
    final screenHeight = MediaQuery.of(context).size.height;
    final tableHeight = screenHeight - 300; // Account for header, padding, etc.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Notifikasi',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SendNotifikasiUKMPage(),
                  ),
                );
                if (result == true) {
                  _loadNotifications();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.send, size: 20),
              label: Text(
                'Kirim Notifikasi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Table Container
        SizedBox(
          height: tableHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: isMobile
                                ? Icon(
                                    Icons.title,
                                    size: 18,
                                    color: Colors.grey[700],
                                  )
                                : Text(
                                    'Judul',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                          ),
                          Expanded(
                            flex: 3,
                            child: isMobile
                                ? Icon(
                                    Icons.message,
                                    size: 18,
                                    color: Colors.grey[700],
                                  )
                                : Text(
                                    'Pesan',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                          ),
                          Expanded(
                            flex: 2,
                            child: isMobile
                                ? Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Colors.grey[700],
                                  )
                                : Text(
                                    'Tanggal',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                          ),
                          Expanded(
                            flex: 2,
                            child: isMobile
                                ? Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.grey[700],
                                  )
                                : Text(
                                    'Status',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 80),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _notifikasiList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada notifikasi',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _notifikasiList.length,
                              itemBuilder: (context, index) {
                                final notif = _notifikasiList[index];
                                final tanggal = notif['create_at'] != null
                                    ? DateFormat('dd-MM-yyyy HH:mm').format(
                                        DateTime.parse(notif['create_at']),
                                      )
                                    : '-';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          notif['judul'] ?? '-',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          notif['pesan'] ?? '-',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          tanggal,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F0FE),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            notif['type'] ?? 'info',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFF4169E1),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 80),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Pagination
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            color: const Color(0xFF4169E1),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '$_currentPage',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4169E1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _currentPage++;
                              });
                            },
                            icon: const Icon(Icons.chevron_right),
                            color: const Color(0xFF4169E1),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
