import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_activity/widgets/qr_scanner_mixin.dart';
import 'package:unit_activity/widgets/notification_bell_widget.dart';
import 'package:unit_activity/widgets/user_sidebar.dart';
import 'package:unit_activity/user/notifikasi_user.dart';
import 'package:unit_activity/user/profile.dart';
import 'package:unit_activity/user/dashboard_user.dart';
import 'package:unit_activity/user/event.dart';
import 'package:unit_activity/user/history.dart';
import 'package:unit_activity/services/custom_auth_service.dart';
import 'package:unit_activity/services/pertemuan_service.dart';
import 'package:unit_activity/services/attendance_service.dart';

class UserUKMPage extends StatefulWidget {
  const UserUKMPage({super.key});

  @override
  State<UserUKMPage> createState() => _UserUKMPageState();
}

class _UserUKMPageState extends State<UserUKMPage> with QRScannerMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomAuthService _authService = CustomAuthService();
  final AttendanceService _attendanceService = AttendanceService();

  String _selectedMenu = 'UKM';
  Map<String, dynamic>? _selectedUKM;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _allUKMs = [];
  List<Map<String, dynamic>> _ukmPertemuanList = [];
  List<Map<String, dynamic>> _ukmEventsList = [];
  bool _isLoadingPertemuan = false;
  bool _isLoadingEvents = false;
  Map<String, dynamic>? _currentPeriode; // Store current periode info
  late final _LifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _LifecycleObserver(_onResume);
    _initializeAndLoad();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  Future<void> _initializeAndLoad() async {
    // Initialize auth service first to restore session
    await _authService.initialize();
    _loadUKMs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  void _onResume() {
    if (mounted) {
      debugPrint('DEBUG: App resumed, reloading UKM data');
      _loadUKMs();
    }
  }

  Future<void> _loadUKMs() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load current periode
      _currentPeriode = await _getCurrentPeriode();
      final currentPeriodeId = _currentPeriode?['id_periode'];

      // Get UKMs from database
      final response = await _supabase
          .from('ukm')
          .select('id_ukm, nama_ukm, email, logo');

      // Load user's registered UKMs
      final registeredUKMIds = <String>{};
      final Map<String, int> attendanceMap = {};
      final Map<String, int> totalMeetingsMap = {};

      // 1. Get Total Meetings for each UKM in current period
      if (currentPeriodeId != null) {
        try {
          // Fetch distinct meeting counts per UKM for current period
          final meetingsResponse = await _supabase
              .from('pertemuan')
              .select('id_ukm, id_pertemuan')
              .eq('id_periode', currentPeriodeId);
          
          final meetingsList = meetingsResponse as List;
          for (var meeting in meetingsList) {
            final ukmId = meeting['id_ukm'].toString();
            totalMeetingsMap[ukmId] = (totalMeetingsMap[ukmId] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint('Error loading total meetings: $e');
        }
      }

      // 2. Get User Registration & Attendance
      try {
        final userId = _authService.currentUserId;
        print('DEBUG _loadUKMs: userId from authService = $userId');
        
        if (userId != null && userId.isNotEmpty) {
          // Get all registered UKMs - Independent of period
          final userUKMResponse = await _supabase
              .from('user_halaman_ukm')
              .select('id_ukm')
              .eq('id_user', userId)
              .or('status.eq.aktif,status.eq.active')
              .order('created_at', ascending: false);

          for (var item in userUKMResponse) {
            registeredUKMIds.add(item['id_ukm']?.toString() ?? '');
          }
          
          // Get user's attendance - Dependent on period
          if (currentPeriodeId != null) {
            final attendanceResponse = await _supabase
                .from('absen_pertemuan')
                .select('id_pertemuan, pertemuan!inner(id_ukm, id_periode)')
                .eq('id_user', userId)
                .eq('status', 'Hadir')
                .eq('pertemuan.id_periode', currentPeriodeId);
                
            final attendanceList = attendanceResponse as List;
            for (var record in attendanceList) {
              final ukmId = record['pertemuan']['id_ukm'].toString();
              attendanceMap[ukmId] = (attendanceMap[ukmId] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading user UKMs/attendance: $e');
      }

      final List<dynamic> data = response as List;

      if (!mounted) return;

      setState(() {
        _allUKMs = data.map((ukm) {
          final ukmId = ukm['id_ukm']?.toString() ?? '';
          final isReg = registeredUKMIds.contains(ukmId);
          
          return {
            'id': ukm['id_ukm']?.toString() ?? '',
            'name': ukm['nama_ukm'] ?? 'UKM',
            'logo': ukm['logo'],
            'email': ukm['email'] ?? '',
            'description': 'Tidak ada deskripsi',
            'jadwal': '-',
            'time': '-',
            'location': '-',
            'kontak': [
              {'icon': Icons.email, 'text': ukm['email'] ?? '-'},
            ],
            'isRegistered': isReg,
            'status': isReg ? 'Sudah Terdaftar' : 'Belum Terdaftar',
            'attendance': attendanceMap[ukmId] ?? 0,
            'totalMeetings': totalMeetingsMap[ukmId] ?? 0,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading UKMs: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUKMs {
    // Start with filtered by category
    List<Map<String, dynamic>> filtered;
    switch (_selectedFilter) {
      case 'Bergabung':
        filtered = _allUKMs
            .where((ukm) => ukm['isRegistered'] == true)
            .toList();
        break;
      case 'Belum':
        filtered = _allUKMs
            .where((ukm) => ukm['isRegistered'] == false)
            .toList();
        break;
      case 'Aktif':
        filtered = _allUKMs
            .where(
              (ukm) =>
                  ukm['isRegistered'] == true &&
                  (ukm['attendance'] as int? ?? 0) > 0,
            )
            .toList();
        break;
      case 'Populer':
        // Sort by attendance
        filtered = _allUKMs.toList()
          ..sort(
            (a, b) => (b['attendance'] ?? 0).compareTo(a['attendance'] ?? 0),
          );
        break;
      case 'Baru':
        // New UKMs
        filtered = _allUKMs.toList();
        break;
      case 'Semua':
        // All UKMs
        filtered = _allUKMs.toList();
        break;
      default:
        filtered = _allUKMs;
    }

    // Filter by search query
    if (_searchQuery.isEmpty) {
      return filtered;
    }

    final query = _searchQuery.toLowerCase();
    return filtered
        .where(
          (ukm) =>
              (ukm['name'] as String).toLowerCase().contains(query) ||
              (ukm['description'] as String).toLowerCase().contains(query) ||
              (ukm['email'] as String).toLowerCase().contains(query),
        )
        .toList();
  }

  void _viewUKMDetail(Map<String, dynamic> ukm) {
    setState(() {
      _selectedUKM = ukm;
      _ukmPertemuanList = [];
      _ukmEventsList = [];
    });
    // Load pertemuan and events for this UKM
    _loadUKMPertemuan(ukm['id'].toString());
    _loadUKMEvents(ukm['id'].toString());
  }

  void _backToList() {
    setState(() {
      _selectedUKM = null;
      _ukmPertemuanList = [];
      _ukmEventsList = [];
    });
    // Reload UKM data to reflect any changes
    _loadUKMs();
  }

  /// Load pertemuan (meetings) for the selected UKM
  Future<void> _loadUKMPertemuan(String ukmId) async {
    print('========================================');
    print('DEBUG _loadUKMPertemuan: START');
    print('UKM ID: $ukmId');

    setState(() => _isLoadingPertemuan = true);

    try {
      final userId = _authService.currentUserId;
      print('User ID: $userId');

      // Use PertemuanService to get pertemuan for this UKM specifically
      // Note: Idealnya service punya method getPertemuanByUkm(ukmId)
      // Tapi untuk saat ini kita filter manual dari getAllPertemuan atau filter query langsung
      
      final response = await _supabase
          .from('pertemuan')
          .select()
          .or('id_ukm.eq.$ukmId,id_ukm.is.null')
          .order('tanggal', ascending: false);

      final List<dynamic> pertemuanData = response as List<dynamic>;
      print('Found ${pertemuanData.length} pertemuan records for this UKM');
      
      // Convert to List<Map>
      // Kita pakai model manual karena PertemuanService return object yang beda strukturnya
      // atau pakai data raw dari supabase langsung
      
      final List<Map<String, dynamic>> pertemuanForThisUKM = [];
      
      for(var p in pertemuanData) {
        pertemuanForThisUKM.add({
             'id_pertemuan': p['id_pertemuan'],
             'topik': p['topik'],
             'tanggal': p['tanggal'],
             'jam_mulai': p['jam_mulai'],
             'jam_akhir': p['jam_akhir'],
             'lokasi': p['lokasi'],
             'id_periode': p['id_periode'],
             'id_ukm': p['id_ukm'],
        });
      }

      if (userId != null && pertemuanForThisUKM.isNotEmpty) {
        // Get user's attendance records
        print('Fetching attendance data for user...');
        final attendanceData = await _supabase
            .from('absen_pertemuan')
            .select('id_pertemuan, status, jam')
            .eq('id_user', userId);

        print('Found ${attendanceData.length} attendance records');

        final attendanceMap = <String, Map<String, dynamic>>{};
        for (var item in attendanceData) {
          attendanceMap[item['id_pertemuan']] = {
            'status_hadir': item['status'],
            'waktu_absen': item['jam'],
          };
        }

        // Merge with attendance
        final mergedData = pertemuanForThisUKM.map((pertemuan) {
          final idPertemuan = pertemuan['id_pertemuan'];
          final attendance = attendanceMap[idPertemuan];
          
          return {
            ...pertemuan,
            'user_status_hadir': attendance?['status_hadir'],
            'user_waktu_absen': attendance?['waktu_absen'],
            'has_invalid_ukm_id': false,
          };
        }).toList();

        setState(() {
          _ukmPertemuanList = mergedData;
          _isLoadingPertemuan = false;
        });
      } else {
        setState(() {
          _ukmPertemuanList = pertemuanForThisUKM;
          _isLoadingPertemuan = false;
        });
      }
      
      print('✅ Successfully loaded ${_ukmPertemuanList.length} pertemuan');

    } catch (e, stackTrace) {
      print('❌ Error loading pertemuan: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _ukmPertemuanList = [];
        _isLoadingPertemuan = false;
      });
    }

    print('DEBUG _loadUKMPertemuan: END');
    print('========================================');
  }

  /// Load events for the selected UKM
  Future<void> _loadUKMEvents(String ukmId) async {
    setState(() => _isLoadingEvents = true);

    try {
      final eventData = await _supabase
          .from('events')
          .select('''
            id_events,
            nama_event,
            deskripsi,
            tanggal_mulai,
            tanggal_akhir,
            lokasi,
            status
          ''')
          .eq('id_ukm', ukmId)
          .eq('status', true)
          .order('tanggal_mulai', ascending: false)
          .limit(5);

      setState(() {
        _ukmEventsList = eventData;
        _isLoadingEvents = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoadingEvents = false);
    }
  }

  /// Get current active periode
  Future<Map<String, dynamic>?> _getCurrentPeriode() async {
    try {
      final response = await _supabase
          .from('periode_ukm')
          .select('''
            id_periode, nama_periode, semester, tahun,
            tanggal_awal, tanggal_akhir, status,
            is_registration_open, registration_start_date, registration_end_date
          ''')
          // Removing strict status check to ensure we find the latest period
          // The logic in _showRegisterDialog will determine if it's open based on dates
          .order('create_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting current periode: $e');
      return null;
    }
  }

  /// Check if user has cooldown for rejoining UKM
  Future<Map<String, dynamic>> _checkCooldownPeriod(String ukmId) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null || userId.isEmpty) {
        return {'has_cooldown': false};
      }

      // Get current periode first
      final currentPeriode = await _getCurrentPeriode();
      if (currentPeriode == null) {
        return {'has_cooldown': false};
      }

      // Check user_halaman_ukm for 'keluar' status in current period
      try {
        final lastUnjoin = await _supabase
            .from('user_halaman_ukm')
            .select('id_periode, status')
            .eq('id_ukm', ukmId)
            .eq('id_user', userId)
            .eq('status', 'keluar') // Status updated when unjoining
            .maybeSingle();

        if (lastUnjoin != null) {
          // Check if unjoin was in current periode
          if (lastUnjoin['id_periode'] == currentPeriode['id_periode']) {
            print('User is in cooldown period (left in this period)');
            return {
              'has_cooldown': true,
              'current_periode': currentPeriode['nama_periode'],
            };
          }
        }
      } catch (e) {
        print('Error checking cooldown record: $e');
      }

      return {'has_cooldown': false};
    } catch (e) {
      print('Error checking cooldown: $e');
      return {'has_cooldown': false};
    }
  }

  /// Unjoin from UKM
  Future<void> _unjoinUKM(Map<String, dynamic> ukm) async {
    final userId = _authService.currentUserId;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar dari UKM?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Anda yakin ingin keluar dari ${ukm['name']}? Anda harus menunggu 1 periode untuk bergabung kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Anda harus login terlebih dahulu'),
            backgroundColor: Colors.red[600],
          ),
        );
        return;
      }

      // Update status to 'keluar' instead of deleting
      await _supabase.from('user_halaman_ukm').update({
        'status': 'keluar',
        // We keep id_periode as the period they were in when they left
        // or effectively the period they are now "cooldown" for if logic checks it
      }).match({
        'id_ukm': ukm['id'],
        'id_user': userId,
      });

      // Update local state immediately
      setState(() {
        final index = _allUKMs.indexWhere((e) => e['id'] == ukm['id']);
        if (index != -1) {
          _allUKMs[index]['isRegistered'] = false;
          _allUKMs[index]['status'] = 'Belum Terdaftar';
          _allUKMs[index]['attendance'] = 0;

          // Update selected UKM to reflect changes immediately in detail view
          if (_selectedUKM != null && _selectedUKM!['id'] == ukm['id']) {
            _selectedUKM = Map<String, dynamic>.from(_allUKMs[index]);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil keluar dari ${ukm['name']}'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error unjoining UKM: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar dari UKM: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _showRegisterDialog(Map<String, dynamic> ukm) async {
    // Get current periode first
    final currentPeriode = await _getCurrentPeriode();

    // Check if there's an active periode
    if (currentPeriode == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Tidak Ada Periode Aktif',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saat ini tidak ada periode pendaftaran yang berlangsung.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Silakan tunggu pengumuman periode pendaftaran berikutnya.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    // Check cooldown period (for users who previously left)
    final cooldownCheck = await _checkCooldownPeriod(ukm['id']);
    if (cooldownCheck['has_cooldown'] == true) {
      final currentPeriodeName = cooldownCheck['current_periode'] ?? 'saat ini';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Tidak Dapat Bergabung',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda telah keluar dari ${ukm['name']} pada periode $currentPeriodeName.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anda harus menunggu sampai periode berikutnya untuk bergabung kembali.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    // Check if registration is open
    bool isRegistrationOpen = currentPeriode['is_registration_open'] ?? false;
    final regStartDate = currentPeriode['registration_start_date'];
    final regEndDate = currentPeriode['registration_end_date'];

    // Override isRegistrationOpen if we are strictly within the date range
    // This ensures logic follows the actual dates set by admin
    if (regStartDate != null && regEndDate != null) {
      try {
        final startDate = DateTime.parse(regStartDate);
        final endDate = DateTime.parse(regEndDate);
        final now = DateTime.now();
        
        if (now.isAfter(startDate) && now.isBefore(endDate)) {
          isRegistrationOpen = true; // Force open if within dates
        } else {
          isRegistrationOpen = false; // Force closed if outside dates
        }
      } catch (e) {
        print('Error checking registration dates: $e');
      }
    }

    if (!isRegistrationOpen) {

      String message = 'Periode pendaftaran belum dibuka atau sudah ditutup.';
      if (regStartDate != null && regEndDate != null) {
        try {
          final startDate = DateTime.parse(regStartDate);
          final endDate = DateTime.parse(regEndDate);
          final now = DateTime.now();

          if (now.isBefore(startDate)) {
            message =
                'Periode pendaftaran akan dibuka pada ${_formatDateIndo(startDate)}.';
          } else if (now.isAfter(endDate)) {
            message =
                'Periode pendaftaran telah ditutup pada ${_formatDateIndo(endDate)}.';
          }
        } catch (e) {
          print('Error parsing registration dates: $e');
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.event_busy, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Pendaftaran Ditutup',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Silakan tunggu hingga periode pendaftaran dibuka.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Anda yakin mendaftar UKM ini?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Tidak',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Use CustomAuthService instead of Supabase Auth
                            final userId = _authService.currentUserId;
                            final userEmail =
                                _authService.currentUser?['email'];

                            print('========== DEBUG REGISTER UKM ==========');
                            print('Current user ID: $userId');
                            print('User email: $userEmail');
                            print('Is logged in: ${_authService.isLoggedIn}');
                            print('UKM ID: ${ukm['id']}');
                            print('======================================');

                            if (userId == null || userId.isEmpty) {
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Anda harus login terlebih dahulu',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red[600],
                                ),
                              );
                              return;
                            }

                            // Check if user is already registered in ANY status
                            // We need to check for 'keluar' status too for cooldown or re-joining
                            final existingReg = await _supabase
                                .from('user_halaman_ukm')
                                .select('id_ukm, status, id_periode')
                                .eq('id_user', userId)
                                .eq('id_ukm', ukm['id'])
                                .maybeSingle();

                            if (existingReg != null) {
                              final status = existingReg['status'];
                              
                              if (status == 'aktif' || status == 'active') {
                                if (existingReg['id_periode'] == currentPeriode['id_periode']) {
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Anda sudah terdaftar di ${ukm['name']}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.orange[600],
                                    ),
                                  );
                                  await _loadUKMs();
                                  return;
                                }
                                // If active in old period, usually we just update period? 
                                // But normally periods roll over. We'll proceed to update/upsert.
                              } else if (status == 'keluar') {
                                // Check cooldown
                                if (existingReg['id_periode'] == currentPeriode['id_periode']) {
                                   if (!mounted) return;
                                   Navigator.pop(context);
                                   // Logic handled by _checkCooldownPeriod usually, but explicit check here too
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Anda baru saja keluar di periode ini. Tunggu periode berikutnya.',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red[600],
                                    ),
                                  );
                                  return;
                                }
                                // If status is keluar but DIFFERENT period, we allow re-join (Update)
                              }
                            }

                            print(
                              'Current periode: ${currentPeriode['id_periode']}',
                            );

                            // Upsert logic:
                            // If record exists (status=keluar or old period), we update it.
                            // If no record, we insert.
                            // Using upsert with match on id_user + id_ukm implies those are unique key
                            // But since we can't be sure of unique constraints, explicit update/insert is safer given we already queried existingReg
                            
                            if (existingReg != null) {
                               // Update existing record
                               await _supabase.from('user_halaman_ukm').update({
                                  'id_periode': currentPeriode['id_periode'],
                                  'status': 'aktif',
                                  // 'create_at': DateTime.now().toIso8601String(), // Optional: refresh timestamp
                               }).match({
                                  'id_ukm': ukm['id'],
                                  'id_user': userId,
                               });
                               print('DAFTAR: Updated existing record to aktif');
                            } else {
                               // Insert new record
                               await _supabase.from('user_halaman_ukm').insert({
                                  'id_ukm': ukm['id'],
                                  'id_user': userId,
                                  'id_periode': currentPeriode['id_periode'],
                                  'status': 'aktif',
                               });
                               print('DAFTAR: Inserted new record');
                            }

                            print(
                              'DEBUG: Berhasil insert user_halaman_ukm untuk ${ukm['name']}',
                            );

                            // Update local state immediately
                            setState(() {
                              final index = _allUKMs.indexWhere(
                                (element) => element['id'] == ukm['id'],
                              );
                              if (index != -1) {
                                _allUKMs[index]['isRegistered'] = true;
                                _allUKMs[index]['status'] = 'Sudah Terdaftar';
                                _allUKMs[index]['attendance'] = 0;

                                // Update selected UKM to reflect changes immediately
                                if (_selectedUKM != null &&
                                    _selectedUKM!['id'] == ukm['id']) {
                                  _selectedUKM = Map<String, dynamic>.from(
                                    _allUKMs[index],
                                  );
                                }
                              }
                            });

                            if (!mounted) return;
                            Navigator.pop(context);

                            // Reload data to ensure consistency
                            await _loadUKMs();

                            // After reload, update selected UKM again
                            if (_selectedUKM != null) {
                              final updatedIndex = _allUKMs.indexWhere(
                                (e) => e['id'] == _selectedUKM!['id'],
                              );
                              if (updatedIndex != -1) {
                                setState(() {
                                  _selectedUKM = _allUKMs[updatedIndex];
                                });
                              }
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Berhasil mendaftar ${ukm['name']}!',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.blue[600],
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          } catch (e) {
                            print('Error registering UKM: $e');
                            if (!mounted) return;

                            // Check if it's duplicate entry error
                            if (e.toString().contains('duplicate') ||
                                e.toString().contains('unique')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Anda sudah terdaftar di UKM ini',
                                  ),
                                  backgroundColor: Colors.orange[600],
                                ),
                              );
                              Navigator.pop(context);
                              await _loadUKMs();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal mendaftar UKM: ${e.toString()}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red[600],
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ya',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // ==================== BUILD METHOD ====================
  }

  String _formatDateIndo(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 70,
              left: 12,
              right: 12,
              bottom: 80,
            ),
            child: _selectedUKM == null
                ? _buildUKMListMobile()
                : _buildUKMDetailMobile(),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingTopBar(isMobile: true),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 70), // Space for floating top bar
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: Container(
                        color: Colors.white,
                        child: _buildSidebarVerticalModern(),
                      ),
                    ),
                    Expanded(
                      child: _selectedUKM == null
                          ? _buildUKMListTablet()
                          : _buildUKMDetailTablet(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
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
                selectedMenu: 'ukm',
                onMenuSelected: (menu) {
                  if (menu == 'dashboard') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardUser(),
                      ),
                    );
                  } else if (menu == 'event') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserEventPage(),
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
                onLogout: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 70), // Space for floating top bar
                    Expanded(
                      child: _selectedUKM == null
                          ? _buildUKMListDesktop()
                          : _buildUKMDetailDesktop(),
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

  // ==================== MODERN VERTICAL SIDEBAR (MOBILE/TABLET) ====================
  Widget _buildSidebarVerticalModern() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'UNIT ACTIVITY',
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildMenuItemCompactModern(
            Icons.dashboard_rounded,
            'Dashboard',
            'dashboard',
          ),
          _buildMenuItemCompactModern(Icons.event_rounded, 'Event', 'event'),
          _buildMenuItemCompactModern(Icons.groups_rounded, 'UKM', 'ukm'),
          _buildMenuItemCompactModern(
            Icons.history_rounded,
            'Histori',
            'history',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCompactModern(
    IconData icon,
    String title,
    String route,
  ) {
    final isSelected = _selectedMenu == title;

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.blue[700] : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.blue[700] : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () {
        setState(() => _selectedMenu = title);
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (route == 'dashboard') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardUser()),
            );
          } else if (route == 'event') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserEventPage()),
            );
          } else if (route == 'ukm') {
            // Already on UKM page
          } else if (route == 'history') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
          }
        });
      },
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

  // ==================== QR SCANNER ====================
  void _handleQRCodeScanned(String code) async {
    print('========== QR CODE SCANNED (UKM PAGE) ==========');
    print('Code: $code');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('Memproses absensi...', style: GoogleFonts.inter()),
          ],
        ),
      ),
    );

    // Process attendance
    final result = await _attendanceService.processQRCodeAttendance(code);

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // Show result
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: result['success']
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  result['success'] ? Icons.check_circle : Icons.error,
                  color: result['success'] ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result['success'] ? 'Berhasil!' : 'Gagal',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['message'] ?? 'Terjadi kesalahan',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
              if (result['success']) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Waktu: ${result['time'] ?? '-'}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (result['success']) {
                  // Reload data to update progress bar and attendance status
                  _loadUKMs();
                  if (_selectedUKM != null) {
                    _loadUKMPertemuan(_selectedUKM!['id']);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    result['success'] ? Colors.blue[600] : Colors.grey[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
                await _supabase.auth.signOut();
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
                  _selectedMenu == 'Dashboard',
                  () => _handleMenuSelected('Dashboard'),
                ),
                // Event
                _buildNavItem(
                  Icons.event_rounded,
                  'Event',
                  _selectedMenu == 'Event',
                  () => _handleMenuSelected('Event'),
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
                  _selectedMenu == 'UKM',
                  () => _handleMenuSelected('UKM'),
                ),
                // History
                _buildNavItem(
                  Icons.history_rounded,
                  'History',
                  _selectedMenu == 'History',
                  () => _handleMenuSelected('History'),
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
      case 'Dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardUser()),
        );
        break;
      case 'Event':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserEventPage()),
        );
        break;
      case 'UKM':
        // Already on UKM page
        break;
      case 'History':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
        break;
    }
  }

  // ==================== UKM LIST VIEW - MOBILE ====================
  Widget _buildUKMListMobile() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan UKM',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildFilterChipsMobile(),
          const SizedBox(height: 16),
          if (_filteredUKMs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'Tidak ada UKM yang tersedia',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredUKMs.length,
              itemBuilder: (context, index) {
                return _buildUKMCard(_filteredUKMs[index], isMobile: true);
              },
            ),
        ],
      ),
    );
  }

  // ==================== UKM LIST VIEW - TABLET ====================
  Widget _buildUKMListTablet() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan UKM',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildFilterChipsTablet(),
          const SizedBox(height: 16),
          if (_filteredUKMs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text(
                'Tidak ada UKM yang tersedia',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: _filteredUKMs.length,
              itemBuilder: (context, index) {
                return _buildUKMCard(_filteredUKMs[index], isMobile: false);
              },
            ),
        ],
      ),
    );
  }

  // ==================== UKM LIST VIEW - DESKTOP ====================
  Widget _buildUKMListDesktop() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan UKM',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildFilterChipsDesktop(),
          const SizedBox(height: 24),
          if (_filteredUKMs.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text(
                    'Tidak ada UKM yang tersedia',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total UKM: ${_allUKMs.length}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Filter: $_selectedFilter',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_allUKMs.isEmpty)
                        ElevatedButton(
                          onPressed: _loadUKMs,
                          child: const Text('Muat Ulang Data'),
                        ),
                      if (_allUKMs.isNotEmpty) ...[
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'Semua';
                            });
                          },
                          child: const Text('Reset Filter'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.9,
              ),
              itemCount: _filteredUKMs.length,
              itemBuilder: (context, index) {
                return _buildUKMCard(_filteredUKMs[index], isMobile: false);
              },
            ),
        ],
      ),
    );
  }

  // ==================== UKM CARD ====================
  Widget _buildUKMCard(Map<String, dynamic> ukm, {required bool isMobile}) {
    final isRegistered = ukm['isRegistered'] as bool;
    final attendance = ukm['attendance'] as int? ?? 0;
    final totalMeetings = ukm['totalMeetings'] as int? ?? 0;
    
    // Calculate progress (avoid division by zero)
    final double progress = totalMeetings > 0 
        ? attendance / totalMeetings 
        : 0.0;

    return InkWell(
      onTap: () => _viewUKMDetail(ukm),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              isRegistered ? Colors.blue[50]! : Colors.grey[50]!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: isRegistered
                  ? Colors.blue.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: isRegistered
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isRegistered ? Colors.blue[100]! : Colors.grey[200]!,
                      isRegistered ? Colors.blue[50]! : Colors.grey[100]!,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: -10,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildUKMLogo(
                              ukm['logo'],
                              size: isMobile ? 50 : 70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              ukm['name'],
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 13 : 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRegistered) ...[
                    // Progress bar untuk pertemuan
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: isMobile ? 12 : 14,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$attendance/$totalMeetings Pertemuan',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress > 1.0 ? 1.0 : progress,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        progress >= 1.0
                                            ? Colors.green[400]!
                                            : Colors.blue[400]!,
                                        progress >= 1.0
                                            ? Colors.green[600]!
                                            : Colors.blue[600]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Belum terdaftar
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: isMobile ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '0/$totalMeetings Pertemuan',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: isMobile ? 6 : 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRegistered
                            ? [Colors.blue[500]!, Colors.blue[600]!]
                            : [Colors.grey[400]!, Colors.grey[500]!],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (isRegistered ? Colors.blue : Colors.grey)
                              .withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isRegistered ? 'Terdaftar' : 'Belum Terdaftar',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isMobile ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          isRegistered
                              ? Icons.check_circle
                              : Icons.arrow_forward_rounded,
                          size: isMobile ? 14 : 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UKM LOGO HELPER ====================
  Widget _buildUKMLogo(String? logoPath, {double size = 50}) {
    if (logoPath == null || logoPath.isEmpty) {
      return _buildUKMLogoPlaceholder(size: size);
    }

    // Check if it's a network URL
    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.network(
          logoPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildUKMLogoPlaceholder(size: size);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.blue[600],
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Assume it's an emoji or fallback
      return Text(logoPath, style: TextStyle(fontSize: size * 0.7));
    }
  }

  Widget _buildUKMLogoPlaceholder({double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Icon(Icons.groups, size: size * 0.5, color: Colors.grey[500]),
      ),
    );
  }

  // ==================== FILTER CHIPS ====================
  Widget _buildFilterChipsMobile() {
    final filters = ['Semua', 'Bergabung', 'Belum', 'Aktif', 'Populer'];
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[200],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChipsTablet() {
    final filters = ['Semua', 'Bergabung', 'Belum', 'Aktif', 'Populer'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[200],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChipsDesktop() {
    final filters = ['Semua', 'Bergabung', 'Belum', 'Aktif', 'Populer'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[200],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari UKM...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  color: Colors.grey[600],
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 0,
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // ==================== UKM DETAIL VIEW - MOBILE ====================
  Widget _buildUKMDetailMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Kembali', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUKMLogo(_selectedUKM!['logo'], size: 80),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _selectedUKM!['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailCard(isMobile: true),
        ],
      ),
    );
  }

  // ==================== UKM DETAIL VIEW - TABLET ====================
  Widget _buildUKMDetailTablet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back),
            label: Text(
              _selectedUKM!['name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUKMLogo(_selectedUKM!['logo'], size: 80),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _selectedUKM!['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildDetailCard(isMobile: false)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== UKM DETAIL VIEW - DESKTOP ====================
  Widget _buildUKMDetailDesktop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back),
            label: Text(_selectedUKM!['name']),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildUKMLogo(_selectedUKM!['logo'], size: 120),
                      const SizedBox(height: 16),
                      Text(
                        _selectedUKM!['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(child: _buildDetailCard(isMobile: false)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DETAIL CARD ====================
  Widget _buildDetailCard({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (!_selectedUKM!['isRegistered'])
                SizedBox(
                  width: isMobile ? 80 : 120,
                  child: ElevatedButton(
                    onPressed: () => _showRegisterDialog(_selectedUKM!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 6 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Daftar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 11 : 14,
                      ),
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _unjoinUKM(_selectedUKM!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red[700],
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 12,
                      vertical: isMobile ? 6 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  child: Text(
                    'Keluar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 11 : 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailSection(
            title: 'Jadwal',
            items: [
              {'icon': Icons.calendar_today, 'text': _selectedUKM!['jadwal']},
              {'icon': Icons.access_time, 'text': _selectedUKM!['time']},
            ],
            isMobile: isMobile,
          ),
          const SizedBox(height: 12),
          _buildDetailSection(
            title: 'Lokasi',
            items: [
              {'icon': Icons.location_on, 'text': _selectedUKM!['location']},
            ],
            isMobile: isMobile,
          ),
          const SizedBox(height: 12),
          _buildDetailSection(
            title: 'Kontak',
            items: _selectedUKM!['kontak'] as List,
            isMobile: isMobile,
          ),
          // Periode Section
          if (_currentPeriode != null) ...[
            const SizedBox(height: 12),
            _buildPeriodeSection(isMobile: isMobile),
          ],
          const SizedBox(height: 24),
          // Kegiatan Pertemuan Section
          _buildPertemuanSection(isMobile: isMobile),
          const SizedBox(height: 24),
          // Event UKM Section
          _buildEventsSection(isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildPertemuanSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Kegiatan Pertemuan',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingPertemuan)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_ukmPertemuanList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada pertemuan terjadwal',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_ukmPertemuanList.length, (index) {
            final pertemuan = _ukmPertemuanList[index];
            return Container(
              margin: EdgeInsets.only(
                bottom: index < _ukmPertemuanList.length - 1 ? 12 : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image/Icon section (left side)
                  Container(
                    width: isMobile ? 100 : 140,
                    height: isMobile ? 100 : 120,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.groups,
                        size: isMobile ? 40 : 50,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  // Content section (right side)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pertemuan['topik'] ?? 'Pertemuan',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Warning badge for invalid UKM ID
                              if (pertemuan['has_invalid_ukm_id'] == true)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 12,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Data',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (pertemuan['user_status_hadir'] != null)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        pertemuan['user_status_hadir'] ==
                                            'hadir'
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    pertemuan['user_status_hadir'] == 'hadir'
                                        ? 'Hadir'
                                        : 'Tidak Hadir',
                                    style: GoogleFonts.inter(
                                      fontSize: isMobile ? 10 : 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          pertemuan['user_status_hadir'] ==
                                              'hadir'
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: isMobile ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  pertemuan['tanggal'] ?? '-',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: isMobile ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${pertemuan['jam_mulai'] ?? '-'} - ${pertemuan['jam_akhir'] ?? '-'}',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (pertemuan['lokasi'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: isMobile ? 12 : 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    pertemuan['lokasi'],
                                    style: GoogleFonts.inter(
                                      fontSize: isMobile ? 11 : 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEventsSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Event UKM',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingEvents)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_ukmEventsList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy, color: Colors.grey[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada event',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_ukmEventsList.length, (index) {
            final event = _ukmEventsList[index];
            return Container(
              margin: EdgeInsets.only(
                bottom: index < _ukmEventsList.length - 1 ? 12 : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon section (left side)
                  Container(
                    width: isMobile ? 100 : 140,
                    height: isMobile ? 100 : 120,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.event,
                        size: isMobile ? 40 : 50,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                  // Content section (right side)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event['nama_event'] ?? 'Event',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: event['status'] == true
                                      ? Colors.green[50]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  event['status'] == true ? 'Aktif' : 'Draft',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: event['status'] == true
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: isMobile ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${event['tanggal_mulai'] ?? '-'} - ${event['tanggal_akhir'] ?? '-'}',
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (event['lokasi'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: isMobile ? 12 : 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event['lokasi'],
                                    style: GoogleFonts.inter(
                                      fontSize: isMobile ? 11 : 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List items,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: isMobile ? 14 : 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item['text'] as String,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==================== PERIODE SECTION ====================
  Widget _buildPeriodeSection({required bool isMobile}) {
    if (_currentPeriode == null) return const SizedBox.shrink();

    final namaPeriode = _currentPeriode!['nama_periode'] ?? '-';
    final tanggalAwal = _currentPeriode!['tanggal_awal'];
    final tanggalAkhir = _currentPeriode!['tanggal_akhir'];
    final isRegistrationOpen =
        _currentPeriode!['is_registration_open'] ?? false;

    String formatTanggal(String? dateStr) {
      if (dateStr == null) return '-';
      try {
        final date = DateTime.parse(dateStr);
        return _formatDateIndo(date);
      } catch (e) {
        return dateStr;
      }
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: isMobile ? 18 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periode Aktif',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    Text(
                      namaPeriode,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 13 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (isRegistrationOpen)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: isMobile ? 12 : 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Buka',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: isMobile ? 12 : 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tutup',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: isMobile ? 16 : 18,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Periode Dimulai',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 10 : 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatTanggal(tanggalAwal),
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: isMobile ? 16 : 18,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Periode Berakhir',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 10 : 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatTanggal(tanggalAkhir),
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
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
    );
  }
}

// Lifecycle observer untuk reload data ketika app resume
class _LifecycleObserver extends WidgetsBindingObserver {
  final Function() onResume;

  _LifecycleObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
