
import 'package:sport_log/models/metcon.dart';

class MetconRepository {
  final Map<int, Metcon> _metcons = {};
  final Map<int, MetconMovement> _metconMovements = {};

  MetconMovement? getMetconMovement(int id) {
    assert(_metconMovements.containsKey(id));
    return _metconMovements[id];
  }

  void addMetconMovement(MetconMovement mm) {
    assert(!_metconMovements.containsKey(mm.id));
    _metconMovements[mm.id] = mm;
  }

  void deleteMetconMovement(int id) {
    assert(_metconMovements.containsKey(id));
    _metconMovements.remove(id);
  }

  void updateMetconMovement(MetconMovement mm) {
    assert(_metconMovements.containsKey(mm.id));
    _metconMovements[mm.id] = mm;
  }

  Metcon? getMetcon(int id) {
    assert(_metcons.containsKey(id));
    return _metcons[id];
  }

  void addMetcon(Metcon m) {
    assert(!_metcons.containsKey(m.id));
    _metcons[m.id] = m;
  }

  void deleteMetcon(int id) {
    assert(_metcons.containsKey(id));
    _metcons.remove(id);
  }

  void updateMetcon(Metcon m) {
    assert(_metcons.containsKey(m.id));
    _metcons[m.id] = m;
  }
}