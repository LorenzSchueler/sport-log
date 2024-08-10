import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/epoch/epoch_map.dart';

part 'account_data.g.dart';

@JsonSerializable()
class AccountData {
  AccountData({
    required this.user,
    required this.diaries,
    required this.wods,
    required this.movements,
    required this.strengthSessions,
    required this.strengthSets,
    required this.metcons,
    required this.metconSessions,
    required this.metconMovements,
    required this.cardioSessions,
    required this.routes,
    required this.platforms,
    required this.platformCredentials,
    required this.actionProviders,
    required this.actions,
    required this.actionRules,
    required this.actionEvents,
    required this.epochMap,
  });

  factory AccountData.fromJson(Map<String, dynamic> json) =>
      _$AccountDataFromJson(json);

  User? user; // only send if updated
  List<Diary> diaries;
  List<Wod> wods;
  List<Movement> movements;
  List<StrengthSession> strengthSessions;
  List<StrengthSet> strengthSets;
  List<Metcon> metcons;
  List<MetconSession> metconSessions;
  List<MetconMovement> metconMovements;
  List<CardioSession> cardioSessions;
  List<Route> routes;
  List<Platform> platforms;
  List<PlatformCredential> platformCredentials;
  List<ActionProvider> actionProviders;
  List<Action> actions;
  List<ActionRule> actionRules;
  List<ActionEvent> actionEvents;
  EpochMap epochMap;

  Map<String, dynamic> toJson() => _$AccountDataToJson(this);
}
