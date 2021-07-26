
import 'dart:convert';
import 'dart:developer';

import 'package:sport_log/api/backend_routes.dart';
import 'package:sport_log/models/new_user.dart';
import 'package:sport_log/models/user.dart';
import 'package:http/http.dart' as http;

enum ApiError {
  usernameTaken, unknown
}

class Api {
  Api({
    required this.urlBase
  });

  final String urlBase;
  final _client = http.Client();

  Future<User> createUser(NewUser newUser) async {
    // TODO: Error handling
    final response = await _client.post(
      Uri.parse(urlBase + BackendRoutes.user),
      body: jsonEncode(newUser.toJson()),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      }
    );
    if (response.statusCode == 409) {
      throw ApiError.usernameTaken;
    } else if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      log("${response.statusCode}\n${response.body}", name: "api error");
      throw ApiError.unknown;
    }
  }
}