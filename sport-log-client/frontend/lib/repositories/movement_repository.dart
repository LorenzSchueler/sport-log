
import 'package:sport_log/models/movement.dart';

class MovementRepository {

  final Map<int, Movement> _movements = {};
  
  int get _nextId => _movements.length;

  void createMovement(NewMovement movement) {
    _movements[_nextId] = Movement.fromNewMovement(movement, _nextId);
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
}