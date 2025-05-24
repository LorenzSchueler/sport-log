import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/helpers/request_permission.dart';

class NotificationController {
  NotificationController._();

  static const String _fileChannelId = "file_channel";
  static const String _fileChannelName = "File Notifications";
  static const String _openFileActionId = "open_file";
  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationController._fileChannelId,
      NotificationController._fileChannelName,
      actions: [
        AndroidNotificationAction(
          _openFileActionId,
          "Open",
          showsUserInterface: true,
        ),
      ],
    ),
  );

  static final NotificationController _instance = NotificationController._();
  final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _instance._plugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _instance._onNotificationResponse,
    );

    final androidPlugin = _instance._plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(_fileChannelId, _fileChannelName),
    );
  }

  static Future<void> showFileNotification(String message, String file) async {
    await _instance._plugin.show(
      Random().nextInt(1 << 31),
      message,
      file,
      _notificationDetails,
      payload: file,
    );
  }

  Future<void> _onNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final payload = notificationResponse.payload;
    if (notificationResponse.actionId == _openFileActionId && payload != null) {
      await PermissionRequest.request(Permission.manageExternalStorage);
      await OpenFile.open(payload);
    }
  }
}
