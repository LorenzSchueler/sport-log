
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/models/metcon.dart';
import 'package:sport_log/pages/workout/metcon/metcons_cubit.dart';
import 'package:sport_log/repositories/metcon_repository.dart';
import 'package:sport_log/helpers/iterable_extension.dart';

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

  final int id;
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
  MetconRequestBloc({
    required MetconRepository metconRepository,
    required MetconsCubit metconsCubit,
  }) : _metconRepository = metconRepository,
       _metconsCubit = metconsCubit,
       super(const MetconRequestIdle());

  MetconRequestBloc.fromContext(BuildContext context)
    : _metconRepository = context.read<MetconRepository>(),
      _metconsCubit = context.read<MetconsCubit>(),
      _api = context.read<Api>(),
      super(const MetconRequestIdle());

  final MetconRepository _metconRepository;
  final MetconsCubit _metconsCubit;
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
    int userId = _api.getCredentials()!.userId;
    event.newMetcon.userId = userId;
    event.newMetcon.id = _metconRepository.nextMetconId;
    final metcon = event.newMetcon.toMetcon();
    final metconMovements = event.newMetcon.moves.mapIndexed((index, mm) {
      assert(mm.id == null);
      mm.id = _metconRepository.nextMetconMovementId;
      return mm.toMetconMovement(metcon, index);
    }).toList();
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    _metconRepository.addMetcon(metcon);
    _metconRepository.addMetconMovements(metconMovements);
    _metconsCubit.addMetcon(event.newMetcon);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _deleteMetcon(MetconRequestDelete event) async* {
    yield const MetconRequestPending();
    _metconRepository.deleteMetcon(event.id);
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    _metconsCubit.deleteMetcon(event.id);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _updateMetcon(MetconRequestUpdate event) async* {
    yield const MetconRequestPending();
    assert(event.metcon.userId != null);
    assert(event.metcon.id != null);
    final metcon = event.metcon.toMetcon();
    final metconMovements = event.metcon.moves.mapIndexed((index, mm) {
      mm.id ??= _metconRepository.nextMetconMovementId;
      return mm.toMetconMovement(metcon, index);
    }).toList();
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    _metconRepository.updateMetcon(metcon);
    _metconRepository.updateOrAddMetconMovements(metconMovements);
    _metconsCubit.updateMetcon(event.metcon);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _getAllMetcons(MetconRequestGetAll event) async* {
    yield const MetconRequestPending();
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    final uiMetcons = _metconRepository.getMetcons().map((metcon) {
      final movements = _metconRepository.getMetconMovementsOfMetcon(metcon)
        .map((movement) => UiMetconMovement.fromMetconMovement(movement))
        .toList();
      return UiMetcon.fromMetcon(metcon, movements);
    });
    _metconsCubit.loadMetcons(uiMetcons);
    yield const MetconRequestSucceeded();
  }
}