
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/models/movement.dart';

abstract class MovementsState {}

class MovementsInitial extends MovementsState {}

class MovementsLoaded extends MovementsState {
  MovementsLoaded(Map<int, Movement> movements)
    : _movements = movements, super();

  MovementsLoaded.fromList(List<Movement> movements)
    : _movements = {}, super() {
    for (final movement in movements) {
      _movements[movement.id] = movement;
    }
  }

  final Map<int, Movement> _movements;

  Map<int, Movement> get movementsMap => _movements;
  List<Movement> get movementsList => _movements.values.toList();
}


class MovementsCubit extends Cubit<MovementsState> {
  MovementsCubit() : super(MovementsInitial());

  void loadMovements(List<Movement> movements) {
    emit(MovementsLoaded.fromList(movements));
  }

  void addMovement(Movement movement) {
    if (state is MovementsLoaded) {
      final movements = (state as MovementsLoaded).movementsMap;
      if (!movements.containsKey(movement.id)) {
        movements[movement.id] = movement;
        emit(MovementsLoaded(movements));
      } else {
        addError(Exception("Adding a movement that already exists."));
      }
    } else {
      addError(Exception("Adding a movement when movements are not yet loaded."));
    }
  }

  void deleteMovement(int id) {
    if (state is MovementsLoaded) {
      final movements = (state as MovementsLoaded).movementsMap;
      if (movements.containsKey(id)) {
        movements.remove(id);
        emit(MovementsLoaded(movements));
      } else {
        addError(Exception("Deleting movement that does not exist."));
      }
    } else {
      addError(Exception("Deleting movement when movements are not yet loaded."));
    }
  }

  void updateMovement(Movement movement) {
    if (state is MovementsLoaded) {
      final movements = (state as MovementsLoaded).movementsMap;
      if (movements.containsKey(movement.id)) {
        movements[movement.id] = movement;
        emit(MovementsLoaded(movements));
      } else {
        addError(Exception("Updating movement that does not exist."));
      }
    } else {
      addError(Exception("Updating movement when movements are not yet loaded."));
    }
  }
}