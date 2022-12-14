import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';

final _logger = Logger("WriteToFile");

/// Requests permission and writes content to file filename in downloads directory.
///
/// If successful it returns the path to the file.
Future<String?> writeToFile({
  required String content,
  required String filename,
  String fileExtension = "",
  bool append = false,
}) async {
  if (!(await Permission.storage.request()).isGranted ||
      !(await Permission.accessMediaLocation.request()).isGranted) {
    _logger.i("permission denied");
    return null;
  }
  final dir = Config.isAndroid
      ? '/storage/emulated/0/Download'
      : Config.isIOS
          ? await getApplicationDocumentsDirectory()
          : (await getDownloadsDirectory())!;
  var file = File("$dir/$filename.$fileExtension");
  if (!append) {
    var index = 1;
    while (await file.exists()) {
      file = File("$dir/$filename($index).$fileExtension");
      index++;
    }
  }
  try {
    await file.writeAsString(
      content,
      flush: true,
      mode: append ? FileMode.writeOnlyAppend : FileMode.writeOnly,
    );
  } on FileSystemException catch (e) {
    _logger.w(e.toString());
    return null;
  }
  return file.path;
}
