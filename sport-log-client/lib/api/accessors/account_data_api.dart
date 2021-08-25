part of '../api.dart';

class AccountDataApi with ApiHeaders, ApiLogging, ApiHelpers {
  ApiResult<AccountData> get(DateTime? lastSync) async {
    return _getRequest(route(lastSync),
        (dynamic json) => AccountData.fromJson(json as Map<String, dynamic>));
  }

  String route(DateTime? dateTime) =>
      version +
      (dateTime == null
          ? '/account_data'
          : '/account_data/${dateTime.toUtc().toIso8601String()}');
}
