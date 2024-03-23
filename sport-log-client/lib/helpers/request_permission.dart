import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

abstract class PermissionRequest {
  // Repeatedly request permission until it is either granted or the user chooses to ignore the request.
  //
  // Returns whether the permission has been granted.
  static Future<bool> request(Permission permission) async {
    while (!await permission.request().isGranted) {
      final permissionSettings = await showPermissionRequiredDialog(
        text: "$permission is required.",
      );
      if (permissionSettings.isIgnore) {
        return false;
      }
    }
    return true;
  }
}

abstract class Request {
  // Repeatedly request until check either returns true or the user chooses to ignore the request.
  //
  // Returns whether check returned true.
  static Future<bool> request({
    required String title,
    required String text,
    required Future<bool> Function() check,
    required Future<void> Function()? change,
  }) async {
    while (!await check()) {
      final serviceSettings = await showRequiredDialog(
        title: title,
        text: text,
      );
      if (serviceSettings.isIgnore) {
        return false;
      }
      await change?.call();
    }
    return true;
  }
}
