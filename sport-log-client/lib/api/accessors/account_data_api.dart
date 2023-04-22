part of '../api.dart';

class AccountDataApi with _ApiLogging {
  Future<ApiResult<AccountData>> get(DateTime? lastSync) async {
    final uri = _uri(lastSync);
    return ApiResultFromRequest.fromRequestWithValue(
      (client) async {
        final headers = _ApiHeaders._basicAuth;
        _logRequest('GET', uri, headers);
        final response = await client.get(
          uri,
          headers: headers,
        );
        _logResponse(response);
        return response;
      },
      (dynamic json) => AccountData.fromJson(json as Map<String, dynamic>),
    );
  }

  String _route(DateTime? dateTime) => dateTime == null
      ? '/account_data'
      : '/account_data?last_sync=${dateTime.toUtc().toIso8601String()}';

  Uri _uri(DateTime? dateTime) => Uri.parse(
        "${Settings.instance.serverUrl}/v${Config.apiVersion}${_route(dateTime)}",
      );
}
