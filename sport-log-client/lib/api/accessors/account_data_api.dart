part of '../api.dart';

class AccountDataApi with ApiLogging, ApiHelpers {
  Future<ApiResult<AccountData>> get(DateTime? lastSync) async {
    return _getRequest(
      _path(lastSync),
      (dynamic json) => AccountData.fromJson(json as Map<String, dynamic>),
    );
  }

  String _route(DateTime? dateTime) => dateTime == null
      ? '/account_data'
      : '/account_data?last_sync=${dateTime.toUtc().toIso8601String()}';

  String _path(DateTime? dateTime) =>
      "/v${Config.apiVersion}${_route(dateTime)}";
}
