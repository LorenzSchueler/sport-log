
import 'package:sport_log/models/metcon.dart';

class MetconRepository {
  final Map<int, Metcon> _metcons = {};
  final Map<int, MetconMovement> _metconMovements = {};

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

  void deleteMetcon(int id) {
    assert(_metcons.containsKey(id));
    _metcons.remove(id);
    _metconMovements.removeWhere((id, mm) => mm.metconId == id);
  }

  void updateMetcon(Metcon m) {
    assert(_metcons.containsKey(m.id));
    _metcons[m.id] = m;
  }

  int get nextMetconId => _metcons.length;
  int get nextMetconMovementId => _metconMovements.length;
}