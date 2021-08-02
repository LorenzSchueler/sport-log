
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/models/metcon.dart';
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

class MetconRequestGet extends MetconRequestEvent {
  const MetconRequestGet(this.id) : super();

  final int id;
}

class MetconRequestCreate extends MetconRequestEvent {
  const MetconRequestCreate(this.newMetcon) : super();

  final NewMetcon newMetcon;
}

class MetconRequestDelete extends MetconRequestEvent {
  const MetconRequestDelete(this.id) : super();

  final int id;
}

class MetconRequestUpdate extends MetconRequestEvent {
  const MetconRequestUpdate(this.metcon) : super();

  final Metcon metcon;
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

  final MetconRepository _metconRepository;
  final MetconsCubit _metconsCubit;

  @override
  Stream<MetconRequestState> mapEventToState(MetconRequestEvent event) async* {
    if (event is MetconRequestGet) {
      yield* _getMetcon(event);
    } else if (event is MetconRequestCreate) {
      yield* _createMetcon(event);
    } else if (event is MetconRequestDelete) {
      yield* _deleteMetcon(event);
    } else if (event is MetconRequestUpdate) {
      yield* _updateMetcon(event);
    } else if (event is MetconRequestGetAll) {
      yield* _getAllMetcons(event);
    }
  }

  Stream<MetconRequestState> _getMetcon(MetconRequestGet event) async* {
    yield const MetconRequestPending();
    final metcon = _metconRepository.getMetcon(event.id);
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    // TODO: use real api
    if (metcon == null) {
      yield const MetconRequestFailed(ApiError.notFound);
    } else {
      _metconsCubit.addMetconIfNotExists(metcon);
      yield const MetconRequestSucceeded();
    }
  }

  Stream<MetconRequestState> _createMetcon(MetconRequestCreate event) async* {
    yield const MetconRequestPending();
    final metcon = _metconRepository.createMetcon(event.newMetcon);
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    // TODO: use real api
    _metconsCubit.addMetcon(metcon);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _deleteMetcon(MetconRequestDelete event) async* {
    yield const MetconRequestPending();
    _metconRepository.deleteMetcon(event.id);
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    // TODO: use real api
    _metconsCubit.deleteMetcon(event.id);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _updateMetcon(MetconRequestUpdate event) async* {
    yield const MetconRequestPending();
    _metconRepository.updateMetcon(event.metcon);
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    // TODO: use real api
    _metconsCubit.editMetcon(event.metcon);
    yield const MetconRequestSucceeded();
  }

  Stream<MetconRequestState> _getAllMetcons(MetconRequestGetAll event) async* {
    yield const MetconRequestPending();
    await Future.delayed(Duration(milliseconds: Config.debugApiDelay));
    // TODO: use real api
    final allMetcons = _metconRepository.getAllMetcons();
    _metconsCubit.loadMetcons(allMetcons);
    yield const MetconRequestSucceeded();
  }
}