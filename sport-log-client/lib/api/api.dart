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
import 'package:sport_log/models/error_message.dart';
import 'package:sport_log/models/server_version/server_version.dart';
import 'package:sport_log/settings.dart';

final _logger = Logger('API');

String _prettyJson(Object json, {int indent = 2}) {
  final spaces = ' ' * indent;
  return JsonEncoder.withIndent(spaces).convert(json);
}

void _logRequest(Request request) {
  final headersStr = Config.instance.outputRequestHeaders
      ? "\n${request.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n')}"
      : "";
  final jsonStr = Config.instance.outputRequestJson && request.body.isNotEmpty
      ? "\n\n${_prettyJson(jsonDecode(request.body) as Object)}"
      : "";
  _logger.d("request: ${request.method} ${request.url}$headersStr$jsonStr");
}

void _logResponse(StreamedResponse response, Object? json) {
  final successful = response.statusCode >= 200 && response.statusCode < 300;
  final headerStr = Config.instance.outputResponseHeaders
      ? "\n${response.headers.entries.map((e) => "${e.key}: ${e.value}").join("\n")}"
      : "";
  final jsonStr = Config.instance.outputResponseJson && json != null
      ? "\n\n${_prettyJson(json)}"
      : "";
  _logger.log(
    successful ? l.Level.debug : l.Level.error,
    "response: ${response.statusCode}$headerStr$jsonStr",
  );
}

enum ApiErrorType {
  // http error
  badRequest("Request is not valid."), // 400
  unauthorized("User unauthorized."), // 401
  forbidden("Access to resource is forbidden."), // 403
  notFound("Resource not found."), // 404
  conflict("Conflict with resource."), // 409
  internalServerError("Internal server error."), // 500
  // unknown status code != 200, 204, 400, 401, 403, 404, 409, 500 request error
  unknownServerError("Unknown server error."),
  serverUnreachable("Unable to establish a connection with the server."),
  badJson("Got bad json from server."),
  unknownRequestError("Unhandled request error."); // unknown request error

  const ApiErrorType(this.description);

  final String description;
}

class ApiError {
  ApiError(this.errorType, this.errorCode, [Object? jsonMessage])
      : message = jsonMessage != null
            ? HandlerError.fromJson(jsonMessage as Map<String, dynamic>).message
            : null;

  final ApiErrorType errorType;
  final int? errorCode;

  final ErrorMessage? message;

  @override
  String toString() {
    final description = errorType.description;
    final errorCodeStr = errorCode != null ? " (status $errorCode)" : "";
    final messageStr = message != null ? "\n$message" : "";
    return "$description$errorCodeStr$messageStr";
  }
}

typedef ApiResult<T> = Result<T, ApiError>;

extension _ToApiResult on StreamedResponse {
  Future<ApiResult<T?>> toApiResult<T>(T Function(Object)? fromJson) async {
    // steam can be read only once
    final rawBody = utf8.decode(await stream.toBytes());
    final json = rawBody.isEmpty ? null : jsonDecode(rawBody) as Object;
    _logResponse(this, json);

    return switch (statusCode) {
      200 => fromJson != null
          ? json != null
              ? Success(fromJson(json))
              // expected non empty body
              : Failure(ApiError(ApiErrorType.badJson, statusCode))
          : Success(null),
      204 => fromJson == null
          ? Success(null)
          // expected non empty body and status 200
          : Failure(ApiError(ApiErrorType.badJson, statusCode)),
      400 => Failure(ApiError(ApiErrorType.badRequest, statusCode, json)),
      401 => Failure(ApiError(ApiErrorType.unauthorized, statusCode, json)),
      403 => Failure(ApiError(ApiErrorType.forbidden, statusCode, json)),
      404 => Failure(ApiError(ApiErrorType.notFound, statusCode, json)),
      409 => Failure(ApiError(ApiErrorType.conflict, statusCode, json)),
      500 =>
        Failure(ApiError(ApiErrorType.internalServerError, statusCode, json)),
      _ => Failure(ApiError(ApiErrorType.unknownServerError, statusCode, json)),
    };
  }
}

