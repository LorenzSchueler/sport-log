import 'package:flutter/foundation.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/accessors/server_version_api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/models/server_version/server_version.dart';

class ServerVersionDataProvider {
  factory ServerVersionDataProvider() => _instance;

  ServerVersionDataProvider._();

  static final _instance = ServerVersionDataProvider._();

  final ServerVersionApi api = ServerVersionApi();

  Future<Result<ServerVersion, void>> getServerVersion({
    VoidCallback? onNoInternet,
  }) async {
    final result = await api.getServerVersion();

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
}
