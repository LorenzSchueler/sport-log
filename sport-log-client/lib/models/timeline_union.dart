import 'package:sport_log/models/all.dart';

class TimelineUnion extends Comparable<TimelineUnion> {
  final StrengthSessionWithStats? _strengthSession;
  final MetconSession? _metconSession;
  final CardioSession? _cardioSession;
  final Diary? _diary;

  TimelineUnion.strengthSession(StrengthSessionWithStats this._strengthSession)
      : _metconSession = null,
        _cardioSession = null,
        _diary = null;
  TimelineUnion.metconSession(MetconSession this._metconSession)
      : _strengthSession = null,
        _cardioSession = null,
        _diary = null;
  TimelineUnion.cardioSession(CardioSession this._cardioSession)
      : _strengthSession = null,
        _metconSession = null,
        _diary = null;
  TimelineUnion.diary(Diary this._diary)
      : _strengthSession = null,
        _metconSession = null,
        _cardioSession = null;

  DateTime get datetime {
    if (_strengthSession != null) {
      return _strengthSession!.session.datetime;
    } else if (_metconSession != null) {
      return _metconSession!.datetime;
    } else if (_cardioSession != null) {
      return _cardioSession!.datetime;
    } else {
      return _diary!.date;
    }
  }

  T map<T>(
    T Function(StrengthSessionWithStats) strengthFunction,
    T Function(MetconSession) metconFunction,
    T Function(CardioSession) cardioFunction,
    T Function(Diary) diaryFunction,
  ) {
    if (_strengthSession != null) {
      return strengthFunction(_strengthSession!);
    } else if (_metconSession != null) {
      return metconFunction(_metconSession!);
    } else if (_cardioSession != null) {
      return cardioFunction(_cardioSession!);
    } else {
      return diaryFunction(_diary!);
    }
  }

  @override
  int compareTo(TimelineUnion other) {
    return datetime.compareTo(other.datetime);
  }
}
