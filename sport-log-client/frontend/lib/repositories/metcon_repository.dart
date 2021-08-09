
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/metcon/metcon_movement.dart';

class MetconRepository {
  final Map<Int64, Metcon> _metcons = {};
  final Map<Int64, MetconMovement> _metconMovements = {};

  List<MetconMovement> getMetconMovementsOfMetcon(Metcon metcon) {
    return _metconMovements.values.where((mm) => mm.metconId == metcon.id)
      .toList();
  }

  void addMetconMovement(MetconMovement mm) {
    assert(!_metconMovements.containsKey(mm.id));
    _metconMovements[mm.id] = mm;
  }

  void addMetconMovements(List<MetconMovement> mms) {
    for (final mm in mms) {
      addMetconMovement(mm);
    }
  }

  void updateOrAddMetconMovement(MetconMovement mm) {
    _metconMovements[mm.id] = mm;
  }

  void updateOrAddMetconMovements(List<MetconMovement> mms) {
    for (final mm in mms) {
      updateOrAddMetconMovement(mm);
    }
  }

  List<Metcon> getMetcons() {
    return _metcons.values.toList();
  }

  void addMetcon(Metcon m) {
    assert(!_metcons.containsKey(m.id));
    _metcons[m.id] = m;
  }

  void deleteMetcon(Int64 id) {
    assert(_metcons.containsKey(id));
    _metcons.remove(id);
    _metconMovements.removeWhere((id, mm) => mm.metconId == id);
  }

  void updateMetcon(Metcon m) {
    assert(_metcons.containsKey(m.id));
    _metcons[m.id] = m;
  }

  static Int64 _nextMetconId = Int64(0);
  Int64 get nextMetconId => _nextMetconId++;

  static Int64 _nextMetconMovementId = Int64(0);
  Int64 get nextMetconMovementId => _nextMetconMovementId++;
}