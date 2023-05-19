import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';

final _logger = Logger("WriteToFile");

/// Writes content to file `filename` in downloads directory.
///
/// The file must be either a new file or must have been created with sport-log.
///
/// If successful it returns the path to the file.
Future<String?> writeToFile({
  required String content,
  required String filename,
  String fileExtension = "",
  bool append = false,
}) async {
  final dir = Config.isAndroid
      ? '/storage/emulated/0/Download'
      : Config.isIOS
          ? await getApplicationDocumentsDirectory()
          : (await getDownloadsDirectory())!;
  var file = File("$dir/$filename.$fileExtension");
  if (!append) {
    var index = 1;
    while (file.existsSync()) {
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
    _logger.w(e);
    return null;
  }
  return file.path;
}
