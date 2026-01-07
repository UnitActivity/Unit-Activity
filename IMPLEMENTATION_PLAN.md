# Implementation Plan for HIGH Priority Features

## Current Status Analysis (January 7, 2026)

### ✅ ALREADY WORKING:
1. **Dashboard Informasi Terkini**:
   - Loading from both ADMIN and UKM (`informasi` table)
   - Auto-slide every 6 seconds (implemented)
   - Shows images from `informasi-images` storage bucket
   
2. **Notifikasi**:
   - "Tandai Semua" button already calls `markAllAsRead()` 
   - Individual notification click already calls `markAsRead(notification.id)`
   - Database updates to `notification_preference` table

3. **Profile**:
   - Recently redesigned with modern UI
   - Uses correct fields (nim, picture, not npm/avatar)
   - Shows statistics (events, meetings, UKMs)

### 🔧 NEEDS FIXES:

## 1. UKM > User Page (HIGH Priority)

### Issues to Fix:
a) **Track Meeting Activities**: Display pertemuan history for each UKM
b) **Prevent Re-registration**: Check existing registration in current period
c) **Show Activities in Detail**: Display pertemuan and events in UKM detail page

### Database Schema Required:
```sql
-- user_halaman_ukm table (existing)
- id_user_ukm (PK)
- id_user (FK to users)
- id_ukm (FK to ukm)
- id_periode (FK to periode_ukm)
- status ('aktif', 'active', 'nonaktif', etc.)
- create_at

-- pertemuan table (existing)
- id_pertemuan (PK)
- id_ukm (FK to ukm)
- id_periode (FK to periode_ukm)
- judul
- deskripsi
- tanggal
- waktu_mulai
- waktu_selesai
- lokasi
- status

-- absen_pertemuan table (existing)
- id_absen (PK)
- id_pertemuan (FK to pertemuan)
- id_user (FK to users)
- status_hadir
- waktu_absen
- create_at

-- events table (existing)
- id_event (PK)
- id_ukm (FK to ukm, nullable for admin events)
- nama_event
- deskripsi
- tanggal_mulai
- tanggal_selesai
- lokasi
- status
```

### Implementation Steps:

#### Step 1: Fix UKM Registration Prevention
```dart
// Check if user is already registered in current period
Future<bool> _checkExistingRegistration(String ukmId, String userId) async {
  // Get current active period
  final currentPeriod = await _supabase
      .from('periode_ukm')
      .select('id_periode')
      .eq('status', 'aktif')
      .maybeSingle();
  
  if (currentPeriod == null) return false;
  
  // Check existing registration
  final existing = await _supabase
      .from('user_halaman_ukm')
      .select('id_user_ukm')
      .eq('id_user', userId)
      .eq('id_ukm', ukmId)
      .eq('id_periode', currentPeriod['id_periode'])
      .or('status.eq.aktif,status.eq.active')
      .maybeSingle();
  
  return existing != null;
}
```

#### Step 2: Add Meeting Activity Tracking Display
```dart
// Load pertemuan history for UKM
Future<List<Map<String, dynamic>>> _loadPertemuanHistory(String ukmId) async {
  final userId = _supabase.auth.currentUser?.id;
  
  final data = await _supabase
      .from('absen_pertemuan')
      .select('''
        id_absen,
        status_hadir,
        waktu_absen,
        pertemuan(
          id_pertemuan,
          judul,
          tanggal,
          waktu_mulai,
          waktu_selesai,
          lokasi
        )
      ''')
      .eq('id_user', userId)
      .eq('pertemuan.id_ukm', ukmId)
      .order('waktu_absen', ascending: false);
  
  return data;
}
```

#### Step 3: Show Activities in UKM Detail
Add sections in UKM detail page:
- **Upcoming Pertemuan**: List of scheduled meetings
- **Past Pertemuan**: History with attendance status
- **Active Events**: Ongoing events for the UKM

## 2. Dashboard Informasi (Already Working - Minor Enhancement)

### Current Status: ✅ WORKING
- Already loads from both ADMIN (`id_ukm = null`) and UKM
- Auto-slides every 6 seconds
- Shows images from database

### Minor Enhancement Needed:
Add manual left/right navigation buttons (if not already visible)

## 3. Notifikasi (Already Working - Verify UI Update)

### Current Status: ✅ WORKING
- `markAllAsRead()` updates database
- Individual `markAsRead(id)` works
- UI shows "BARU" badge for unread notifications

### Potential Issue:
UI might not immediately reflect the status change. Ensure `notifyListeners()` is called and UI rebuilds.

## 4. Profile Page (Recently Fixed - Add Dropdown)

### Current Status: ✅ MOSTLY COMPLETE
- Modern design with gradient header
- Statistics cards
- Correct database fields

### Enhancement Needed:
Add dropdown menu in header (like UKM/ADMIN) with:
- Profile option (current view)
- Logout option

### Implementation:
```dart
// In floating top bar, add PopupMenuButton
PopupMenuButton<String>(
  icon: CircleAvatar(
    backgroundImage: _pictureUrl != null 
        ? NetworkImage(_pictureUrl!) 
        : null,
    child: _pictureUrl == null 
        ? Icon(Icons.person) 
        : null,
  ),
  onSelected: (value) {
    if (value == 'profile') {
      // Already on profile
    } else if (value == 'logout') {
      _handleLogout();
    }
  },
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'profile',
      child: Row(
        children: [
          Icon(Icons.person),
          SizedBox(width: 12),
          Text('Profile'),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'logout',
      child: Row(
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 12),
          Text('Logout', style: TextStyle(color: Colors.red)),
        ],
      ),
    ),
  ],
)
```

## Database Recommendations

### Option 1: Use Existing Schema (RECOMMENDED)
All required tables already exist. No new tables needed.

### Option 2: Add Helper View (Optional)
Create a view for easier querying of UKM member pertemuan:
```sql
CREATE OR REPLACE VIEW user_ukm_activity AS
SELECT 
    u.id_user,
    u.username,
    uhu.id_ukm,
    uk.nama_ukm,
    p.id_pertemuan,
    p.judul as pertemuan_judul,
    p.tanggal as pertemuan_tanggal,
    ap.status_hadir,
    ap.waktu_absen
FROM users u
JOIN user_halaman_ukm uhu ON u.id_user = uhu.id_user
JOIN ukm uk ON uhu.id_ukm = uk.id_ukm
LEFT JOIN pertemuan p ON p.id_ukm = uk.id_ukm
LEFT JOIN absen_pertemuan ap ON ap.id_pertemuan = p.id_pertemuan AND ap.id_user = u.id_user
WHERE uhu.status IN ('aktif', 'active');
```

## Priority Order

1. **VHIGH**: Do not break existing features ✅
2. **HIGH**: UKM page - Prevent re-registration
3. **HIGH**: UKM page - Show pertemuan/event history
4. **HIGH**: Profile - Add dropdown menu
5. **MEDIUM**: UI polish and testing

## Testing Checklist

- [ ] UKM registration prevents duplicate in same period
- [ ] UKM detail shows pertemuan history
- [ ] UKM detail shows active events
- [ ] Dashboard informasi shows both ADMIN and UKM info
- [ ] Dashboard informasi auto-slides every 6 seconds
- [ ] Notification "Tandai Semua" marks all as read
- [ ] Individual notification click removes "BARU" badge
- [ ] Profile dropdown shows Profile and Logout
- [ ] All existing features still work
