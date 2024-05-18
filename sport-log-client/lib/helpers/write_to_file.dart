import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/result.dart';

final _logger = Logger("WriteToFile");

File _nextFile(
  String dir,
  String filename,
  String fileExtension,
) {
  var file = File("$dir/$filename.$fileExtension");
  var index = 1;
  while (file.existsSync()) {
    file = File("$dir/$filename($index).$fileExtension");
    index++;
  }
  return file;
}

/// Writes content to file `filename.fileExtension` in downloads directory.
///
/// If the file already exits (and `append` is false) it writes to `filename(1).fileExtension` and so on.
///
/// The file must be either a new file or must have been created with sport-log.
///
/// If successful it returns the path to the file.
Future<Result<String, void>> writeToFile({
  required String content,
  required String filename,
  required String fileExtension,
  bool append = false,
}) async {
  final dir = Config.isAndroid
      ? '/storage/emulated/0/Download'
      : (await getDownloadsDirectory())!.path;
  final file = append
      ? File("$dir/$filename.$fileExtension")
      : _nextFile(dir, filename, fileExtension);
  try {
    await file.writeAsString(
      content,
      flush: true,
      mode: append ? FileMode.writeOnlyAppend : FileMode.writeOnly,
    );
  } on FileSystemException catch (error, stackTrace) {
    _logger.w(
      "writing file $file failed",
      error: error,
      stackTrace: stackTrace,
    );
    return Err(null);
  }
  return Ok(file.path);
}

/// Writes content to file `filename.fileExtension` in downloads directory.
///
/// If the file already exits it writes to `filename(1).fileExtension` and so on.
///
/// The file must be either a new file or must have been created with sport-log.
///
/// If successful it returns the path to the file.
Future<Result<String, void>> writeBytesToFileInDownloads({
  required Uint8List content,
  required String filename,
  required String fileExtension,
}) async {
  final dir = Config.isAndroid
      ? '/storage/emulated/0/Download'
      : (await getDownloadsDirectory())!.path;
  final file = _nextFile(dir, filename, fileExtension);
  try {
    await file.writeAsBytes(
      content,
      flush: true,
      mode: FileMode.writeOnly,
    );
  } on FileSystemException catch (error, stackTrace) {
    _logger.w(
      "writing file $file failed",
      error: error,
      stackTrace: stackTrace,
    );
    return Err(null);
  }
  return Ok(file.path);
}

/// Writes content to file `filename` in cache directory and returns the path to the file.
///
/// If the file already exists it will be overwritten.
Future<Result<String, void>> writeBytesToFile({
  required Uint8List content,
  required String filename,
  required String fileExtension,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/$filename.$fileExtension");
  try {
    await file.writeAsBytes(
      content,
      flush: true,
      mode: FileMode.writeOnly,
    );
  } on FileSystemException catch (error, stackTrace) {
    _logger.w(
      "writing file $file failed",
      error: error,
      stackTrace: stackTrace,
    );
    return Err(null);
  }
  return Ok(file.path);
}
