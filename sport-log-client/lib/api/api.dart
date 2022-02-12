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

abstract class Api<T extends JsonSerializable> with ApiLogging, ApiHelpers {
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
        headers: _ApiHeaders._defaultHeaders,
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
        headers: _ApiHeaders._defaultHeaders,
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
        headers: _ApiHeaders._defaultHeaders,
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
        headers: _ApiHeaders._defaultHeaders,
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

class _ApiHeaders {
  static Map<String, String> _makeAuthorizedHeader(
      String username, String password) {
    final basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    return {'authorization': basicAuth};
  }

  static Map<String, String> get _authorizedHeader {
    assert(Settings.instance.userExists());
    return _makeAuthorizedHeader(
        Settings.instance.username!, Settings.instance.password!);
  }

  static const Map<String, String> _jsonContentTypeHeader = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  static Map<String, String> get _defaultHeaders => {
        ..._authorizedHeader,
        ..._jsonContentTypeHeader,
      };
}

mixin ApiLogging {
  static final logger = Logger('API');

  String _prettyJson(dynamic json, {int indent = 2}) {
    var spaces = ' ' * indent;
    return JsonEncoder.withIndent(spaces).convert(json);
  }

  void _logRequest(String httpMethod, String route, [dynamic json]) {
    json != null && Config.outputRequestJson
        ? logger.d(
            'request: $httpMethod ${Settings.instance.serverUrl}$route\n${_prettyJson(json)}')
        : logger.d('request: $httpMethod ${Settings.instance.serverUrl}$route');
  }

  void _logResponse(Response response) {
    final body = utf8.decode(response.bodyBytes);
    final successful = response.statusCode >= 200 && response.statusCode < 300;
    body.isNotEmpty && (!successful || Config.outputRequestJson)
        ? logger.log(successful ? l.Level.debug : l.Level.error,
            'response: ${response.statusCode}\n${_prettyJson(jsonDecode(body))}')
        : logger.log(successful ? l.Level.debug : l.Level.error,
            'response: ${response.statusCode}');
  }
}

mixin ApiHelpers on ApiLogging {
  final _client = Client();

  Uri _uri(String route) => Uri.parse(Settings.instance.serverUrl + route);

  ApiResult<R> _errorHandling<R>(
      Future<Result<R, ApiError>> Function(Client client) req) async {
    try {
      return await req(_client);
    } on SocketException {
      return Failure(ApiError.noInternetConnection);
    } on TypeError {
      return Failure(ApiError.badJson);
    } catch (e) {
      ApiLogging.logger.e("Unhandled error", e);
      return Failure(ApiError.unhandled);
    }
  }

  ApiResult<R> _getRequest<R>(
      String route, R Function(dynamic) fromJson) async {
    return _errorHandling<R>((client) async {
      _logRequest('GET', route);
      final response = await client.get(
        _uri(route),
        headers: _ApiHeaders._authorizedHeader,
      );
      _logResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(fromJson(jsonDecode(utf8.decode(response.bodyBytes))));
    });
  }
}
