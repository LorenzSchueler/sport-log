import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

abstract class PermissionRequest {
  // Repeatedly request permission until it is either granted or the user chooses to ignore the request.
  //
  // Returns whether the permission has been granted.
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
