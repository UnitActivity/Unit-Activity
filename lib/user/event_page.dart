import 'package:flutter/material.dart';

// ==================== USER EVENT PAGE ====================
class UserEventPage extends StatefulWidget {
  const UserEventPage({Key? key}) : super(key: key);

  @override
  State<UserEventPage> createState() => _UserEventPageState();
}

class _UserEventPageState extends State<UserEventPage> {
  int _selectedIndex = 1; // Event selected by default
  Map<String, dynamic>? _selectedEvent;

  final List<Map<String, dynamic>> _allEvents = [
    {
      'id': 1,
      'title': 'Sparing E-Sport',
      'image': 'assets/images/esport.png',
      'date': 'Kamis, 13 November 2025',
      'time': '16.00 - 18.00 WIB',
      'location': 'Ruang 6A - Universitas Katolik Darma Cendika',
      'description':
          'Sparing dengan UKM E-Sport Universitas Katolik Widya Mandala',
      'isRegistered': false,
    },
    {
      'id': 2,
      'title': 'Sparing Badminton',
      'image': 'assets/images/badminton.png',
      'date': 'Jumat, 14 November 2025',
      'time': '14.00 - 16.00 WIB',
      'location': 'GOR Universitas Katolik Darma Cendika',
      'description': 'Sparing Badminton antar UKM',
      'isRegistered': false,
    },
    {
      'id': 3,
      'title': 'KMJ Live In',
      'image': 'assets/images/kmj.png',
      'date': 'Sabtu, 15 November 2025',
      'time': '19.00 - 22.00 WIB',
      'location': 'Aula Utama UKDC',
      'description': 'Konser musik jazz live performance',
      'isRegistered': false,
    },
  ];

  List<Map<String, dynamic>> get _followedEvents {
    return _allEvents.where((event) => event['isRegistered'] == true).toList();
  }

  void _viewEventDetail(Map<String, dynamic> event) {
    setState(() {
      _selectedEvent = event;
    });
  }

  void _backToList() {
    setState(() {
      _selectedEvent = null;
    });
  }

  void _toggleRegistration() {
    setState(() {
      _selectedEvent!['isRegistered'] = !_selectedEvent!['isRegistered'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedEvent!['isRegistered']
              ? 'Berhasil mendaftar event!'
              : 'Batal mendaftar event',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),

                // Content Area - Switch between list and detail
                Expanded(
                  child: _selectedEvent == null
                      ? _buildEventListView()
                      : _buildEventDetailView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Unit Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const Divider(height: 1),

          // Menu Items
          _buildMenuItem(0, Icons.dashboard_outlined, 'Dashboard'),
          _buildMenuItem(1, Icons.event_outlined, 'Event'),
          _buildMenuItem(2, Icons.groups_outlined, 'UKM'),
          _buildMenuItem(3, Icons.history_outlined, 'Histori'),

          const Spacer(),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue[700] : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue[700] : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Handle navigation based on index
      },
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            child: Row(
              children: [
                const Text(
                  'Admin',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, size: 20, color: Colors.blue),
                ),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== EVENT LIST VIEW (GAMBAR 1) ====================
  Widget _buildEventListView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Lihat Semua"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seluruh Event',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () {}, child: const Text('Lihat Semua >')),
            ],
          ),
          const SizedBox(height: 20),

          // Event Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
            ),
            itemCount: _allEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(_allEvents[index]);
            },
          ),

          const SizedBox(height: 40),

          // Event yang diikuti
          const Text(
            'Event yang diikuti',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          _followedEvents.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada event yang diikuti',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _followedEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(_followedEvents[index]);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return InkWell(
      onTap: () => _viewEventDetail(event),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        event['title'],
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
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lihat Detail',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EVENT DETAIL VIEW (GAMBAR 2) ====================
  Widget _buildEventDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          TextButton.icon(
            onPressed: _backToList,
            icon: const Icon(Icons.arrow_back),
            label: Text(_selectedEvent!['title']),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _selectedEvent!['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),

              // Event Details
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: _toggleRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedEvent!['isRegistered']
                                    ? Colors.grey[400]
                                    : Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _selectedEvent!['isRegistered']
                                    ? 'Terdaftar'
                                    : 'Daftar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(
                        _selectedEvent!['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 30),

                      // Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedEvent!['date'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.access_time,
                              size: 20,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedEvent!['time'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedEvent!['location'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== LOGOUT DIALOG ====================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
