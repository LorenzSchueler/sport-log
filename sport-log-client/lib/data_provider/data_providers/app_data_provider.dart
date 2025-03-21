import 'package:flutter/foundation.dart';
import 'package:sport_log/api/accessors/app_api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/helpers/result.dart';
import 'package:sport_log/helpers/write_to_file.dart';
import 'package:sport_log/models/server_version/server_version.dart';

class AppDataProvider {
  factory AppDataProvider() => _instance;

  AppDataProvider._();

  static final _instance = AppDataProvider._();

  final AppApi api = AppApi();

  Future<Result<UpdateInfo, void>> getUpdateInfo({
    VoidCallback? onNoInternet,
  }) => api.getUpdateInfo().mapErrAsync(
    (err) => DataProvider.handleApiError(err, onNoInternet),
  );

  Future<Result<String, void>> downloadUpdate({VoidCallback? onNoInternet}) =>
      api
          .downloadUpdate()
          .onErrAsync((err) => DataProvider.handleApiError(err, onNoInternet))
          .nullErr()
          .flatMapAsync(
            (bytes) => writeBytesToFile(
              content: bytes,
              filename: "app",
              fileExtension: "apk",
            ), // filename
          );
}
