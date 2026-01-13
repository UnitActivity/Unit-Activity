import 'package:flutter/foundation.dart';

class ProfileImageService {
  static final ProfileImageService instance = ProfileImageService._();

  ProfileImageService._();

  final ValueNotifier<String?> _profileImageUrl = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _userName = ValueNotifier<String?>('Admin');

  ValueListenable<String?> get profileImageUrl => _profileImageUrl;
  ValueListenable<String?> get userName => _userName;

  void updateProfileImage(String? url) {
    // Tambakan timestamp untuk bust cache jika url sama
    if (url != null && !url.contains('?t=')) {
      _profileImageUrl.value =
          '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } else {
      _profileImageUrl.value = url;
    }
  }

  void updateUserName(String name) {
    _userName.value = name;
  }
}
