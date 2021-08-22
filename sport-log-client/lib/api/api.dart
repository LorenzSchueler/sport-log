
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/backend_routes.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:http/http.dart' as http;
import 'package:sport_log/config.dart';
import 'package:sport_log/models/all.dart';

part 'movement_api.dart';
part 'metcon_api.dart';
part 'cardio_api.dart';
part 'diary_api.dart';
part 'wod_api.dart';
part 'strength_api.dart';
part 'user_api.dart';
part 'platform_api.dart';
part 'action.dart';
part 'api_helpers.dart';

typedef ApiResult<T> = Future<Result<T, ApiError>>;

class Api {

  static final Api instance = Api._();
  Api._();

  Future<void> init() async {
    _urlBaseOptional = await Config.apiUrlBase;
  }

  void setCurrentUser(User user) {
    _currentUser = user;
  }

  void removeCurrentUser() {
    _currentUser = null;
  }

  User? get currentUser => _currentUser;

  String? _urlBaseOptional;
  final _client = http.Client();
  User? _currentUser;
}