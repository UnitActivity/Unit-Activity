# Push Notifications Setup Guide

## Overview
Aplikasi ini menggunakan Firebase Cloud Messaging (FCM) untuk mengirim push notifications kepada user. **Notifikasi akan tetap berfungsi meskipun user sudah logout**, sehingga user tetap bisa mendapatkan update penting dari admin dan UKM.

## Fitur

### 1. Persistent Notifications (Notifikasi Persisten)
- ✅ FCM token disimpan di device storage
- ✅ Token tetap aktif meskipun user logout
- ✅ User bisa menerima broadcast notifications dari admin
- ✅ Token otomatis terhubung ke user saat login

### 2. Notification Types (Tipe Notifikasi)
- **Broadcast Notifications**: Notifikasi dari admin ke semua user (topic: `all_users`)
- **UKM Notifications**: Notifikasi dari UKM tertentu (topic: `ukm_{id_ukm}`)
- **Personal Notifications**: Notifikasi khusus untuk user tertentu

### 3. Notification Flow

#### Saat Aplikasi Pertama Kali Dibuka:
```
1. App requests notification permission
2. FCM generates unique token
3. Token saved to local storage (SharedPreferences)
4. Token registered to backend (device_tokens table)
5. Subscribe to 'all_users' topic
```

#### Saat User Login:
```
1. Update device_tokens table with user_id
2. Subscribe to relevant UKM topics
3. User can now receive personal & UKM notifications
```

#### Saat User Logout:
```
1. Clear user_id from device_tokens (but keep token!)
2. Token remains active for broadcast notifications
3. User still receives admin announcements
```

## Implementation

### Backend Setup (Supabase)

1. **Create device_tokens table**:
```bash
# Run this SQL migration
supabase db push database/migrations/create_device_tokens_table.sql
```

2. **Table Structure**:
```sql
device_tokens (
  token TEXT PRIMARY KEY,           -- FCM token
  id_user UUID (nullable),          -- User ID (NULL for logged out)
  platform TEXT,                    -- 'android' | 'ios' | 'web'
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### Flutter App Setup

1. **Initialize Push Notifications** (in main.dart):
```dart
// Already implemented in main.dart
final pushService = PushNotificationService();
await pushService.initialize();
await pushService.subscribeToAdminNotifications();
```

2. **Handle Login**:
```dart
// Already implemented in custom_auth_service.dart
await pushService.updateUserAssociation(userId);
```

3. **Handle Logout**:
```dart
// Already implemented in custom_auth_service.dart
await pushService.clearUserAssociation();
// Token is preserved, only user association is cleared
```

### Sending Notifications

#### From Backend (Server-side)
You can send notifications using Firebase Admin SDK or Supabase Edge Functions:

```javascript
// Send to specific user
const response = await admin.messaging().send({
  token: userToken,
  notification: {
    title: 'Notifikasi Baru',
    body: 'Anda memiliki event baru'
  },
  data: {
    screen: 'event_detail',
    event_id: '123'
  }
});

// Send to topic (all subscribers)
await admin.messaging().send({
  topic: 'all_users',
  notification: {
    title: 'Pengumuman Admin',
    body: 'Sistem akan maintenance besok'
  }
});
```

#### From Supabase Function
```sql
-- Send notification to all users
SELECT send_push_notification(
  topic := 'all_users',
  title := 'Pengumuman',
  body := 'Event baru tersedia',
  data := '{"screen": "events"}'::jsonb
);

-- Send to specific UKM members
SELECT send_push_notification(
  topic := 'ukm_' || ukm_id,
  title := 'Pertemuan UKM',
  body := 'Jangan lupa hadir besok',
  data := '{"screen": "pertemuan", "id": "456"}'::jsonb
);
```

## Testing

### Test Notification
```dart
// In Flutter app
final pushService = PushNotificationService();
await pushService.sendTestNotification();
```

### Check Token Registration
```dart
final token = pushService.fcmToken;
print('FCM Token: $token');
```

### Debug Output
The service provides detailed logging:
```
========== INITIALIZING PUSH NOTIFICATIONS ==========
Notification permission: authorized
FCM Token: eABC123...xyz
FCM token saved to local storage
FCM token registered with backend
Subscribed to topic: all_users
✅ Push notifications initialized successfully
```

## Important Notes

1. **iOS Permissions**: 
   - User must grant notification permission
   - Request permission on app first launch

2. **Android**:
   - No permission needed for Android 12 and below
   - Android 13+ requires POST_NOTIFICATIONS permission

3. **Web Support**:
   - FCM works on web but requires Firebase config
   - Currently disabled (check `if (!kIsWeb)` conditions)

4. **Token Persistence**:
   - Tokens saved in SharedPreferences
   - Survives app updates and device restarts
   - Only cleared if user uninstalls app

5. **Security**:
   - Tokens are unique per device
   - No sensitive data stored in token
   - RLS policies protect token access

## Troubleshooting

### Notifications Not Received?
1. Check notification permission granted
2. Verify FCM token generated: `print(pushService.fcmToken)`
3. Check device_tokens table: token should be present
4. Test with `sendTestNotification()`
5. Check Firebase Console logs

### Token Not Saved?
1. Check SharedPreferences access
2. Verify backend connectivity
3. Check Supabase RLS policies
4. Look for error logs in console

### User Not Getting Personal Notifications After Login?
1. Verify `updateUserAssociation()` called
2. Check device_tokens table: `id_user` should be set
3. Ensure user subscribed to relevant topics

## Migration from Old System

If you have existing notification system:

1. **Keep Old System**: Can run both in parallel
2. **Gradual Migration**: Migrate users as they login
3. **Data Cleanup**: Remove old tokens after migration complete

## Future Enhancements

- [ ] Rich notifications with images
- [ ] Action buttons in notifications  
- [ ] Notification analytics
- [ ] In-app notification center
- [ ] Notification preferences/settings
- [ ] Scheduled notifications
- [ ] Notification categories/channels

## Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
