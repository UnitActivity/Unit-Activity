import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allNotifications = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua'; // Semua, Belum Dibaca, Sudah Dibaca

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      dynamic query = _supabase.from('notifikasi').select();

      // Apply filter
      if (_filterStatus == 'Belum Dibaca') {
        query = query.eq('is_read', false);
      } else if (_filterStatus == 'Sudah Dibaca') {
        query = query.eq('is_read', true);
      }

      // Apply order after filter
      query = query.order('created_at', ascending: false);

      final response = await query;

      setState(() {
        _allNotifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifikasi')
          .update({'is_read': true})
          .eq('id_notifikasi', notificationId);

      _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase
          .from('notifikasi')
          .update({'is_read': true})
          .eq('is_read', false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi ditandai sudah dibaca'),
          backgroundColor: Colors.green,
        ),
      );

      _loadNotifications();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifikasi')
          .delete()
          .eq('id_notifikasi', notificationId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      _loadNotifications();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final unreadCount = _allNotifications
        .where((n) => n['is_read'] == false)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifikasi',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unreadCount notifikasi belum dibaca',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: Text(
                      'Tandai Semua Dibaca',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4169E1),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showSendNotificationDialog(context),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(
                    'Kirim Notifikasi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Filter Tabs
        _buildFilterTabs(),
        const SizedBox(height: 24),

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
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allNotifications.length,
              itemBuilder: (context, index) {
                final notification = _allNotifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          _buildFilterTab('Semua'),
          _buildFilterTab('Belum Dibaca'),
          _buildFilterTab('Sudah Dibaca'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _filterStatus == label;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _filterStatus = label);
          _loadNotifications();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4169E1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? 'info';

    return Dismissible(
      key: Key(notification['id_notifikasi'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Hapus Notifikasi',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus notifikasi ini?',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal', style: GoogleFonts.inter()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Hapus', style: GoogleFonts.inter()),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteNotification(notification['id_notifikasi'].toString());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : const Color(0xFF4169E1).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Colors.grey[200]!
                : const Color(0xFF4169E1).withOpacity(0.2),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _markAsRead(notification['id_notifikasi'].toString());
            }
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
                    color: _getNotificationColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? 'Notifikasi',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4169E1),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['message'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDateTime(notification['created_at']),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada notifikasi',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notifikasi akan muncul di sini',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
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

  void _showSendNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'info';
    String selectedTarget =
        'all_users'; // all_users, all_ukm, specific_ukm, specific_user

    // For event/info linking
    String? selectedEventId;
    String? selectedInfoId;

    // For multi-select
    List<String> selectedUkmIds = [];
    List<String> selectedUserIds = [];

    // Sample data - replace with actual Supabase queries
    final sampleEvents = [
      {'id': '1', 'nama': 'Sparing w/ UWIKA'},
      {'id': '2', 'nama': 'Friendly Match Futsal'},
      {'id': '3', 'nama': 'Mini Tournament Badminton'},
    ];

    final sampleInfo = [
      {'id': '1', 'judul': 'Pendaftaran UKM Dibuka'},
      {'id': '2', 'judul': 'Pengumuman Kegiatan'},
    ];

    final sampleUkm = [
      {'id': '1', 'nama': 'Basket'},
      {'id': '2', 'nama': 'Futsal'},
      {'id': '3', 'nama': 'Badminton'},
    ];

    final sampleUsers = [
      {'id': '1', 'nama': 'John Doe', 'email': 'john@example.com'},
      {'id': '2', 'nama': 'Jane Smith', 'email': 'jane@example.com'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Kirim Notifikasi',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  Text(
                    'Judul Notifikasi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan judul notifikasi',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                        borderSide: const BorderSide(color: Color(0xFF4169E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message Field
                  Text(
                    'Pesan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Masukkan pesan notifikasi',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                        borderSide: const BorderSide(color: Color(0xFF4169E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type Dropdown
                  Text(
                    'Tipe Notifikasi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
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
                        borderSide: const BorderSide(color: Color(0xFF4169E1)),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text('Info', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'event',
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              color: Color(0xFF4169E1),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text('Event', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'document',
                        child: Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text('Dokumen', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'approval',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text('Persetujuan', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'warning',
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text('Peringatan', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'user',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.purple, size: 20),
                            const SizedBox(width: 8),
                            Text('User', style: GoogleFonts.inter()),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                        selectedEventId = null;
                        selectedInfoId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Conditional: Event Selection
                  if (selectedType == 'event') ...[
                    Text(
                      'Pilih Event',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedEventId,
                      hint: Text('Pilih event', style: GoogleFonts.inter()),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      items: sampleEvents.map((event) {
                        return DropdownMenuItem<String>(
                          value: event['id'],
                          child: Text(
                            event['nama']!,
                            style: GoogleFonts.inter(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedEventId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Conditional: Info Selection
                  if (selectedType == 'info') ...[
                    Text(
                      'Pilih Informasi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedInfoId,
                      hint: Text('Pilih informasi', style: GoogleFonts.inter()),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      items: sampleInfo.map((info) {
                        return DropdownMenuItem<String>(
                          value: info['id'],
                          child: Text(
                            info['judul']!,
                            style: GoogleFonts.inter(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedInfoId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Target Dropdown
                  Text(
                    'Kirim Ke',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTarget,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
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
                        borderSide: const BorderSide(color: Color(0xFF4169E1)),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all_users',
                        child: Text(
                          'Semua Pengguna',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'all_ukm',
                        child: Text('Semua UKM', style: GoogleFonts.inter()),
                      ),
                      DropdownMenuItem(
                        value: 'specific_ukm',
                        child: Text('Pilih UKM', style: GoogleFonts.inter()),
                      ),
                      DropdownMenuItem(
                        value: 'specific_user',
                        child: Text(
                          'Pilih Pengguna',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedTarget = value!;
                        selectedUkmIds.clear();
                        selectedUserIds.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Conditional: UKM Multi-Select
                  if (selectedTarget == 'specific_ukm') ...[
                    Text(
                      'Pilih UKM (${selectedUkmIds.length} dipilih)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: sampleUkm.map((ukm) {
                          final isSelected = selectedUkmIds.contains(ukm['id']);
                          return CheckboxListTile(
                            title: Text(
                              ukm['nama']!,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedUkmIds.add(ukm['id']!);
                                } else {
                                  selectedUkmIds.remove(ukm['id']);
                                }
                              });
                            },
                            activeColor: const Color(0xFF4169E1),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Conditional: User Multi-Select
                  if (selectedTarget == 'specific_user') ...[
                    Text(
                      'Pilih Pengguna (${selectedUserIds.length} dipilih)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: sampleUsers.map((user) {
                          final isSelected = selectedUserIds.contains(
                            user['id'],
                          );
                          return CheckboxListTile(
                            title: Text(
                              user['nama']!,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            subtitle: Text(
                              user['email']!,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedUserIds.add(user['id']!);
                                } else {
                                  selectedUserIds.remove(user['id']);
                                }
                              });
                            },
                            activeColor: const Color(0xFF4169E1),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Validation
                if (titleController.text.trim().isEmpty ||
                    messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Judul dan pesan tidak boleh kosong'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedTarget == 'specific_ukm' &&
                    selectedUkmIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih minimal 1 UKM'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedTarget == 'specific_user' &&
                    selectedUserIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih minimal 1 pengguna'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _sendNotification(
                  titleController.text.trim(),
                  messageController.text.trim(),
                  selectedType,
                  selectedTarget,
                  eventId: selectedEventId,
                  infoId: selectedInfoId,
                  ukmIds: selectedUkmIds,
                  userIds: selectedUserIds,
                );
              },
              icon: const Icon(Icons.send, size: 18),
              label: Text(
                'Kirim',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendNotification(
    String title,
    String message,
    String type,
    String target, {
    String? eventId,
    String? infoId,
    List<String>? ukmIds,
    List<String>? userIds,
  }) async {
    try {
      // Prepare notification data
      final notificationData = {
        'judul': title,
        'pesan': message,
        'type': type,
        'is_read': false,
        'create_at': DateTime.now().toIso8601String(),
      };

      // Add optional foreign keys
      if (eventId != null) {
        notificationData['id_events'] = eventId;
      }
      if (infoId != null) {
        notificationData['id_informasi'] = infoId;
      }

      // Send based on target
      if (target == 'all_users') {
        // Get all users and insert notification for each
        final users = await _supabase.from('users').select('id_user');
        for (var user in users) {
          await _supabase.from('notification_preference').insert({
            ...notificationData,
            'id_user': user['id_user'],
          });
        }
      } else if (target == 'all_ukm') {
        // Get all UKM and insert notification for each
        final ukms = await _supabase.from('ukm').select('id_ukm');
        for (var ukm in ukms) {
          await _supabase.from('notification_preference').insert({
            ...notificationData,
            'id_ukm': ukm['id_ukm'],
          });
        }
      } else if (target == 'specific_ukm' && ukmIds != null) {
        // Insert for selected UKMs
        for (var ukmId in ukmIds) {
          await _supabase.from('notification_preference').insert({
            ...notificationData,
            'id_ukm': ukmId,
          });
        }
      } else if (target == 'specific_user' && userIds != null) {
        // Insert for selected users
        for (var userId in userIds) {
          await _supabase.from('notification_preference').insert({
            ...notificationData,
            'id_user': userId,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifikasi berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );

      _loadNotifications();
    } catch (e) {
      print('Error sending notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim notifikasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
}
