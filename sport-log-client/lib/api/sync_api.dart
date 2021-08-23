
part of 'api.dart';

extension SyncRoutes on Api {
  ApiResult<AccountData> getAccountData(DateTime? lastSync) {
    return _getSingle(BackendRoutes.sync(lastSync),
        fromJson: (json) => AccountData.fromJson(json));
  }
}
