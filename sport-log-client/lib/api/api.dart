import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart' as l;
import 'package:result_type/result_type.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/error_message.dart';
import 'package:sport_log/models/server_version/server_version.dart';
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

String apiVersion = '/v${Config.apiVersion}';

enum ApiErrorCode {
  // http error
  badRequest, // 400
  unauthorized, // 401
  forbidden, // 403
  notFound, // 404
  conflict, // 409
  internalServerError, // 500
  unknownServerError, // unknown status code != 200, 204, 400, 401, 403, 404, 409, 500
  // request error
  serverUnreachable,
  badJson,
  unknownRequestError; // unknown request error

  String get description {
    switch (this) {
      case ApiErrorCode.badRequest:
        return "Request was not valid.";
      case ApiErrorCode.unauthorized:
        return "User unauthorized";
      case ApiErrorCode.forbidden:
        return "Access to resource is forbidden.";
      case ApiErrorCode.notFound:
        return "Resource not found.";
      case ApiErrorCode.conflict:
        return "Conflict with resource.";
      case ApiErrorCode.internalServerError:
        return "Internal server error.";
      case ApiErrorCode.unknownServerError:
        return "An unknown server error.";
      case ApiErrorCode.serverUnreachable:
        return "It was not possible to establish a connection with the server.";
      case ApiErrorCode.badJson:
        return "Got bad json from server.";
      case ApiErrorCode.unknownRequestError:
        return "Unhandled request error.";
    }
  }
}

class ApiError {
  ApiError(this.errorCode, [this.message]);

  final ApiErrorCode errorCode;

  /// contains always only one entry
  final Map<String, ConflictDescriptor>? message;

  @override
  String toString() {
    return message != null
        ? "${errorCode.description}\n${message!.keys.first} in table ${message!.values.first.table} on columns ${message!.values.first.columns.join(', ')}"
        : errorCode.description;
  }
}

typedef ApiResult<T> = Result<T, ApiError>;

extension _ToApiResult on Response {
  Map<String, ConflictDescriptor>? get _message => ErrorMessage.fromJson(
        jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>,
      ).message;

  ApiResult<T?> _mapToApiResult<T>(T Function()? fromJson) {
    switch (statusCode) {
      case 200:
        return Success(fromJson?.call());
      case 204:
        return fromJson == null
            ? Success(null)
            : Failure(
                ApiError(ApiErrorCode.unknownServerError),
              ); // value needed but nothing returned
      case 400:
        return Failure(ApiError(ApiErrorCode.badRequest, _message));
      case 401:
        return Failure(ApiError(ApiErrorCode.unauthorized, _message));
      case 403:
        return Failure(ApiError(ApiErrorCode.forbidden, _message));
      case 404:
        return Failure(ApiError(ApiErrorCode.notFound, _message));
      case 409:
        return Failure(ApiError(ApiErrorCode.conflict, _message));
      case 500:
        return Failure(ApiError(ApiErrorCode.internalServerError, _message));
      default:
        return Failure(ApiError(ApiErrorCode.unknownServerError, _message));
    }
  }

  ApiResult<void> toApiResult() => _mapToApiResult(null);

  ApiResult<T> toApiResultWithValue<T>(T Function(dynamic) fromJson) {
    final result = _mapToApiResult(
      () => fromJson(jsonDecode(utf8.decode(bodyBytes))),
    );
    return result.isSuccess
        ? Success(result.success as T)
        : Failure(result.failure);
  }
}

extension ApiResultFromRequest on ApiResult {
  static final _ioClient = HttpClient()..connectionTimeout = Config.httpTimeout;
  static final _client = IOClient(_ioClient);

  static Future<ApiResult<T>> _handleError<T>(
    Future<ApiResult<T>> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException {
      return Failure(ApiError(ApiErrorCode.serverUnreachable));
    } on TypeError {
      return Failure(ApiError(ApiErrorCode.badJson));
    } catch (e) {
      ApiLogging.logger.e("Unhandled error", e);
      return Failure(ApiError(ApiErrorCode.unknownRequestError));
    }
  }

  static Future<ApiResult<void>> fromRequest(
    Future<Response> Function(Client client) request,
  ) =>
      _handleError(() async {
        final response = await request(_client);
        return response.toApiResult();
      });

