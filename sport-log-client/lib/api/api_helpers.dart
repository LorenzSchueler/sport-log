part of 'api.dart';

mixin ApiHeaders {
  Map<String, String> _makeAuthorizedHeader(String username, String password) {
    final basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    return {'authorization': basicAuth};
  }

  Map<String, String> get _authorizedHeader {
    assert(Settings.instance.userExists());
    return _makeAuthorizedHeader(
        Settings.instance.username!, Settings.instance.password!);
  }

  Map<String, String> get _jsonContentTypeHeader => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Map<String, String> get _defaultHeaders => {
        ..._authorizedHeader,
        ..._jsonContentTypeHeader,
      };
}

mixin ApiLogging {
  static final logger = Logger('API');

  String _prettyJson(dynamic json, {int indent = 2}) {
    var spaces = ' ' * indent;
    var encoder = JsonEncoder.withIndent(spaces);
    return encoder.convert(json);
  }

  void _logRequest(String httpMethod, String route, [dynamic json]) {
    if (json != null && Config.outputRequestJson) {
      final prettyJson = _prettyJson(json);
      logger.d('request: $httpMethod $route\n$prettyJson');
    } else {
      logger.d('request: $httpMethod $route');
    }
  }

  void _logResponse(Response response) {
    final body = utf8.decode(response.bodyBytes);
    final successful = response.statusCode >= 200 && response.statusCode < 300;
    if (body.isNotEmpty && (!successful || Config.outputRequestJson)) {
      dynamic jsonObject = jsonDecode(body);
      logger.log(successful ? l.Level.debug : l.Level.error,
          'response: ${response.statusCode}\n${_prettyJson(jsonObject)}');
    } else {
      logger.log(successful ? l.Level.debug : l.Level.error,
          'response: ${response.statusCode}');
    }
  }
}

mixin ApiHelpers on ApiLogging, ApiHeaders {
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
        headers: _authorizedHeader,
      );
      _logResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(fromJson(jsonDecode(utf8.decode(response.bodyBytes))));
    });
  }
}
