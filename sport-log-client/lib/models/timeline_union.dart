import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/metcon/metcon_records.dart';
import 'package:sport_log/models/strength/strength_records.dart';

class TimelineUnion {
  TimelineUnion.strengthSession(
    StrengthSessionDescription this._strengthSessionDescription,
  ) : _metconSessionDescription = null,
      _cardioSessionDescription = null,
      _wod = null,
      _diary = null;

  TimelineUnion.metconSession(
    MetconSessionDescription this._metconSessionDescription,
  ) : _strengthSessionDescription = null,
      _cardioSessionDescription = null,
      _wod = null,
      _diary = null;

  TimelineUnion.cardioSession(
    CardioSessionDescription this._cardioSessionDescription,
  ) : _strengthSessionDescription = null,
      _metconSessionDescription = null,
      _wod = null,
      _diary = null;

  TimelineUnion.wod(Wod this._wod)
    : _strengthSessionDescription = null,
      _metconSessionDescription = null,
      _cardioSessionDescription = null,
      _diary = null;
  TimelineUnion.diary(Diary this._diary)
    : _strengthSessionDescription = null,
      _metconSessionDescription = null,
      _cardioSessionDescription = null,
      _wod = null;

  final StrengthSessionDescription? _strengthSessionDescription;
  final MetconSessionDescription? _metconSessionDescription;
  final CardioSessionDescription? _cardioSessionDescription;
  final Wod? _wod;
  final Diary? _diary;

  DateTime get datetime {
    if (_strengthSessionDescription != null) {
      return _strengthSessionDescription.session.datetime;
    } else if (_metconSessionDescription != null) {
      return _metconSessionDescription.metconSession.datetime;
    } else if (_cardioSessionDescription != null) {
      return _cardioSessionDescription.cardioSession.datetime;
    } else if (_wod != null) {
      return _wod.date;
    } else {
      return _diary!.date;
    }
  }

  T map<T>(
    T Function(StrengthSessionDescription) strengthFunction,
    T Function(MetconSessionDescription) metconFunction,
    T Function(CardioSessionDescription) cardioFunction,
    T Function(Wod) wodFunction,
    T Function(Diary) diaryFunction,
  ) {
    if (_strengthSessionDescription != null) {
      return strengthFunction(_strengthSessionDescription);
    } else if (_metconSessionDescription != null) {
      return metconFunction(_metconSessionDescription);
    } else if (_cardioSessionDescription != null) {
      return cardioFunction(_cardioSessionDescription);
    } else if (_wod != null) {
      return wodFunction(_wod);
    } else {
      return diaryFunction(_diary!);
    }
  }
}

class TimelineRecords {
  TimelineRecords(this.strengthRecords, this.metconRecords);

  final StrengthRecords strengthRecords;
  final MetconRecords metconRecords;
}

class MovementOrMetcon {
  MovementOrMetcon.movement(Movement this.movement) : metcon = null;
  MovementOrMetcon.metcon(Metcon this.metcon) : movement = null;

  final Movement? movement;
  final Metcon? metcon;

  bool get isMovement => movement != null;
  bool get isMetcon => metcon != null;

  String get name => movement?.name ?? metcon!.name;

  @override
  bool operator ==(Object other) =>
      other is MovementOrMetcon &&
      isMovement == other.isMovement &&
      movement?.id == other.movement?.id &&
      metcon?.id == other.metcon?.id;

  @override
  int get hashCode =>
      Object.hash(runtimeType, isMovement, movement?.id, metcon?.id);
}
