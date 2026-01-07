# Push Notification Setup Guide

## Prerequisites

1. **Firebase Project**: Buat project di [Firebase Console](https://console.firebase.google.com/)
2. **FCM Credentials**: Download file konfigurasi Firebase
3. **Supabase Project**: Database sudah setup dan running

## Setup Firebase

### 1. Android Setup

1. Download `google-services.json` dari Firebase Console
2. Copy file ke `android/app/google-services.json`
3. Pastikan `build.gradle.kts` sudah include:

```kotlin
// android/build.gradle.kts
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}

// android/app/build.gradle.kts
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging")
}
```

### 2. iOS Setup

1. Download `GoogleService-Info.plist` dari Firebase Console
2. Copy file ke `ios/Runner/GoogleService-Info.plist`
3. Update `ios/Runner/AppDelegate.swift`:

```swift
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ application: UIApplication, 
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

### 3. Flutter Dependencies

Pastikan di `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.11.0
  firebase_messaging: ^16.0.3
  flutter_local_notifications: ^18.1.0
  shared_preferences: ^2.3.5
```

## Database Migration

### Run Migration

1. Buka Supabase Dashboard → SQL Editor
2. Run migration `create_device_tokens_table.sql`
3. Run migration `create_notifikasi_anonymous_table.sql`
4. Verify tables created:

```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('device_tokens', 'notifikasi_anonymous');
```

## Testing Push Notifications

### Test 1: FCM Token Registration

**Expected:** Token tersimpan saat app pertama kali dibuka

```dart
// Check console logs
// Output: "FCM Token: eyJh..."
// Output: "FCM token saved to local storage"
// Output: "FCM token registered with backend"
```

**Verify in Database:**

```sql
SELECT * FROM device_tokens ORDER BY created_at DESC LIMIT 5;
```

### Test 2: Foreground Notification (App Terbuka)

**Scenario:** User membuka app, admin mengirim notifikasi

**Send via Firebase Console:**
1. Firebase Console → Cloud Messaging → Send test message
2. Paste FCM token dari console logs
3. Klik Send

**Expected:**
- Notification muncul sebagai local notification
- Tersimpan di tabel `notifikasi`
- Console logs: "✅ Foreground notification saved"

**Verify:**

```sql
SELECT * FROM notifikasi WHERE id_user = 'USER_ID' ORDER BY created_at DESC;
```

### Test 3: Background Notification (App di Background)

**Scenario:** User minimize app (app masih running di background)

**Steps:**
1. Buka app
2. Minimize (home button / recent apps)
3. Send notification via Firebase Console
4. Buka app lagi

**Expected:**
- Notification tersimpan di database
- Console logs: "========== BACKGROUND MESSAGE (BACKGROUND) =========="
- Console logs: "✅ Background notification saved"

### Test 4: Terminated Notification (App Tertutup)

**Scenario:** App benar-benar tertutup (swipe close di recent apps)

**Steps:**
1. Buka app, copy FCM token dari logs
2. Force close app (swipe close)
3. Send notification via Firebase Console
4. Buka app lagi

**Expected:**
- Notification tersimpan di `notifikasi_anonymous` (jika logout)
- Notification tersimpan di `notifikasi` (jika login)
- Background handler berjalan saat notif diterima
- Console logs: "========== BACKGROUND MESSAGE (TERMINATED) =========="

**Verify:**

```sql
-- If logged out
SELECT * FROM notifikasi_anonymous ORDER BY created_at DESC LIMIT 5;

-- If logged in
SELECT * FROM notifikasi WHERE id_user = 'USER_ID' ORDER BY created_at DESC;
```

### Test 5: Anonymous to User Migration

**Scenario:** User logout, terima notifikasi, login lagi

**Steps:**
1. Login ke app
2. Copy FCM token dari console logs
3. Logout
4. Force close app
5. Send notification via Firebase Console
6. Buka app, login dengan user yang sama

**Expected:**
- Notifikasi tersimpan di `notifikasi_anonymous` saat logout
- Saat login, otomatis dipindahkan ke `notifikasi`
- Console logs: "Migrated X anonymous notifications to user"

**Verify Before Login:**

```sql
SELECT * FROM notifikasi_anonymous WHERE device_token = 'FCM_TOKEN';
```

**Verify After Login:**

```sql
-- Anonymous notifications should be deleted
SELECT * FROM notifikasi_anonymous WHERE device_token = 'FCM_TOKEN';

-- Should appear in user notifications
SELECT * FROM notifikasi WHERE id_user = 'USER_ID' ORDER BY created_at DESC;
```

### Test 6: Topic Subscription

**Scenario:** Broadcast ke semua user atau specific UKM

**Send to All Users:**

Firebase Console → Target: Topic → Topic name: `all_users`

**Send to Specific UKM:**

Topic name: `ukm_UUID_OF_UKM`

**Expected:**
- Semua user tersubscribe `all_users` menerima notifikasi
- User yang join UKM tersubscribe `ukm_UUID` menerima notifikasi

## Troubleshooting

### Issue: FCM Token tidak ter-generate

**Check:**
1. Firebase project sudah setup dengan benar?
2. `google-services.json` ada di `android/app/`?
3. Dependencies sudah ter-install dengan benar?

**Fix:**
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd .. && flutter run
```

### Issue: Notification tidak muncul di foreground

**Check:**
1. Notification permission sudah granted?
2. FlutterLocalNotifications sudah initialized?

**Fix:**
- Check Settings → Apps → Unit Activity → Notifications → Enabled

### Issue: Background notification tidak tersimpan

**Check:**
1. Background handler registered sebelum runApp?
2. Supabase URL dan anon key benar?

**Fix:**

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase FIRST
  await Supabase.initialize(...);
  
  // THEN register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(MyApp());
}
```

### Issue: Token tidak tersimpan di SharedPreferences

**Check:**

```dart
// Test manually
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('fcm_token');
print('Saved token: $token');
```

**Fix:**
- Pastikan `_saveTokenToLocalStorage()` dipanggil setelah `_getFCMToken()`

### Issue: Migration tidak berjalan saat login

**Check:**

```dart
// custom_auth_service.dart
Future<bool> login(...) async {
  // After successful login
  await PushNotificationService().updateUserAssociation(userId);
  await _migrateAnonymousNotifications(); // ✅ Should be here
}
```

## Manual Testing via HTTP

### Send via FCM HTTP API

Dapatkan Server Key dari Firebase Console → Project Settings → Cloud Messaging

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_HERE",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test from curl"
    },
    "data": {
      "type": "info",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    },
    "priority": "high"
  }'
```

