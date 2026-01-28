import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'send_notifikasi_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allNotifications = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua'; // Semua, Broadcast, Individual

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalNotifications = 0;
  int _totalPages = 1;

  // Hidden notifications (visual delete - not from database)
  final Set<String> _hiddenNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      // First, get total count for pagination
      dynamic countQuery = _supabase
          .from('notification_preference')
          .select('id_notification_pref');

      // Apply filter
      if (_filterStatus == 'Broadcast') {
        countQuery = countQuery.eq('is_broadcast', true);
      } else if (_filterStatus == 'Individual') {
        countQuery = countQuery.eq('is_broadcast', false);
      }

      final countResponse = await countQuery;
      _totalNotifications = (countResponse as List).length;
      _totalPages = (_totalNotifications / _itemsPerPage).ceil();
      if (_totalPages < 1) _totalPages = 1;
      if (_currentPage > _totalPages) _currentPage = _totalPages;

      // Calculate range for pagination
      final startIndex = (_currentPage - 1) * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage - 1;

      // Fetch notifications with pagination
      dynamic query = _supabase.from('notification_preference').select();

      // Apply filter
      if (_filterStatus == 'Broadcast') {
        query = query.eq('is_broadcast', true);
      } else if (_filterStatus == 'Individual') {
        query = query.eq('is_broadcast', false);
      }

      // Apply order and pagination
      query = query
          .order('create_at', ascending: false)
          .range(startIndex, endIndex);

      final response = await query;
      final notifications = List<Map<String, dynamic>>.from(response);

      // For broadcast notifications, fetch read counts from notification_read_status
      for (var notification in notifications) {
        if (notification['is_broadcast'] == true) {
          final notifId = notification['id_notification_pref'];
          final readCountResponse = await _supabase
              .from('notification_read_status')
              .select('id')
              .eq('id_notification_pref', notifId)
              .eq('is_read', true);
          notification['read_count'] = (readCountResponse as List).length;

          // Also get total recipients count
          final totalRecipientsResponse = await _supabase
              .from('notification_read_status')
              .select('id')
              .eq('id_notification_pref', notifId);
          notification['total_recipients'] =
              (totalRecipientsResponse as List).length;
        }
      }

      // Filter out hidden notifications
      final visibleNotifications = notifications
          .where(
            (n) => !_hiddenNotifications.contains(n['id_notification_pref']),
          )
          .toList();

      setState(() {
        _allNotifications = visibleNotifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  // Hapus satu notifikasi dari tampilan visual (tidak hapus dari database)
  void _hideNotification(String notificationId) {
    setState(() {
      _hiddenNotifications.add(notificationId);
      _allNotifications.removeWhere(
        (n) => n['id_notification_pref'] == notificationId,
      );
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifikasi dihapus dari tampilan'),
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Batalkan',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _hiddenNotifications.remove(notificationId);
            });
            _loadNotifications();
          },
        ),
      ),
    );
  }

  // Hapus SEMUA notifikasi dari tampilan visual (clear history view)
  void _clearAllVisualNotifications() {
    if (_allNotifications.isEmpty) return;

    // Simpan semua ID untuk undo
    final allIds = _allNotifications
        .map((n) => n['id_notification_pref'].toString())
        .toList();

    setState(() {
      _hiddenNotifications.addAll(allIds);
      _allNotifications.clear();
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Semua notifikasi dihapus dari tampilan'),
        backgroundColor: const Color(0xFF4169E1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Batalkan',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _hiddenNotifications.removeAll(allIds);
            });
            _loadNotifications();
          },
        ),
      ),
    );
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notification_preference')
          .delete()
          .eq('id_notification_pref', notificationId);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi berhasil dihapus'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _loadNotifications();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // For admin, show total sent count instead of unread
    final totalSent = _totalNotifications;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isMobile ? 24 : 24),

          // Modern Header with Gradient
          _buildModernHeader(isMobile, isDesktop, totalSent),
          SizedBox(height: isMobile ? 16 : 24),

          // Filter Tabs
          _buildFilterTabs(isMobile),
          SizedBox(height: isMobile ? 16 : 24),

          // Notifications List
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_allNotifications.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allNotifications.length,
              itemBuilder: (context, index) {
                final notification = _allNotifications[index];
                return _buildNotificationCard(notification, isMobile);
              },
            ),

          // Pagination
          if (!_isLoading && _allNotifications.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isMobile ? 16 : 24),
              child: _buildPagination(),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isMobile, bool isDesktop, int unreadCount) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : (isDesktop ? 32 : 24)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4169E1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: isMobile ? 24 : (isDesktop ? 32 : 28),
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
                            fontSize: isMobile ? 18 : (isDesktop ? 28 : 24),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total notifikasi terkirim',
                              style: GoogleFonts.inter(
                                fontSize: isDesktop ? 16 : 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 20),
              Row(
                children: [
                  // Tombol Kirim Notifikasi
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SendNotifikasiPage(),
                          ),
                        );
                        if (result == true) {
                          _loadNotifications();
                        }
                      },
                      icon: Icon(Icons.send, size: isMobile ? 16 : 18),
                      label: Text(
                        'Kirim Notifikasi',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4169E1),
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 10 : 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Hapus Semua Visual
                  ElevatedButton.icon(
                    onPressed: _allNotifications.isEmpty
                        ? null
                        : _clearAllVisualNotifications,
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      size: isMobile ? 16 : 18,
                    ),
                    label: Text(
                      isMobile ? 'Hapus' : 'Hapus Semua',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 14,
                        horizontal: isMobile ? 12 : 16,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterTab('Semua', isMobile),
          SizedBox(width: isMobile ? 6 : 8),
          _buildFilterTab('Broadcast', isMobile),
          SizedBox(width: isMobile ? 6 : 8),
          _buildFilterTab('Individual', isMobile),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isMobile) {
    final isSelected = _filterStatus == label;

    return Expanded(
      flex: label == 'Semua' ? 1 : 2, // Give more space to longer labels
      child: InkWell(
        onTap: () {
          setState(() => _filterStatus = label);
          _loadNotifications();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 8 : 12,
            horizontal: isMobile ? 4 : 12,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4169E1), Color(0xFF5B7FE8)],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4169E1).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                label == 'Semua'
                    ? Icons.notifications_rounded
                    : label == 'Broadcast'
                    ? Icons.campaign_rounded
                    : Icons.person_rounded,
                size: isMobile ? 18 : 22,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 10 : 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      letterSpacing: 0,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    bool isMobile,
  ) {
    // Admin adalah PENGIRIM, bukan penerima - jadi tidak ada logika is_read
    final type = notification['type'] ?? 'info';

    return Dismissible(
      key: Key(notification['id_notification_pref'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              'Hapus',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hapus Notifikasi',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus notifikasi ini dari database?',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Hapus',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteNotification(notification['id_notification_pref'].toString());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
        decoration: BoxDecoration(
          // Style yang sama untuk semua notifikasi (admin adalah pengirim)
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with gradient background
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getNotificationColor(type),
                      _getNotificationColor(type).withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getNotificationColor(type).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: Colors.white,
                  size: isMobile ? 20 : 26,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row - tanpa badge "BARU" karena admin adalah pengirim
                    Text(
                      notification['judul'] ?? 'Notifikasi',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 10,
                            vertical: isMobile ? 3 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(
                              type,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getNotificationTypeName(type),
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: _getNotificationColor(type),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show broadcast target badge
                        if (notification['is_broadcast'] == true)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 10,
                              vertical: isMobile ? 3 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.campaign_rounded,
                                  size: isMobile ? 12 : 14,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notification['target_audience'] == 'all_users'
                                      ? 'SEMUA USER'
                                      : notification['target_audience'] ==
                                            'all_ukm'
                                      ? 'SEMUA UKM'
                                      : 'BROADCAST',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 10 : 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green[700],
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 8 : 10),
                    Text(
                      notification['pesan'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    // Time and read count row
                    Row(
                      children: [
                        // Time badge
                        Container(
                          padding: EdgeInsets.all(isMobile ? 8 : 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: isMobile ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: isMobile ? 4 : 6),
                              Text(
                                _formatDateTime(notification['create_at']),
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 10 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Read count badge (for broadcast notifications)
                        if (notification['is_broadcast'] == true)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 10,
                              vertical: isMobile ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  size: isMobile ? 12 : 14,
                                  color: const Color(0xFF4169E1),
                                ),
                                SizedBox(width: isMobile ? 4 : 6),
                                Text(
                                  'Dibaca ${notification['read_count'] ?? 0}/${notification['total_recipients'] ?? 0}',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4169E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        // Hide button - hapus dari tampilan visual
                        InkWell(
                          onTap: () => _hideNotification(
                            notification['id_notification_pref'].toString(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: isMobile ? 14 : 16,
                                  color: Colors.red[600],
                                ),
                                if (!isMobile) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hapus',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
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

  String _getNotificationTypeName(String type) {
    switch (type) {
      case 'event':
        return 'EVENT';
      case 'document':
        return 'DOKUMEN';
      case 'approval':
        return 'PERSETUJUAN';
      case 'warning':
        return 'PERINGATAN';
      case 'user':
        return 'USER';
      default:
        return 'INFO';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[100]!, Colors.grey[50]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tidak ada notifikasi',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _filterStatus == 'Semua'
                  ? 'Notifikasi akan muncul di sini'
                  : _filterStatus == 'Belum Dibaca'
                  ? 'Semua notifikasi sudah dibaca'
                  : 'Belum ada notifikasi yang dibaca',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'document':
        return Icons.description;
      case 'approval':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'user':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'event':
        return const Color(0xFF4169E1);
      case 'document':
        return Colors.orange;
      case 'approval':
        return Colors.green;
      case 'warning':
        return Colors.red;
      case 'user':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Baru saja';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else {
        return DateFormat('dd MMM yyyy, HH:mm').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildPagination() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                Text(
                  'Halaman $_currentPage dari $_totalPages',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() => _currentPage--);
                        _loadNotifications();
                      },
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4169E1).withValues(alpha: 0.1),
                            const Color(0xFF4169E1).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() => _currentPage++);
                        _loadNotifications();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage) > _totalNotifications ? _totalNotifications : (_currentPage * _itemsPerPage)} dari $_totalNotifications',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menampilkan ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage * _itemsPerPage) > _totalNotifications ? _totalNotifications : (_currentPage * _itemsPerPage)} dari $_totalNotifications notifikasi',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    _buildPageButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onPressed: () {
                        setState(() => _currentPage--);
                        _loadNotifications();
                      },
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4169E1).withValues(alpha: 0.1),
                            const Color(0xFF4169E1).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4169E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPageButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onPressed: () {
                        setState(() => _currentPage++);
                        _loadNotifications();
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF4169E1) : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.grey[500],
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
