import 'package:flutter/foundation.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/accessors/app_api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/helpers/write_to_file.dart';
import 'package:sport_log/models/server_version/server_version.dart';

class AppDataProvider {
  factory AppDataProvider() => _instance;

  AppDataProvider._();

  static final _instance = AppDataProvider._();

  final AppApi api = AppApi();

  Future<Result<UpdateInfo, void>> getUpdateInfo({
    VoidCallback? onNoInternet,
  }) async {
    final result = await api.getUpdateInfo();

    if (result.isFailure) {
      await DataProvider.handleApiError(
        result.failure,
        onNoInternet,
      );
      return Failure(null);
    } else {
      return result;
    }
  }

  Future<Result<String?, void>> downloadUpdate({
    VoidCallback? onNoInternet,
  }) async {
    final result = await api.downloadUpdate();

    if (result.isFailure) {
      await DataProvider.handleApiError(
        result.failure,
        onNoInternet,
      );
      return Failure(null);
    } else {
      final bytes = result.success;
      final filename = await writeBytesToFile(
        content: bytes,
        filename: "app",
        fileExtension: "apk",
      );
      return Success(filename);
    }
  }
}
