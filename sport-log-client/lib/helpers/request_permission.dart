import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

abstract class PermissionRequest {
  static Future<bool> request(Permission permission) async {
    while (!await permission.request().isGranted) {
      final systemSettings = await showSystemSettingsDialog(
        text: "$permission is required.",
      );
      if (systemSettings.isIgnore) {
        return false;
      }
    }
    return true;
  }
}
