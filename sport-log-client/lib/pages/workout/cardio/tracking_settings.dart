import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/cardio/audio_feedback_config.dart';

class TrackingSettings extends ChangeNotifier {
  factory TrackingSettings() {
    final settings = TrackingSettings._();
    settings.heartRateUtils.addListener(settings.notifyListeners);
    return settings;
  }

  TrackingSettings._();

  Movement _movement = Movement.defaultMovement!;
  Movement get movement => _movement;
  set movement(Movement movement) {
    _movement = movement;
    notifyListeners();
  }

  CardioType _cardioType = CardioType.training;
  CardioType get cardioType => _cardioType;
  set cardioType(CardioType cardioType) {
    _cardioType = cardioType;
    notifyListeners();
  }

  Route? _route;
  Route? get route => _route;
  set route(Route? route) {
    _route = route;
    notifyListeners();
  }

  int? _routeAlarmDistance;
  int? get routeAlarmDistance => _routeAlarmDistance;
  set routeAlarmDistance(int? routeAlarmDistance) {
    _routeAlarmDistance = routeAlarmDistance;
    notifyListeners();
  }

  AudioFeedbackConfig? _audioFeedback;
  AudioFeedbackConfig? get audioFeedback => _audioFeedback;
  set audioFeedback(AudioFeedbackConfig? audioFeedback) {
    _audioFeedback = audioFeedback;
    _audioFeedback?.addListener(notifyListeners);
    notifyListeners();
  }

  final HeartRateUtils _heartRateUtils = HeartRateUtils();
  HeartRateUtils get heartRateUtils => _heartRateUtils;
}
