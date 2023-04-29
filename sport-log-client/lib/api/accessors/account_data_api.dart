import 'package:http/http.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/account_data/account_data.dart';

class AccountDataApi {
  factory AccountDataApi() => _instance;

  AccountDataApi._();

  static final _instance = AccountDataApi._();

  String _route(DateTime? dateTime) => dateTime == null
      ? '/account_data'
      : '/account_data?last_sync=${dateTime.toUtc().toIso8601String()}';

  Uri _uri(DateTime? dateTime) => Api.uriFromRoute(_route(dateTime));

  Future<ApiResult<AccountData>> get(DateTime? lastSync) =>
      (Request("get", _uri(lastSync))..headers.addAll(ApiHeaders.basicAuth))
          .toApiResultWithValue(
        (Object json) => AccountData.fromJson(json as Map<String, dynamic>),
      );
}
