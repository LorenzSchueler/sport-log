import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/api/backend_routes.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';

part 'accessors/action_api.dart';
part 'accessors/cardio_api.dart';
part 'accessors/diary_api.dart';
part 'accessors/metcon_api.dart';
part 'accessors/movement_api.dart';
part 'accessors/platform_api.dart';
part 'accessors/strength_api.dart';
part 'accessors/sync_api.dart';
part 'accessors/user_api.dart';
part 'accessors/wod_api.dart';
part 'api_helpers.dart';

final _logger = Logger('API');

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
