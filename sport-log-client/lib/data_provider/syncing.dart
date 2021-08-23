import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/database/defs.dart';

Future<void> _syncDone() async {
  final storage = await SharedPreferences.getInstance();
  storage.setString(Keys.lastSync, DateTime.now().toString());
}

Future<DateTime?> _lastSync() async {
  final storage = await SharedPreferences.getInstance();
  final result = storage.getString(Keys.lastSync);
  return result == null ? null : DateTime.parse(result);
}