extension RequestExtension on Request {
  static final _ioClient = HttpClient()..connectionTimeout = Config.httpTimeout;
  static final _client = IOClient(_ioClient);

  static Future<ApiResult<T>> _handleError<T>(
    Future<ApiResult<T>> Function() fn,
  ) async {
    try {
      return await fn();
    } on SocketException {
      return Failure(ApiError(ApiErrorType.serverUnreachable, null));
    } on TypeError {
      return Failure(ApiError(ApiErrorType.badJson, null));
    } catch (e) {
      _logger.e("Unhandled error", e);
      return Failure(ApiError(ApiErrorType.unknownRequestError, null));
    }
  }

  Future<ApiResult<void>> toApiResult() => _handleError(() async {
        _logRequest(this);
        final response = await _client.send(this);
        return response.toApiResult(null);
      });

  Future<ApiResult<T>> toApiResultWithValue<T>(T Function(Object) fromJson) =>
      _handleError(() async {
        _logRequest(this);
        final response = await _client.send(this);
        final result = await response.toApiResult(fromJson);
        return result.isSuccess
            ? Success(result.success as T)
            : Failure(result.failure);
      });
}

abstract class Api<T extends JsonSerializable> {
  static Future<ApiResult<ServerVersion>> getServerVersion() {
    final uri = Uri.parse("${Settings.instance.serverUrl}/version");
    return Request("get", uri).toApiResultWithValue(
      (json) => ServerVersion.fromJson(json as Map<String, dynamic>),
    );
  }

  T fromJson(Map<String, dynamic> json);

  /// everything after version, e. g. '/user'
  String get route;

  static Uri uriFromRoute(String route) =>
      Uri.parse("${Settings.instance.serverUrl}/v${Config.apiVersion}$route");
  Uri get _uri => uriFromRoute(route);
  Map<String, dynamic> _toJson(T object) => object.toJson();

  Future<ApiResult<T>> getSingle(Int64 id) =>
      (Request("get", Uri.parse("$_uri?id=$id"))
            ..headers.addAll(ApiHeaders.basicAuth))
          .toApiResultWithValue(
        (json) => fromJson(json as Map<String, dynamic>),
      );

  Future<ApiResult<List<T>>> getMultiple() =>
      (Request("get", _uri)..headers.addAll(ApiHeaders.basicAuth))
          .toApiResultWithValue(
        (json) => (json as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(fromJson)
            .toList(),
      );

  Future<ApiResult<void>> postSingle(T object) => (Request("post", _uri)
        ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
        ..body = jsonEncode(_toJson(object)))
      .toApiResult();

  Future<ApiResult<void>> postMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return (Request("post", _uri)
          ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
          ..body = jsonEncode(objects.map(_toJson).toList()))
        .toApiResult();
  }

  Future<ApiResult<void>> putSingle(T object) => (Request("put", _uri)
        ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
        ..body = jsonEncode(_toJson(object)))
      .toApiResult();

  Future<ApiResult<void>> putMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return (Request("put", _uri)
          ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
          ..body = jsonEncode(objects.map(_toJson).toList()))
        .toApiResult();
  }
}

class ApiHeaders {
  static Map<String, String> basicAuthFromParts(
    String username,
    String password,
  ) =>
      {
        HttpHeaders.authorizationHeader:
            "Basic ${base64Encode(utf8.encode('$username:$password'))}"
      };

  static const Map<String, String> contentTypeJson = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
  };

  static Map<String, String> get basicAuth => basicAuthFromParts(
        Settings.instance.username!,
        Settings.instance.password!,
      );

  static Map<String, String> get basicAuthContentTypeJson => {
        ...basicAuth,
        ...contentTypeJson,
      };
}
