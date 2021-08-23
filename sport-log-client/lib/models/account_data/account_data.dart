
import 'package:json_annotation/json_annotation.dart';
import '../all.dart';

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
  });

  User? user;
  List<Diary> diaries;
  List<Wod> wods;
  List<Movement> movements;
  List<StrengthSession> strengthSessions;
  @JsonKey(name: 'strength_set') // FIXME
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

  factory AccountData.fromJson(Map<String, dynamic> json) => _$AccountDataFromJson(json);
  Map<String, dynamic> toJson() => _$AccountDataToJson(this);
}
