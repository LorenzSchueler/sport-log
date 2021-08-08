
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:sport_log/api/backend_routes.dart';
import 'package:sport_log/models/user.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:http/http.dart' as http;

part 'user_api.dart';

class Credentials {
  Credentials({
    required this.username,
    required this.password,
    required this.userId,
  });

  String username, password;
  int userId;
}

class Api {

  static final Api instance = Api._();
  Api._();

  late final String urlBase;
  final _client = http.Client();
  Credentials? _credentials;

  void setCredentials(String username, String password, int userId) {
    _credentials = Credentials(
      username: username,
      password: password,
      userId: userId
    );
  }

  void removeCredentials() {
    _credentials = null;
  }

  Credentials? getCredentials() {
    return _credentials;
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

  /*
  Map<String, String> get _authorizedHeader {
    assert(_credentials != null);
    final username = _credentials!.username;
    final password = _credentials!.password;
    return _makeAuthorizedHeader(username, password);
  }
  */

  static const _jsonContentTypeHeader = {
    'Content-Type': 'application/json; charset=UTF-8',
  };
}