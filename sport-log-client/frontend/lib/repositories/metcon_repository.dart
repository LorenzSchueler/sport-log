
import 'package:sport_log/models/metcon.dart';

class MetconRepository {
  final Map<int, Metcon> _metcons = {};

  int get _nextId => _metcons.length;
  int get _nextMovementId => _metcons.values.toList().fold(0,
          (int number, m) => number + m.moves.length);

  Metcon createMetcon(NewMetcon newMetcon) {
    final mms = newMetcon.moves.map((nmm) =>
        MetconMovement.fromNewMetconMovement(nmm, _nextMovementId)).toList();
    final id = _nextId;
    final metcon = Metcon.fromNewMetconWithMoves(newMetcon, id, mms);
    _metcons[id] = metcon;
    return metcon;
  }

  void deleteMetcon(int id) {
    _metcons.remove(id);
  }

  Metcon? getMetcon(int id) {
    if (!_metcons.containsKey(id)) {
      return null;
    }
    return _metcons[id];
  }

  List<Metcon> getAllMetcons() {
    return _metcons.values.toList();
  }

  void updateMetcon(Metcon metcon) {
    if (_metcons.containsKey(metcon.id)) {
      _metcons[metcon.id] = metcon;
    }
  }
}