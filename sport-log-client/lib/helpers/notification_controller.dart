import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/helpers/request_permission.dart';

class NotificationController {
  static String fileChannel = "file_channel";
  static String expeditionChannel = "expedition_channel";

  static String openFileAction = "open_file";

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    if (receivedAction.channelKey == fileChannel) {
      if (receivedAction.buttonKeyPressed == openFileAction) {
        await openFile(receivedAction.payload);
      }
    }
  }

  static Future<void> openFile(Map<String, String?>? payload) async {
    final file = payload?["file"];
    if (file != null) {
      await PermissionRequest.request(Permission.manageExternalStorage);
      await OpenFile.open(file);
    }
  }
}
