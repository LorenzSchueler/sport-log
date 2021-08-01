
import 'package:sport_log/models/movement.dart';

class MovementRepository {

  final Map<int, Movement> _movements = {};
  
  int get _nextId => _movements.length;

  int createMovement(NewMovement movement) {
    final id = _nextId;
    _movements[id] = Movement.fromNewMovement(movement, id);
    return id;
  }

  void deleteMovement(int id) {
    _movements.remove(id);
  }

  Movement? getMovement(int id) {
    if (!_movements.containsKey(id)) {
      return null;
    }
    return _movements[id];
  }

  List<Movement> getAllMovements() {
    return _movements.values.toList();
  }

  List<Movement> searchByName(String search) {
    if (search.isEmpty) {
      return getAllMovements();
    }
    final s = search.toLowerCase();
    return _movements.values.where((m) =>
        m.name.toLowerCase().contains(s)).toList();
  }
}