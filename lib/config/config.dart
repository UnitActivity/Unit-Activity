import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Fallback values for web platform
  static const String _fallbackUrl = 'https://xrnxoywvuzexvdifkryd.supabase.co';
  static const String _fallbackAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhybnhveXd2dXpleHZkaWZrcnlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4MzI5NjksImV4cCI6MjA3NzQwODk2OX0.TZM_jAY64ngBHgZO3dCv8ADgqWW-UgfllUEB7CvYdNY';

  static String get supabaseUrl {
    try {
      final envUrl = dotenv.env['SUPABASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    } catch (e) {
      // dotenv not initialized or error accessing env
    }
    return _fallbackUrl;
  }

  static String get supabaseAnonKey {
    try {
      final envKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (e) {
      // dotenv not initialized or error accessing env
    }
    return _fallbackAnonKey;
  }
}
