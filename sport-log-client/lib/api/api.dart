import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';

export 'api_error.dart';

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
part 'api_accessor.dart';
part 'api_helpers.dart';

const String version = '/v1.0';

class Api {
  static final Api instance = Api._();
  Api._();

  final accountData = AccountDataApi();
  final user = UserApi();

  final actions = ActionApi();
  final actionProviders = ActionProviderApi();
  final actionRules = ActionRuleApi();
  final actionEvents = ActionEventApi();
  final cardioSessions = CardioSessionApi();
  final routes = RouteApi();
  final diaries = DiaryApi();
  final metcons = MetconApi();
  final metconSessions = MetconSessionApi();
  final metconMovements = MetconMovementApi();
  final movements = MovementApi();
  final platforms = PlatformApi();
  final platformCredentials = PlatformCredentialApi();
  final strengthSessions = StrengthSessionApi();
  final strengthSets = StrengthSetApi();
  final wods = WodApi();
}