  static Future<ApiResult<T>> fromRequestWithValue<T>(
    Future<Response> Function(Client client) request,
    T Function(dynamic) fromJson,
  ) =>
      _handleError(() async {
        final response = await request(_client);
        return response.toApiResultWithValue(fromJson);
      });
}

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

  static Future<ApiResult<ServerVersion>> getServerVersion() {
    const route = "/version";
    return ApiResultFromRequest.fromRequestWithValue<ServerVersion>(
      (client) => client.get(UriFromRoute.fromRoute(route)),
      (dynamic json) => ServerVersion.fromJson(json as Map<String, dynamic>),
    );
  }

  // things needed to be overridden
  T _fromJson(Map<String, dynamic> json);
  String get _singularRoute; // everything after url base, e. g. '/v1.0/user'

  // default implementations
  String get _pluralRoute => '${_singularRoute}s';
  Map<String, dynamic> _toJson(T object) => object.toJson();

  Future<ApiResult<T>> getSingle(Int64 id) async {
    return _getRequest(
      '$_singularRoute/$id',
      (dynamic json) => _fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResult<List<T>>> getMultiple() async {
    return _getRequest(
      _singularRoute,
      (dynamic json) => (json as List<dynamic>)
          .map((dynamic json) => _fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResult<void>> postSingle(T object) async {
    return ApiResultFromRequest.fromRequest((client) async {
      final body = _toJson(object);
      final headers = _ApiHeaders._defaultHeaders;
      _logRequest('POST', _singularRoute, headers, body);
      final response = await client.post(
        UriFromRoute.fromRoute(_singularRoute),
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  Future<ApiResult<void>> postMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return ApiResultFromRequest.fromRequest((client) async {
      final body = objects.map(_toJson).toList();
      final headers = _ApiHeaders._defaultHeaders;
      _logRequest('POST', _pluralRoute, headers, body);
      final response = await client.post(
        UriFromRoute.fromRoute(_pluralRoute),
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  Future<ApiResult<void>> putSingle(T object) async {
    return ApiResultFromRequest.fromRequest((client) async {
      final body = _toJson(object);
      final headers = _ApiHeaders._defaultHeaders;
      _logRequest('PUT', _singularRoute, headers, body);
      final response = await client.put(
        UriFromRoute.fromRoute(_singularRoute),
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  Future<ApiResult<void>> putMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return ApiResultFromRequest.fromRequest((client) async {
      final body = objects.map(_toJson).toList();
      final headers = _ApiHeaders._defaultHeaders;
      _logRequest('PUT', _pluralRoute, headers, body);
      final response = await client.put(
        UriFromRoute.fromRoute(_pluralRoute),
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }
}

class _ApiHeaders {
  static Map<String, String> _basicAuth(String username, String password) {
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    return {'authorization': basicAuth};
  }

  static const Map<String, String> _jsonContentType = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  static Map<String, String> get _defaultHeaders => {
        ..._basicAuth(Settings.instance.username!, Settings.instance.password!),
        ..._jsonContentType,
      };
}

mixin ApiLogging {
  static final logger = Logger('API');

  String _prettyJson(dynamic json, {int indent = 2}) {
    var spaces = ' ' * indent;
    return JsonEncoder.withIndent(spaces).convert(json);
  }

  void _logRequest(
    String httpMethod,
    String route,
    Map<String, String> headers, [
    dynamic json,
  ]) {
    final headersStr = Config.instance.outputRequestHeaders
        ? "\n${headers.entries.map((e) => '${e.key}:${e.value}').join('\n')}"
        : "";
    json != null && Config.instance.outputRequestJson
        ? logger.d(
            'request: $httpMethod ${Settings.instance.serverUrl}$route$headersStr\n${_prettyJson(json)}',
          )
        : logger.d(
            'request: $httpMethod ${Settings.instance.serverUrl}$route$headersStr',
          );
  }

  void _logResponse(Response response) {
    final body = utf8.decode(response.bodyBytes);
    final successful = response.statusCode >= 200 && response.statusCode < 300;
    body.isNotEmpty && (!successful || Config.instance.outputResponseJson)
        ? logger.log(
            successful ? l.Level.debug : l.Level.error,
            'response: ${response.statusCode}\n${_prettyJson(jsonDecode(body))}',
          )
        : logger.log(
            successful ? l.Level.debug : l.Level.error,
            'response: ${response.statusCode}',
          );
  }
}

extension UriFromRoute on Uri {
  static Uri fromRoute(String route) =>
      Uri.parse(Settings.instance.serverUrl + route);
}

mixin ApiHelpers on ApiLogging {
  Future<ApiResult<T>> _getRequest<T>(
    String route,
    T Function(dynamic) fromJson,
  ) async {
    return ApiResultFromRequest.fromRequestWithValue<T>(
      (client) async {
        final headers = _ApiHeaders._basicAuth(
          Settings.instance.username!,
          Settings.instance.password!,
        );
        _logRequest('GET', route, headers);
        final response = await client.get(
          UriFromRoute.fromRoute(route),
          headers: headers,
        );
        _logResponse(response);
        return response;
      },
      fromJson,
    );
  }
}
