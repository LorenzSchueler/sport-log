
import 'package:shared_preferences/shared_preferences.dart';

class LastSync {
  static const String key = 'last_sync';

  static Future<void> syncDone() async {
    final storage = await SharedPreferences.getInstance();
    storage.setString(key, DateTime.now().toString());
  }

  static Future<DateTime?> lastSync() async {
    final storage = await SharedPreferences.getInstance();
    final result = storage.getString(key);
    return result == null ? null : DateTime.parse(result);
  }
}