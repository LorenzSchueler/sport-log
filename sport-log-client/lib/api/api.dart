import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart' as l;
import 'package:result_type/result_type.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/settings.dart';

part 'accessors/account_data_api.dart';
part 'accessors/action_api.dart';
part 'accessors/cardio_api.dart';
part 'accessors/diary_api.dart';
part 'accessors/metcon_api.dart';
part 'accessors/movement_api.dart';
part 'accessors/platform_api.dart';
part 'accessors/strength_api.dart';
part 'accessors/user_api.dart';
part 'accessors/wod_api.dart';
part 'api_helpers.dart';

const String version = '/v1.0';

enum ApiError {
  usernameTaken,
  noInternetConnection,
  loginFailed,
  notFound,
  unknown, // unknown status code from server
  unhandled, // unknown request error
  conflict,
  badJson,
  unauthorized,
}

extension ToErrorMessage on ApiError {
  String toErrorMessage() {
    switch (this) {
      case ApiError.usernameTaken:
        return "Username is already taken.";
      case ApiError.unknown:
        return "An unknown error occurred.";
      case ApiError.noInternetConnection:
        return "No Internet connection.";
      case ApiError.loginFailed:
        return "Wrong credentials.";
      case ApiError.notFound:
        return "Resource not found.";
      case ApiError.unhandled:
        return "Unhandled error occurred.";
      case ApiError.conflict:
        return "Conflict creating resource";
      case ApiError.badJson:
        return "Got bad json from server.";
      case ApiError.unauthorized:
        return "Unauthorized.";
    }
  }
}

typedef ApiResult<T> = Future<Result<T, ApiError>>;

abstract class Api<T extends JsonSerializable>
    with ApiHeaders, ApiLogging, ApiHelpers {
  static final accountData = AccountDataApi();
  static final user = UserApi();
  static final actions = ActionApi();
  static final actionProviders = ActionProviderApi();
  static final actionRules = ActionRuleApi();
  static final actionEvents = ActionEventApi();
  static final cardioSessions = CardioSessionApi();
  static final routes = RouteApi();
  static final diaries = DiaryApi();
  static final metcons = MetconApi();
  static final metconSessions = MetconSessionApi();
  static final metconMovements = MetconMovementApi();
  static final movements = MovementApi();
  static final platforms = PlatformApi();
  static final platformCredentials = PlatformCredentialApi();
  static final strengthSessions = StrengthSessionApi();
  static final strengthSets = StrengthSetApi();
  static final wods = WodApi();

  // things needed to be overridden
  T _fromJson(Map<String, dynamic> json);
  String get singularRoute; // everything after url base, e. g. '/v1.0/user'

  // default impls
  String get pluralRoute => singularRoute + 's';
  Map<String, dynamic> _toJson(T object) => object.toJson();

  ApiResult<T> getSingle(Int64 id) async {
    return _getRequest(singularRoute + '/$id',
        (dynamic json) => _fromJson(json as Map<String, dynamic>));
  }

  ApiResult<List<T>> getMultiple() async {
    return _getRequest(
        singularRoute,
        (dynamic json) => (json as List<dynamic>)
            .map((dynamic json) => _fromJson(json as Map<String, dynamic>))
            .toList());
  }

  ApiResult<void> postSingle(T object) async {
    return _errorHandling((client) async {
      final body = _toJson(object);
      _logRequest('POST', singularRoute, body);
      final response = await client.post(
        _uri(singularRoute),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode == 409) {
        return Failure(ApiError.conflict);
      }
      if (response.statusCode < 200 && response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }

  ApiResult<void> postMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return _errorHandling((client) async {
      final body = objects.map(_toJson).toList();
      _logRequest('POST', pluralRoute, body);
      final response = await client.post(
        _uri(pluralRoute),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode == 409) {
        return Failure(ApiError.conflict);
      }
      if (response.statusCode < 200 && response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }

  ApiResult<void> putSingle(T object) async {
    return _errorHandling((client) async {
      final body = _toJson(object);
      _logRequest('PUT', singularRoute, body);
      final response = await client.put(
        _uri(singularRoute),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode < 200 && response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }

  ApiResult<void> putMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return _errorHandling((client) async {
      final body = objects.map(_toJson).toList();
      _logRequest('PUT', pluralRoute, body);
      final response = await client.put(
        _uri(pluralRoute),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode < 200 && response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }
}
