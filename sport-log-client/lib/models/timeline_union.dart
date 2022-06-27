import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';
import 'package:sport_log/models/strength/strength_records.dart';

class TimelineUnion extends Comparable<TimelineUnion> {
  TimelineUnion.strengthSession(
    StrengthSessionDescription this._strengthSessionDescription,
  )   : _metconSessionDescription = null,
        _cardioSessionDescription = null,
        _diary = null;

  TimelineUnion.metconSession(
    MetconSessionDescription this._metconSessionDescription,
  )   : _strengthSessionDescription = null,
        _cardioSessionDescription = null,
        _diary = null;

  TimelineUnion.cardioSession(
    CardioSessionDescription this._cardioSessionDescription,
  )   : _strengthSessionDescription = null,
        _metconSessionDescription = null,
        _diary = null;

  TimelineUnion.diary(Diary this._diary)
      : _strengthSessionDescription = null,
        _metconSessionDescription = null,
        _cardioSessionDescription = null;

  final StrengthSessionDescription? _strengthSessionDescription;
  final MetconSessionDescription? _metconSessionDescription;
  final CardioSessionDescription? _cardioSessionDescription;
  final Diary? _diary;

  DateTime get datetime {
    if (_strengthSessionDescription != null) {
      return _strengthSessionDescription!.session.datetime;
    } else if (_metconSessionDescription != null) {
      return _metconSessionDescription!.metconSession.datetime;
    } else if (_cardioSessionDescription != null) {
      return _cardioSessionDescription!.cardioSession.datetime;
    } else {
      return _diary!.date;
    }
  }

  T map<T>(
    T Function(StrengthSessionDescription) strengthFunction,
    T Function(MetconSessionDescription) metconFunction,
    T Function(CardioSessionDescription) cardioFunction,
    T Function(Diary) diaryFunction,
  ) {
    if (_strengthSessionDescription != null) {
      return strengthFunction(_strengthSessionDescription!);
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

class TimelineRecords {
  TimelineRecords(this.strengthRecords, this.metconRecords);

  final StrengthRecords strengthRecords;
  final MetconRecords metconRecords;
}
