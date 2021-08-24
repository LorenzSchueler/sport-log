import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/api/backend_routes.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';

part 'action_api.dart';
part 'api_helpers.dart';
part 'cardio_api.dart';
part 'diary_api.dart';
part 'metcon_api.dart';
part 'movement_api.dart';
part 'platform_api.dart';
part 'strength_api.dart';
part 'sync_api.dart';
part 'user_api.dart';
part 'wod_api.dart';

final logger = Logger('API');

typedef ApiResult<T> = Future<Result<T, ApiError>>;

class Api {
  static final Api instance = Api._();

  Api._();

  void setCurrentUser(User user) {
    _currentUser = user;
  }

  void removeCurrentUser() {
    _currentUser = null;
  }

  void setUrlBase(String base) => _urlBase = base;

  User? get currentUser => _currentUser;

  late final String _urlBase;
  final _client = http.Client();
  User? _currentUser;
}