### Send via Python Script

```python
import requests
import json

SERVER_KEY = "YOUR_SERVER_KEY"
FCM_TOKEN = "USER_FCM_TOKEN"

url = "https://fcm.googleapis.com/fcm/send"
headers = {
    "Authorization": f"key={SERVER_KEY}",
    "Content-Type": "application/json"
}
payload = {
    "to": FCM_TOKEN,
    "notification": {
        "title": "Test dari Python",
        "body": "Notifikasi ini dikirim via Python script"
    },
    "data": {
        "type": "announcement",
        "page": "home"
    },
    "priority": "high"
}

response = requests.post(url, headers=headers, data=json.dumps(payload))
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")
```

## Monitoring & Analytics

### Check Notification Stats

```sql
-- Total notifications sent (last 7 days)
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total,
    COUNT(CASE WHEN is_read THEN 1 END) as read,
    COUNT(CASE WHEN NOT is_read THEN 1 END) as unread
FROM notifikasi
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Notification by type
SELECT 
    tipe,
    COUNT(*) as total
FROM notifikasi
GROUP BY tipe
ORDER BY total DESC;

-- Average read time
SELECT 
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) / 60 as avg_minutes
FROM notifikasi
WHERE is_read = true;
```

### Check Device Stats

```sql
-- Active devices (received notification in last 7 days)
SELECT 
    dt.platform,
    COUNT(DISTINCT dt.token) as active_devices
FROM device_tokens dt
JOIN notifikasi n ON n.id_user = dt.id_user
WHERE n.created_at > NOW() - INTERVAL '7 days'
GROUP BY dt.platform;

-- Device distribution
SELECT 
    platform,
    COUNT(*) as total,
    COUNT(id_user) as with_user,
    COUNT(*) - COUNT(id_user) as anonymous
FROM device_tokens
GROUP BY platform;
```

## Production Checklist

- [ ] Firebase project configured (Android & iOS)
- [ ] Database migrations executed successfully
- [ ] RLS policies tested and working
- [ ] Background handler tested (app closed scenario)
- [ ] Anonymous notification migration tested
- [ ] Topic subscriptions working
- [ ] Notification permissions requested properly
- [ ] Error handling implemented
- [ ] Monitoring queries saved
- [ ] Cleanup job scheduled
- [ ] Documentation updated
- [ ] Team trained on notification system

## Next Steps

1. **Admin Panel:** Buat UI untuk admin mengirim notifikasi
2. **Scheduling:** Tambah fitur schedule notification
3. **Templates:** Buat template notification untuk berbagai event
4. **Rich Notifications:** Tambah gambar, action buttons
5. **Analytics:** Track notification open rate
6. **A/B Testing:** Test berbagai judul dan isi notifikasi
