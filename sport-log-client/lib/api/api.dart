import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/result.dart';
import 'package:sport_log/models/epoch/epoch_result.dart';
import 'package:sport_log/models/error_message.dart';
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
  _logger.t("request: ${request.method} ${request.url}$headersStr$jsonStr");
}

void _logResponse(StreamedResponse response, Object? json) {
  final headerStr = Config.instance.outputResponseHeaders
      ? "\n${response.headers.entries.map((e) => "${e.key}: ${e.value}").join("\n")}"
      : "";
  final jsonStr = Config.instance.outputResponseJson && json != null
      ? "\n\n${_prettyJson(json)}"
      : "";
  _logger.t("response: ${response.statusCode}$headerStr$jsonStr");
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
  unknownRequestError("Unknown request error."); // unknown request error

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
    final messageStr = message != null ? "\nReason: $message" : "";
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
              ? Ok(fromJson(json))
              // expected non empty body
              : Err(ApiError(ApiErrorType.badJson, statusCode))
          : Ok(null),
      204 => fromJson == null
          ? Ok(null)
          // expected non empty body and status 200
          : Err(ApiError(ApiErrorType.badJson, statusCode)),
      400 => Err(ApiError(ApiErrorType.badRequest, statusCode, json)),
      401 => Err(ApiError(ApiErrorType.unauthorized, statusCode, json)),
      403 => Err(ApiError(ApiErrorType.forbidden, statusCode, json)),
      404 => Err(ApiError(ApiErrorType.notFound, statusCode, json)),
      409 => Err(ApiError(ApiErrorType.conflict, statusCode, json)),
      500 => Err(ApiError(ApiErrorType.internalServerError, statusCode, json)),
      _ => Err(ApiError(ApiErrorType.unknownServerError, statusCode, json)),
    };
  }

  Future<ApiResult<Uint8List>> toBytes() async {
    _logResponse(this, null);
    final rawBody = await stream.toBytes();
    return switch (statusCode) {
      200 => Ok(rawBody),
      204 => Err(ApiError(ApiErrorType.badJson, statusCode)),
      400 => Err(ApiError(ApiErrorType.badRequest, statusCode)),
      401 => Err(ApiError(ApiErrorType.unauthorized, statusCode)),
      403 => Err(ApiError(ApiErrorType.forbidden, statusCode)),
      404 => Err(ApiError(ApiErrorType.notFound, statusCode)),
      409 => Err(ApiError(ApiErrorType.conflict, statusCode)),
      500 => Err(ApiError(ApiErrorType.internalServerError, statusCode)),
      _ => Err(ApiError(ApiErrorType.unknownServerError, statusCode)),
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
      return Err(ApiError(ApiErrorType.serverUnreachable, null));
    } on HttpException {
      return Err(ApiError(ApiErrorType.serverUnreachable, null));
    } on OSError catch (error, stackTrace) {
      if (error.message.contains("Software caused connection abort")) {
        return Err(ApiError(ApiErrorType.serverUnreachable, null));
      } else {
        _logger.e(
          "unknown error",
          error: error,
          caughtBy: "RequestExtension._handlerError",
          stackTrace: stackTrace,
        );
        return Err(ApiError(ApiErrorType.unknownRequestError, null));
      }
    } on TypeError {
      return Err(ApiError(ApiErrorType.badJson, null));
    } catch (error, stackTrace) {
      _logger.e(
        "unknown error",
        error: error,
        caughtBy: "RequestExtension._handlerError",
        stackTrace: stackTrace,
      );
      return Err(ApiError(ApiErrorType.unknownRequestError, null));
    }
  }

  Future<ApiResult<void>> toApiResult() => _handleError(() async {
        _logRequest(this);
        final response = await _client.send(this);
        return response.toApiResult(null);
      });

  Future<ApiResult<T>> toApiResultWithValue<T extends Object>(
    T Function(Object) fromJson,
  ) =>
      _handleError(() async {
        _logRequest(this);
        final response = await _client.send(this);
        return response.toApiResult(fromJson).mapAsync((success) => success!);
      });

  Future<ApiResult<Uint8List>> toBytes() => _handleError(() async {
        _logRequest(this);
        final response = await _client.send(this);
        return response.toBytes();
      });
}

abstract class Api<T extends JsonSerializable> {
  T fromJson(Map<String, dynamic> json);

  /// everything after version, e. g. '/user'
  String get route;

  static Uri uriFromRoute(String route) =>
      Uri.parse("${Settings.instance.serverUrl}/v${Config.apiVersion}$route");
  Uri get _uri => uriFromRoute(route);
  Map<String, dynamic> _toJson(T object) => object.toJson();

  Future<ApiResult<EpochResult?>> postSingle(T object) => (Request("post", _uri)
            ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
            ..body = jsonEncode(_toJson(object)))
          .toApiResultWithValue(
        (json) => EpochResult.fromJson((json as Map).cast()),
      );

  Future<ApiResult<EpochResult?>> postMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Ok(null);
    }
    return (Request("post", _uri)
          ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
          ..body = jsonEncode(objects.map(_toJson).toList()))
        .toApiResultWithValue(
      (json) => EpochResult.fromJson((json as Map).cast()),
    );
  }

  Future<ApiResult<EpochResult?>> putSingle(T object) => (Request("put", _uri)
            ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
            ..body = jsonEncode(_toJson(object)))
          .toApiResultWithValue(
        (json) => EpochResult.fromJson((json as Map).cast()),
      );

  Future<ApiResult<EpochResult?>> putMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Ok(null);
    }
    return (Request("put", _uri)
          ..headers.addAll(ApiHeaders.basicAuthContentTypeJson)
          ..body = jsonEncode(objects.map(_toJson).toList()))
        .toApiResultWithValue(
      (json) => EpochResult.fromJson((json as Map).cast()),
    );
  }
}

class ApiHeaders {
  static Map<String, String> basicAuthFromParts(
    String username,
    String password,
  ) =>
      {
        HttpHeaders.authorizationHeader:
            "Basic ${base64Encode(utf8.encode('$username:$password'))}",
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
