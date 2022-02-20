import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';

class TimelineUnion extends Comparable<TimelineUnion> {
  final StrengthSessionWithStats? _strengthSessionWithStats;
  final MetconSessionDescription? _metconSessionDescription;
  final CardioSessionDescription? _cardioSessionDescription;
  final Diary? _diary;

  TimelineUnion.strengthSession(
      StrengthSessionWithStats this._strengthSessionWithStats)
      : _metconSessionDescription = null,
        _cardioSessionDescription = null,
        _diary = null;
  TimelineUnion.metconSession(
      MetconSessionDescription this._metconSessionDescription)
      : _strengthSessionWithStats = null,
        _cardioSessionDescription = null,
        _diary = null;
  TimelineUnion.cardioSession(
      CardioSessionDescription this._cardioSessionDescription)
      : _strengthSessionWithStats = null,
        _metconSessionDescription = null,
        _diary = null;
  TimelineUnion.diary(Diary this._diary)
      : _strengthSessionWithStats = null,
        _metconSessionDescription = null,
        _cardioSessionDescription = null;

  DateTime get datetime {
    if (_strengthSessionWithStats != null) {
      return _strengthSessionWithStats!.session.datetime;
    } else if (_metconSessionDescription != null) {
      return _metconSessionDescription!.metconSession.datetime;
    } else if (_cardioSessionDescription != null) {
      return _cardioSessionDescription!.cardioSession.datetime;
    } else {
      return _diary!.date;
    }
  }

  T map<T>(
    T Function(StrengthSessionWithStats) strengthFunction,
    T Function(MetconSessionDescription) metconFunction,
    T Function(CardioSessionDescription) cardioFunction,
    T Function(Diary) diaryFunction,
  ) {
    if (_strengthSessionWithStats != null) {
      return strengthFunction(_strengthSessionWithStats!);
    } else if (_metconSessionDescription != null) {
      return metconFunction(_metconSessionDescription!);
    } else if (_cardioSessionDescription != null) {
      return cardioFunction(_cardioSessionDescription!);
    } else {
      return diaryFunction(_diary!);
    }
  }

  @override
  int compareTo(TimelineUnion other) {
    return datetime.compareTo(other.datetime);
  }
}
