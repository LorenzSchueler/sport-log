import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'epoch_map.g.dart';

@JsonSerializable()
class EpochMap {
  EpochMap({
    required this.user,
    required this.diary,
    required this.wod,
    required this.movement,
    required this.strengthSession,
    required this.strengthSet,
    required this.metcon,
    required this.metconSession,
    required this.metconMovement,
    required this.cardioSession,
    required this.route,
    required this.platform,
    required this.platformCredential,
    required this.actionProvider,
    required this.action,
    required this.actionRule,
    required this.actionEvent,
  }) : lastSync = DateTime.fromMillisecondsSinceEpoch(0);

  EpochMap.zero()
    : user = Int64.ZERO,
      diary = Int64.ZERO,
      wod = Int64.ZERO,
      movement = Int64.ZERO,
      strengthSession = Int64.ZERO,
      strengthSet = Int64.ZERO,
      metcon = Int64.ZERO,
      metconSession = Int64.ZERO,
      metconMovement = Int64.ZERO,
      cardioSession = Int64.ZERO,
      route = Int64.ZERO,
      platform = Int64.ZERO,
      platformCredential = Int64.ZERO,
      actionProvider = Int64.ZERO,
      action = Int64.ZERO,
      actionRule = Int64.ZERO,
      actionEvent = Int64.ZERO,
      lastSync = DateTime.fromMillisecondsSinceEpoch(0);

  factory EpochMap.fromJson(Map<String, dynamic> json) =>
      _$EpochMapFromJson(json);

  @IdConverter()
  Int64 user;
  @IdConverter()
  Int64 diary;
  @IdConverter()
  Int64 wod;
  @IdConverter()
  Int64 movement;
  @IdConverter()
  Int64 strengthSession;
  @IdConverter()
  Int64 strengthSet;
  @IdConverter()
  Int64 metcon;
  @IdConverter()
  Int64 metconSession;
  @IdConverter()
  Int64 metconMovement;
  @IdConverter()
  Int64 cardioSession;
  @IdConverter()
  Int64 route;
  @IdConverter()
  Int64 platform;
  @IdConverter()
  Int64 platformCredential;
  @IdConverter()
  Int64 actionProvider;
  @IdConverter()
  Int64 action;
  @IdConverter()
  Int64 actionRule;
  @IdConverter()
  Int64 actionEvent;
  // set in Settings on every update
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime lastSync;

  Map<String, dynamic> toJson() => _$EpochMapToJson(this);
}
