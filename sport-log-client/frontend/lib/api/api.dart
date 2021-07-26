
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:sport_log/api/backend_routes.dart';
import 'package:sport_log/models/new_user.dart';
import 'package:sport_log/models/user.dart';
import 'package:http/http.dart' as http;

part 'user_api.dart';

enum ApiError {
  usernameTaken, unknown, noInternetConnection, loginFailed
}

class Credentials {
  Credentials({
    required this.username,
    required this.password,
  });

  String username, password;
}

class Api {
  Api({
    required this.urlBase
  });

  final String urlBase;
  final _client = http.Client();
  Credentials? _credentials;

  void setCredentials(String username, String password) {
    _credentials = Credentials(
        username: username,
        password: password,
    );
  }

  void removeCredentials() {
    _credentials = null;
  }

  void _handleUnknownStatusCode(http.Response response) {
    log("${response.statusCode}\n${response.body}", name: "unknown api error");
  }

  Map<String, String> _makeAuthorizedHeader(String username, String password) {
    final basicAuth = 'Basic '
        + base64Encode(utf8.encode('$username:$password'));
    return {
      'authorization': basicAuth
    };
  }

  Map<String, String> get _authorizedHeader {
    assert(_credentials != null);
    final username = _credentials!.username;
    final password = _credentials!.password;
    return _makeAuthorizedHeader(username, password);
  }

  static const _jsonContentTypeHeader = {
    'Content-Type': 'application/json; charset=UTF-8',
  };
}