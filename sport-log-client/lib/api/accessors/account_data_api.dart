part of '../api.dart';

class AccountDataApi with ApiLogging, ApiHelpers {
  ApiResult<AccountData> get(DateTime? lastSync) async {
    return _getRequest(
      _route(lastSync),
      (dynamic json) => AccountData.fromJson(json as Map<String, dynamic>),
    );
  }

  String _route(DateTime? dateTime) =>
      version +
      (dateTime == null
          ? '/account_data'
          : '/account_data/${dateTime.toUtc().toIso8601String()}');
}
