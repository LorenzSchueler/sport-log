import 'package:flutter/foundation.dart';
import 'package:sport_log/api/accessors/server_version_api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/helpers/result.dart';
import 'package:sport_log/models/server_version/server_version.dart';

class ServerVersionDataProvider {
  factory ServerVersionDataProvider() => _instance;

  ServerVersionDataProvider._();

  static final _instance = ServerVersionDataProvider._();

  final ServerVersionApi api = ServerVersionApi();

  Future<Result<ServerVersion, void>> getServerVersion({
    VoidCallback? onNoInternet,
  }) =>
      api.getServerVersion().onErrAsync(
            (err) => DataProvider.handleApiError(err, onNoInternet),
          );
}
