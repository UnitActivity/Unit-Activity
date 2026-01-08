import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unit_activity/ukm/send_notifikasi_ukm_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/services/ukm_dashboard_service.dart';

class NotifikasiUKMPage extends StatefulWidget {
  const NotifikasiUKMPage({super.key});

  @override
  State<NotifikasiUKMPage> createState() => _NotifikasiUKMPageState();
}

class _NotifikasiUKMPageState extends State<NotifikasiUKMPage> {
  final _supabase = Supabase.instance.client;
  final _dashboardService = UkmDashboardService();

  List<Map<String, dynamic>> _notifikasiList = [];
  bool _isLoading = true;
  String? _currentUkmId;
  String _selectedTab = 'Semua'; // Semua, Belum Dibaca, Sudah Dibaca

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
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Gradient
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4169E1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: isMobile ? 24 : 32,
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifikasi',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 20 : 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (!isMobile)
                            Text(
                              'Semua notifikasi sudah dibaca',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(
                      'Kirim Notifikasi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4169E1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                _buildTab('Semua', Icons.notifications_rounded),
                const SizedBox(width: 6),
                _buildTab('Belum Dibaca', Icons.mark_email_unread_rounded),
                const SizedBox(width: 6),
                _buildTab('Sudah Dibaca', Icons.mark_email_read_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications List
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _notifikasiList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _notifikasiList.length,
                  itemBuilder: (context, index) {
                    final notif = _notifikasiList[index];
                    return _buildNotificationCard(notif);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon) {
    final isSelected = _selectedTab == label;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = label),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: isMobile
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label.split(' ').first, // Only show first word on mobile
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final type = notif['type'] ?? 'info';
    final isWarning =
        type.toLowerCase() == 'warning' || type.toLowerCase() == 'peringatan';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? Colors.red.withOpacity(0.2)
              : const Color(0xFF4169E1).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isWarning
                ? Colors.red.withOpacity(0.08)
                : const Color(0xFF4169E1).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: isWarning ? Colors.red : const Color(0xFF4169E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isWarning ? Icons.warning_rounded : Icons.info_rounded,
                  color: Colors.white,
                  size: isMobile ? 18 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 10,
                            vertical: isMobile ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isWarning
                                ? Colors.red
                                : const Color(0xFF4169E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isWarning ? 'PERINGATAN' : 'INFO',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 9 : 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!isMobile) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _getTimeAgo(notif['create_at']),
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 10 : 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notif['judul'] ?? 'Tanpa Judul',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w700,
                        color: isWarning ? Colors.red : const Color(0xFF4169E1),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['pesan'] ?? '-',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: isMobile ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada notifikasi',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(dynamic createAt) {
    if (createAt == null) return 'Baru saja';

    try {
      final dateTime = DateTime.parse(createAt.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit yang lalu';
      }
      return 'Baru saja';
    } catch (e) {
      return 'Baru saja';
    }
  }
}
