import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';
import 'package:unit_activity/widgets/notification_bell_widget.dart';
import 'package:unit_activity/user/notifikasi_user.dart';
import 'package:unit_activity/user/profile.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/user/ukm.dart';
import 'package:unit_activity/user/history.dart';
import 'package:unit_activity/user/event_detail_user.dart';
import 'package:unit_activity/services/user_dashboard_service.dart';
import 'package:unit_activity/services/attendance_service.dart';
import 'package:unit_activity/services/custom_auth_service.dart';

class UserEventPage extends StatefulWidget {
  const UserEventPage({super.key});

  @override
  State<UserEventPage> createState() => _UserEventPageState();
}

class _UserEventPageState extends State<UserEventPage>
    with QRScannerMixin, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedMenu = 'event';
  final UserDashboardService _dashboardService = UserDashboardService();
  final AttendanceService _attendanceService = AttendanceService();
  final CustomAuthService _authService = CustomAuthService();

  // Tab controller for event categories
  late TabController _tabController;

  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _followedEvents = [];
  List<Map<String, dynamic>> _myUKMEvents = [];
  bool _isLoading = true;
  Set<String> _registeredEventIds = {};
  List<String> _userUKMIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Reload data when page becomes visible again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      // Only reload if not first time (initState already loads)
      if (_allEvents.isNotEmpty ||
          _followedEvents.isNotEmpty ||
          _myUKMEvents.isNotEmpty) {
        // Silent reload without showing loading indicator
        _loadEventsQuietly();
      }
    }
  }

  Future<void> _loadEventsQuietly() async {
    try {
      await _loadUserUKMs();
      final events = await _dashboardService.getAllEvents();
      final registeredEvents = await _dashboardService
          .getUserRegisteredEvents();

      _registeredEventIds = registeredEvents
          .map((e) {
            // Try to get from nested events object first (new structure)
            final eventsData = e['events'];
            if (eventsData != null && eventsData is Map) {
              return eventsData['id_events']?.toString() ?? '';
            }
            // Fallback to direct id_event field
            return e['id_event']?.toString() ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      if (mounted) {
        setState(() {
          _allEvents = events.map((event) {
            final eventId = event['id_events']?.toString() ?? '';
            final ukmId = event['id_ukm']?.toString() ?? '';
            return {
              'id': eventId,
              'id_ukm': ukmId,
              'title': event['nama_event'] ?? 'Event',
              'image': null,
              'date': _formatDate(event['tanggal_mulai']),
              'time':
                  '${event['jam_mulai'] ?? ''} - ${event['jam_akhir'] ?? ''} WIB',
              'location': event['lokasi'] ?? '',
              'description': event['deskripsi'] ?? '',
              'isRegistered': _registeredEventIds.contains(eventId),
              'isMyUKM': _userUKMIds.contains(ukmId),
              'ukm_name': event['ukm']?['nama_ukm'] ?? '',
              'ukm_logo': event['ukm']?['logo'],
              'max_participant': event['max_participant'],
              'tanggal_mulai': event['tanggal_mulai'],
              'tanggal_akhir': event['tanggal_akhir'],
              'jam_mulai': event['jam_mulai'],
              'jam_akhir': event['jam_akhir'],
              'id_events': eventId,
              'nama_event': event['nama_event'],
              'lokasi': event['lokasi'],
            };
          }).toList();

          _followedEvents = _allEvents
              .where((e) => e['isRegistered'] == true)
              .toList();
          _myUKMEvents = _allEvents.where((e) => e['isMyUKM'] == true).toList();
        });
      }
    } catch (e) {
      print('Error quietly reloading events: $e');
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      // Load user's joined UKMs
      await _loadUserUKMs();

      // Load all events from database
      final events = await _dashboardService.getAllEvents();

      // Load user's registered events
      final registeredEvents = await _dashboardService
          .getUserRegisteredEvents();

      print('========================================');
      print('DEBUG _loadEvents: Registered Events');
      print('Raw registered events count: ${registeredEvents.length}');
      print('Registered events data: $registeredEvents');

      // Get set of registered event IDs from peserta_event table
      // The 'events' key comes from the join with events table (id_event -> events)
      _registeredEventIds = registeredEvents
          .map((e) {
            // Try to get from nested events object first (new structure)
            final eventsData = e['events'];
            if (eventsData != null && eventsData is Map) {
              return eventsData['id_events']?.toString() ?? '';
            }
            // Fallback to direct id_event field
            return e['id_event']?.toString() ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      print('Registered event IDs: $_registeredEventIds');
      print('Total registered event IDs: ${_registeredEventIds.length}');

      // Map events to UI format with access control
      _allEvents = events.map((event) {
        final eventId = event['id_events']?.toString() ?? '';
        final ukmId = event['id_ukm']?.toString() ?? '';
        final tipeAkses = event['tipe_akses']?.toString().toLowerCase() ?? 'anggota';
        final isMyUKM = _userUKMIds.contains(ukmId);
        
        // Access control: umum events visible to all, anggota events only to UKM members
        final canView = tipeAkses == 'umum' || isMyUKM;
        
        return {
          'id': eventId,
          'id_ukm': ukmId,
          'tipe_akses': tipeAkses,
          'canView': canView,
          'title': event['nama_event'] ?? 'Event',
          'image': null,
          'date': _formatDate(event['tanggal_mulai']),
          'time':
              '${event['jam_mulai'] ?? ''} - ${event['jam_akhir'] ?? ''} WIB',
          'location': event['lokasi'] ?? '',
          'description': event['deskripsi'] ?? '',
          'isRegistered': _registeredEventIds.contains(eventId),
          'isMyUKM': isMyUKM,
          'ukm_name': event['ukm']?['nama_ukm'] ?? '',
          'ukm_logo': event['ukm']?['logo'],
          'max_participant': event['max_participant'],
          'tanggal_mulai': event['tanggal_mulai'],
          'tanggal_akhir': event['tanggal_akhir'],
          'jam_mulai': event['jam_mulai'],
          'jam_akhir': event['jam_akhir'],
          'id_events': eventId,
          'nama_event': event['nama_event'],
          'lokasi': event['lokasi'],
        };
      }).toList();

      // Filter events based on access control
      _allEvents = _allEvents.where((e) => e['canView'] == true).toList();

      // NEW: Filter expired events
      // If tanggal_akhir exists and is before today, hide it
      final now = DateTime.now();
      // Reset time to midnight for fair comparison if needed, or just compare exact time
      // Usually "Expired" means end date is passed.
      _allEvents = _allEvents.where((e) {
         final endDateStr = e['tanggal_akhir'];
         if (endDateStr != null) {
            try {
               final endDate = DateTime.parse(endDateStr);
               // If end date is BEFORE now (and maybe add buffer for 'today'?)
               // If endDate is 2023-01-01 and now is 2023-01-02, it's expired.
               if (endDate.isBefore(now)) {
                  // But if it's SAME day? usually events last until end of day.
                  // If endDate has time, use it. If not, assume end of day?
                  // Let's assume strict comparison for now.
                  return false; 
               }
            } catch (_) {}
         }
         return true;
      }).toList();

      // Filter followed events
      _followedEvents = _allEvents
          .where((e) => e['isRegistered'] == true)
          .toList();

      print('Total all events: ${_allEvents.length}');
      print('Total followed events: ${_followedEvents.length}');
      print('Followed events: $_followedEvents');

      // Filter events from user's UKMs
      _myUKMEvents = _allEvents.where((e) => e['isMyUKM'] == true).toList();

      print('Total my UKM events: ${_myUKMEvents.length}');
      print('========================================');

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserUKMs() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = _authService.currentUserId;

      if (userId == null || userId.isEmpty) {
        _userUKMIds = [];
        return;
      }

      final response = await supabase
          .from('user_halaman_ukm')
          .select('id_ukm')
          .eq('id_user', userId)
          .or('status.eq.aktif,status.eq.active');

      _userUKMIds = (response as List)
          .map((e) => e['id_ukm']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      print('DEBUG: User joined ${_userUKMIds.length} UKMs');
    } catch (e) {
      print('Error loading user UKMs: $e');
      _userUKMIds = [];
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      final days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _viewEventDetail(Map<String, dynamic> event) {
    // Navigate to detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserEventDetailPage(eventId: event['id_events']?.toString() ?? ''),
      ),
    ).then((_) {
      // Refresh data when returning
      _loadEvents();
    });
  }

  /// Register user for an event
  Future<void> _registerForEvent(String eventId, String eventName) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User tidak terautentikasi'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get event details for validation
      final eventData = await Supabase.instance.client
          .from('events')
          .select('tanggal_mulai, tanggal_akhir, max_participant, nama_event')
          .eq('id_events', eventId)
          .single();

      print('========================================');
      print('DEBUG _registerForEvent: Event Validation');
      print('Event: ${eventData['nama_event']}');
      print('Tanggal Mulai: ${eventData['tanggal_mulai']}');
      print('Tanggal Akhir: ${eventData['tanggal_akhir']}');
      print('Current DateTime: ${DateTime.now()}');

      // Check if event has ended - compare DATE only, not time
      if (eventData['tanggal_akhir'] != null) {
        final endDate = DateTime.parse(eventData['tanggal_akhir']);
        final now = DateTime.now();
        
        // Compare dates only (ignore time component)
        final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
        final nowDateOnly = DateTime(now.year, now.month, now.day);
        
        print('End Date (date only): $endDateOnly');
        print('Now (date only): $nowDateOnly');
        print('Is event ended? ${nowDateOnly.isAfter(endDateOnly)}');
        
        // Event is considered ended only if current DATE is AFTER end DATE
        if (nowDateOnly.isAfter(endDateOnly)) {
          print('❌ Event has ended - registration closed');
          print('========================================');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.event_busy, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Event sudah selesai. Pendaftaran ditutup.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[700],
              ),
            );
          }
          return;
        }
        print('✅ Event is still active - registration allowed');
      }
      print('========================================');

      // Check participant quota
      if (eventData['max_participant'] != null) {
        final maxParticipant = eventData['max_participant'] as int;
        
        // Count current registrations using Supabase count
        final response = await Supabase.instance.client
            .from('absen_event')
            .select('id_absen_e')
            .eq('id_event', eventId)
            .count(CountOption.exact);

        final currentCount = response.count;

        if (currentCount >= maxParticipant) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kuota peserta penuh ($currentCount/$maxParticipant)',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[700],
              ),
            );
          }
          return;
        }
      }

      // Check if already registered
      final existing = await Supabase.instance.client
          .from('absen_event')
          .select('id_absen_e')
          .eq('id_event', eventId)
          .eq('id_user', userId)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda sudah terdaftar di event ini'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Register to event
      final now = DateTime.now();
      await Supabase.instance.client.from('absen_event').insert({
        'id_event': eventId,
        'id_user': userId,
        'status': 'terdaftar',
        'jam':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      });

      if (mounted) {
        setState(() {
          _registeredEventIds.add(eventId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Berhasil mendaftar event: $eventName',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('ERROR _registerForEvent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendaftar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle QR Code scanned for attendance
  Future<void> _handleQRCodeScanned(String code) async {
    try {
      final result = await _attendanceService.processQRCodeAttendance(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result['success'] == true ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(result['message'] ?? 'Proses selesai')),
              ],
            ),
            backgroundColor: result['success'] == true
                ? Colors.green[600]
                : Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh events if successful
        if (result['success'] == true) {
          _loadEvents();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600]),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
                debugPrint('Error signing out: $e');
              }
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width < 1200;

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Top bar
          _buildFloatingTopBar(isMobile: true),
          const SizedBox(height: 16),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              indicator: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(height: 42, text: 'Seluruh Event'),
                Tab(height: 42, text: 'Event Diikuti'),
                Tab(height: 42, text: 'UKM Saya'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventTabContent(
                        _allEvents,
                        'Belum ada event tersedia',
                        isMobile: true,
                      ),
                      _buildEventTabContent(
                        _followedEvents,
                        'Belum ada event yang diikuti',
                        isMobile: true,
                      ),
                      _buildEventTabContent(
                        _myUKMEvents,
                        'Belum ada event dari UKM yang kamu ikuti',
                        isMobile: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Build event content for each tab
  Widget _buildEventTabContent(
    List<Map<String, dynamic>> events,
    String emptyMessage, {
    required bool isMobile,
  }) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: GridView.builder(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile
              ? 1
              : (MediaQuery.of(context).size.width < 1200 ? 2 : 3),
          mainAxisSpacing: isMobile ? 12 : 16,
          crossAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: isMobile ? 1.15 : 1.3,
        ),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(events[index]);
        },
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Row(
            children: [
              UserSidebar(
                selectedMenu: 'event',
                onMenuSelected: (menu) {
                  if (menu == 'dashboard') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardUser(),
                      ),
                    );
                  } else if (menu == 'ukm') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserUKMPage(),
                      ),
                    );
                  } else if (menu == 'histori') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                  } else if (menu == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  }
                },
                onLogout: _showLogoutDialog,
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70), // Space for floating top bar
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue[700],
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Colors.blue[700],
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Seluruh Event'),
                          Tab(text: 'Event yang Diikuti'),
                          Tab(text: 'Event dari UKM Saya'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEventTabContent(
                                  _allEvents,
                                  'Belum ada event tersedia',
                                  isMobile: false,
                                ),
                                _buildEventTabContent(
                                  _followedEvents,
                                  'Belum ada event yang diikuti',
                                  isMobile: false,
                                ),
                                _buildEventTabContent(
                                  _myUKMEvents,
                                  'Belum ada event dari UKM yang kamu ikuti',
                                  isMobile: false,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 260,
            right: 0,
            child: _buildFloatingTopBar(isMobile: false),
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Row(
            children: [
              UserSidebar(
                selectedMenu: 'event',
                onMenuSelected: (menu) {
                  if (menu == 'dashboard') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardUser(),
                      ),
                    );
                  } else if (menu == 'ukm') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserUKMPage(),
                      ),
                    );
                  } else if (menu == 'histori') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                  } else if (menu == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  }
                },
                onLogout: _showLogoutDialog,
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 70), // Space for floating top bar
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue[700],
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Colors.blue[700],
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Seluruh Event'),
                          Tab(text: 'Event yang Diikuti'),
                          Tab(text: 'Event dari UKM Saya'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildEventTabContent(
                                  _allEvents,
                                  'Belum ada event tersedia',
                                  isMobile: false,
                                ),
                                _buildEventTabContent(
                                  _followedEvents,
                                  'Belum ada event yang diikuti',
                                  isMobile: false,
                                ),
                                _buildEventTabContent(
                                  _myUKMEvents,
                                  'Belum ada event dari UKM yang kamu ikuti',
                                  isMobile: false,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 260,
            right: 0,
            child: _buildFloatingTopBar(isMobile: false),
          ),
        ],
      ),
    );
  }

  // ==================== FLOATING TOP BAR ====================
  Widget _buildFloatingTopBar({required bool isMobile}) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NotificationBellWidget(
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotifikasiUserPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    } else if (value == 'logout') {
                      _showLogoutDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          const Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.red[600]),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // QR Scanner Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => openQRScannerDialog(
                      onCodeScanned: _handleQRCodeScanned,
                    ),
                    icon: Icon(Icons.qr_code_scanner, color: Colors.blue[700]),
                    tooltip: 'Scan QR Code',
                  ),
                ),
                const SizedBox(width: 12),
                NotificationBellWidget(
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotifikasiUserPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    } else if (value == 'logout') {
                      _showLogoutDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          const Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.red[600]),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF4169E1).withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF4169E1),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ==================== EVENT CARD ====================
  Widget _buildEventCard(Map<String, dynamic> event) {
    final String eventId = event['id_events']?.toString() ?? '';
    final String? imageUrl = event['gambar'];
    final String title = event['nama_event'] ?? 'Event';
    final String location = event['lokasi'] ?? '-';
    final String? dateStr = event['tanggal_mulai'];
    final bool isRegistered = _registeredEventIds.contains(event['id_events']);
    final bool isMyUKM = event['isMyUKM'] == true;
    final String ukmName = event['ukm_name'] ?? '';
    // ukm_logo available in event['ukm_logo'] if needed

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section - Fixed height instead of flex
          SizedBox(
            height: 140,
            child: InkWell(
              onTap: () => _viewEventDetail(event),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            cacheWidth: 400, // Optimize memory
                            cacheHeight: 300,
                            loadingBuilder:
                                (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value:
                                          loadingProgress
                                                  .expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.event,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.event,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  // UKM Badge
                  if (ukmName.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isMyUKM
                              ? Colors.purple[700]
                              : Colors.blue[700],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMyUKM ? Icons.star : Icons.groups,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                ukmName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Top-right badge: Access type or Registration status
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isRegistered
                            ? Colors.green
                            : (event['tipe_akses'] == 'umum'
                                ? Colors.green[600]
                                : Colors.blue[600]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRegistered
                                ? Icons.check
                                : (event['tipe_akses'] == 'umum'
                                    ? Icons.public
                                    : Icons.group),
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRegistered
                                ? 'Terdaftar'
                                : (event['tipe_akses'] == 'umum'
                                    ? 'Umum'
                                    : 'Anggota'),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content Section - Flexible to fill remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Event details - takes available space
                  Expanded(
                    child: InkWell(
                      onTap: () => _viewEventDetail(event),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  dateStr != null ? _formatDate(dateStr) : '-',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Registration Button - Always visible at bottom
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: isRegistered
                          ? () => _viewEventDetail(event)
                          : () => _registerForEvent(eventId, title),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRegistered
                            ? Colors.green[600]
                            : Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: isRegistered ? 0 : 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRegistered ? Icons.check_circle : Icons.person_add,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isRegistered ? 'Terdaftar' : 'Daftar',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM NAVIGATION BAR ====================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Dashboard
                _buildNavItem(
                  Icons.home_rounded,
                  'Dashboard',
                  _selectedMenu == 'dashboard',
                  () => _handleMenuSelected('dashboard'),
                ),
                // Event
                _buildNavItem(
                  Icons.event_rounded,
                  'Event',
                  _selectedMenu == 'event',
                  () => _handleMenuSelected('event'),
                ),
                // Center QR Scanner button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[600],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => openQRScannerDialog(
                        onCodeScanned: _handleQRCodeScanned,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                // UKM
                _buildNavItem(
                  Icons.school_rounded,
                  'UKM',
                  _selectedMenu == 'ukm',
                  () => _handleMenuSelected('ukm'),
                ),
                // History
                _buildNavItem(
                  Icons.history_rounded,
                  'History',
                  _selectedMenu == 'history',
                  () => _handleMenuSelected('history'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NAV ITEM WIDGET ====================
  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue[600] : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MENU HANDLERS ====================
  void _handleMenuSelected(String menu) {
    if (_selectedMenu == menu) return;

    setState(() {
      _selectedMenu = menu;
    });

    switch (menu) {
      case 'dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardUser()),
        );
        break;
      case 'event':
        // Already on event page
        break;
      case 'ukm':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserUKMPage()),
        );
        break;
      case 'history':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
        break;
    }
  }
}
