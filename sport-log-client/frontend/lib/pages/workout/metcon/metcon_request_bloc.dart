
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/iterable_extension.dart';
import 'package:sport_log/models/metcon/ui_metcon.dart';
import 'package:sport_log/pages/workout/metcon/metcons_cubit.dart';
import 'package:sport_log/repositories/metcon_repository.dart';

/// Bloc State
abstract class MetconRequestState {
  const MetconRequestState();
}

class MetconRequestIdle extends MetconRequestState {
  const MetconRequestIdle() : super();
}

class MetconRequestFailed extends MetconRequestState {
  const MetconRequestFailed(this.reason) : super();

  final ApiError reason;
}

class MetconRequestPending extends MetconRequestState {
  const MetconRequestPending() : super();
}

class MetconRequestSucceeded extends MetconRequestState {
  const MetconRequestSucceeded() : super();
}

/// Bloc Event
abstract class MetconRequestEvent {
  const MetconRequestEvent();
}

class MetconRequestCreate extends MetconRequestEvent {
  const MetconRequestCreate(this.newMetcon) : super();

  final UiMetcon newMetcon;
}

class MetconRequestDelete extends MetconRequestEvent {
  const MetconRequestDelete(this.id) : super();

  final Int64 id;
}

class MetconRequestUpdate extends MetconRequestEvent {
  const MetconRequestUpdate(this.metcon) : super();

  final UiMetcon metcon;
}

class MetconRequestGetAll extends MetconRequestEvent {
  const MetconRequestGetAll() : super();
}

/// Actual Bloc
class MetconRequestBloc extends Bloc<MetconRequestEvent, MetconRequestState> {
  MetconRequestBloc.fromContext(BuildContext context)
    : _repo = context.read<MetconRepository>(),
      _cubit = context.read<MetconsCubit>(),
      _api = Api.instance,
      super(const MetconRequestIdle());

  final MetconRepository _repo;
  final MetconsCubit _cubit;
  final Api _api;

  @override
  Stream<MetconRequestState> mapEventToState(MetconRequestEvent event) async* {
    if (event is MetconRequestCreate) {
      yield* _createMetcon(event);
    } else if (event is MetconRequestDelete) {
      yield* _deleteMetcon(event);
    } else if (event is MetconRequestUpdate) {
      yield* _updateMetcon(event);
    } else if (event is MetconRequestGetAll) {
      yield* _getAllMetcons(event);
    }
  }

  Stream<MetconRequestState> _createMetcon(MetconRequestCreate event) async* {
    yield const MetconRequestPending();
    assert(event.newMetcon.id == null);
    Int64 userId = _api.currentUser!.id;
    event.newMetcon.userId = userId;
    event.newMetcon.id = _repo.nextMetconId;
    final metcon = event.newMetcon.toMetcon();
    final metconMovements = event.newMetcon.moves.mapIndexed((index, mm) {
      assert(mm.id == null);
      mm.id = _repo.nextMetconMovementId;
      return mm.toMetconMovement(metcon, index);
    }).toList();
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    _repo.addMetcon(metcon);
    _repo.addMetconMovements(metconMovements);
    _cubit.addMetcon(event.newMetcon);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _deleteMetcon(MetconRequestDelete event) async* {
    yield const MetconRequestPending();
    _repo.deleteMetcon(event.id);
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    _cubit.deleteMetcon(event.id);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _updateMetcon(MetconRequestUpdate event) async* {
    yield const MetconRequestPending();
    assert(event.metcon.userId != null);
    assert(event.metcon.id != null);
    final metcon = event.metcon.toMetcon();
    final metconMovements = event.metcon.moves.mapIndexed((index, mm) {
      mm.id ??= _repo.nextMetconMovementId;
      return mm.toMetconMovement(metcon, index);
    }).toList();
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    _repo.updateMetcon(metcon);
    _repo.updateOrAddMetconMovements(metconMovements);
    _cubit.updateMetcon(event.metcon);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _getAllMetcons(MetconRequestGetAll event) async* {
    yield const MetconRequestPending();
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    final uiMetcons = _repo.getMetcons().map((metcon) {
      final movements = _repo.getMetconMovementsOfMetcon(metcon)
        .map((movement) => UiMetconMovement.fromMetconMovement(movement))
        .toList();
      return UiMetcon.fromMetcon(metcon, movements);
    }).toList();
    _cubit.loadMetcons(uiMetcons);
    yield const MetconRequestSucceeded();
  }
}