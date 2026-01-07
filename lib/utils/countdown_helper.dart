import 'package:intl/intl.dart';

enum RegistrationStatus {
  belumDibuka, // Sebelum registration_start_date
  dibuka, // Antara start dan end
  ditutup, // Setelah registration_end_date
  tidakAda, // Tidak ada tanggal pendaftaran
}

class CountdownHelper {
  /// Get status pendaftaran berdasarkan waktu sekarang
  static RegistrationStatus getRegistrationStatus(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null || endDate == null) {
      return RegistrationStatus.tidakAda;
    }

    final now = DateTime.now();

    if (now.isBefore(startDate)) {
      return RegistrationStatus.belumDibuka;
    } else if (now.isAfter(endDate)) {
      return RegistrationStatus.ditutup;
    } else {
      return RegistrationStatus.dibuka;
    }
  }

  /// Check apakah pendaftaran sedang dibuka
  static bool isRegistrationOpen(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get countdown text dari sekarang sampai target date
  /// Returns: "2 hari 5 jam 30 menit" atau "Berakhir"
  static String getCountdownText(DateTime targetDate) {
    final now = DateTime.now();

    if (now.isAfter(targetDate)) {
      return 'Berakhir';
    }

    final difference = targetDate.difference(now);

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return '$days hari $hours jam';
    } else if (hours > 0) {
      return '$hours jam $minutes menit';
    } else if (minutes > 0) {
      return '$minutes menit';
    } else {
      return 'Beberapa detik lagi';
    }
  }

  /// Get detailed countdown dengan detik
  static String getDetailedCountdown(DateTime targetDate) {
    final now = DateTime.now();

    if (now.isAfter(targetDate)) {
      return 'Berakhir';
    }

    final difference = targetDate.difference(now);

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    List<String> parts = [];

    if (days > 0) parts.add('$days hari');
    if (hours > 0) parts.add('$hours jam');
    if (minutes > 0) parts.add('$minutes menit');
    if (days == 0 && hours == 0) parts.add('$seconds detik');

    return parts.isEmpty ? 'Berakhir' : parts.join(' ');
  }

  /// Get remaining duration
  static Duration getRemainingDuration(DateTime targetDate) {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) {
      return Duration.zero;
    }
    return targetDate.difference(now);
  }

  /// Format DateTime dengan zona waktu
  /// Output: "07 Jan 2026, 14:30"
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  /// Format DateTime tanpa tahun
  /// Output: "07 Jan, 14:30"
  static String formatDateTimeShort(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd MMM, HH:mm', 'id_ID').format(dateTime);
  }

  /// Format hanya tanggal
  /// Output: "07 Jan 2026"
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
  }

  /// Format hanya waktu
  /// Output: "14:30"
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Get countdown progress (0.0 - 1.0)
  /// Untuk progress bar/indicator
  static double getCountdownProgress(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();

    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;

    final totalDuration = endDate.difference(startDate);
    final elapsed = now.difference(startDate);

    return elapsed.inMilliseconds / totalDuration.inMilliseconds;
  }

  /// Get status text untuk display
  static String getStatusText(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.belumDibuka:
        return 'Belum Dibuka';
      case RegistrationStatus.dibuka:
        return 'Dibuka';
      case RegistrationStatus.ditutup:
        return 'Ditutup';
      case RegistrationStatus.tidakAda:
        return 'Tidak Tersedia';
    }
  }

  /// Combine date and time
  static DateTime combineDateAndTime(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
