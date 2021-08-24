import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/movement/ui_movement.dart';
import 'package:sport_log/pages/movements/movements_cubit.dart';
import 'package:sport_log/repositories/movement_repository.dart';

/// Bloc State
abstract class MovementRequestState {}

class MovementRequestIdle extends MovementRequestState {}

class MovementRequestPending extends MovementRequestState {}

class MovementRequestFailed extends MovementRequestState {
  MovementRequestFailed(this.reason) : super();

  final ApiError reason;
}

class MovementRequestSucceeded extends MovementRequestState {
  MovementRequestSucceeded({this.payload});

  dynamic payload;
}

/// Bloc Event
abstract class MovementRequestEvent {}

class MovementRequestCreate extends MovementRequestEvent {
  MovementRequestCreate(this.newMovement) : super();

  final UiMovement newMovement;
}

class MovementRequestDelete extends MovementRequestEvent {
  MovementRequestDelete(this.id) : super();

  final Int64 id;
}

class MovementRequestUpdate extends MovementRequestEvent {
  MovementRequestUpdate(this.movement) : super();

  final UiMovement movement;
}

class MovementRequestGetAll extends MovementRequestEvent {}

/// Bloc
class MovementRequestBloc
    extends Bloc<MovementRequestEvent, MovementRequestState> {
  MovementRequestBloc.fromContext(BuildContext context)
      : _repo = context.read<MovementRepository>(),
        _cubit = context.read<MovementsCubit>(),
        super(MovementRequestIdle());

  final MovementRepository _repo;
  final MovementsCubit _cubit;

  @override
  Stream<MovementRequestState> mapEventToState(
      MovementRequestEvent event) async* {
    if (event is MovementRequestCreate) {
      yield* _createMovement(event);
    } else if (event is MovementRequestDelete) {
      yield* _deleteMovement(event);
    } else if (event is MovementRequestUpdate) {
      yield* _updateMovement(event);
    } else if (event is MovementRequestGetAll) {
      yield* _getAllMovements(event);
    }
  }

  Stream<MovementRequestState> _createMovement(
      MovementRequestCreate event) async* {
    yield MovementRequestPending();
    assert(event.newMovement.id == null);
    final Movement movement = Movement(
      id: _repo.nextMovementId,
      userId: Api.instance.currentUser!.id,
      name: event.newMovement.name,
      category: event.newMovement.category,
      description: event.newMovement.description,
      deleted: false,
    );
    await Future<void>.delayed(Duration(milliseconds: Config.debugApiDelay));
    _repo.addMovement(movement);
    _cubit.addMovement(movement);
    yield MovementRequestSucceeded(payload: movement.id);
  }

  Stream<MovementRequestState> _deleteMovement(
      MovementRequestDelete event) async* {
    yield MovementRequestPending();
    await Future<void>.delayed(Duration(milliseconds: Config.debugApiDelay));
    _repo.deleteMovement(event.id);
    _cubit.deleteMovement(event.id);
    yield MovementRequestSucceeded(payload: event.id);
  }

  Stream<MovementRequestState> _updateMovement(
      MovementRequestUpdate event) async* {
    yield MovementRequestPending();
    assert(event.movement.id != null);
    assert(event.movement.userId != null);
    assert(event.movement.userId == Api.instance.currentUser!.id);
    await Future<void>.delayed(Duration(milliseconds: Config.debugApiDelay));
    final movement = Movement(
      id: event.movement.id!,
      userId: event.movement.userId,
      name: event.movement.name,
      category: event.movement.category,
      description: event.movement.description,
      deleted: false,
    );
    _repo.updateMovement(movement);
    _cubit.updateMovement(movement);
    yield MovementRequestSucceeded(payload: movement.id);
  }

  Stream<MovementRequestState> _getAllMovements(
      MovementRequestGetAll event) async* {
    yield MovementRequestPending();
    await Future<void>.delayed(Duration(milliseconds: Config.debugApiDelay));
    final movements = _repo.getAllMovements();
    _cubit.loadMovements(movements);
    yield MovementRequestSucceeded();
  }
}
