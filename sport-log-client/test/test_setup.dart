import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:sport_log/config.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes [Config], which reads the local `sport-log-client.yaml` in test mode.
Future<void> initConfig() async {
  PackageInfo.setMockInitialValues(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
    buildSignature: '',
  );
  await Config.init();
}

/// Uses sqflite_common_ffi with a new temporary databases directory and returns it.
/// Test files run in parallel, so they would otherwise reset each other's database.
Future<Directory> initDatabaseFactory() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final directory = await Directory.systemTemp.createTemp();
  await databaseFactory.setDatabasesPath(directory.path);
  return directory;
}
