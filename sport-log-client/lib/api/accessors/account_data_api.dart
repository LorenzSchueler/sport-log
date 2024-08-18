import 'dart:convert';

import 'package:http/http.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/epoch/epoch_map.dart';

class AccountDataApi {
  factory AccountDataApi() => _instance;

  AccountDataApi._();

  static final _instance = AccountDataApi._();

  final _uri = Api.uriFromRoute('/account_data');

  Future<ApiResult<AccountData>> get(EpochMap? epochMap) =>
      (Request("get", _uri)
            ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
            ..body = epochMap != null ? jsonEncode(epochMap.toJson()) : "null")
          .toApiResultWithValue(
        (json) => AccountData.fromJson((json as Map).cast()),
      );
}
