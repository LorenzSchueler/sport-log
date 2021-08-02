
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/models/metcon.dart';

abstract class MetconsState {
  const MetconsState();
}

class MetconsInitial extends MetconsState {
  const MetconsInitial() : super();
}

class MetconsLoaded extends MetconsState {
  MetconsLoaded(Map<int, Metcon> metcons)
    : _metcons = metcons, super();

  MetconsLoaded.fromList(List<Metcon> metcons)
    : _metcons = { for (var m in metcons) m.id : m }, super();

  final Map<int, Metcon> _metcons;

  Map<int, Metcon> get metcons => _metcons;

  Metcon? getMetcon(int id) => _metcons[id];
}

class MetconsCubit extends Cubit<MetconsState> {
  MetconsCubit() : super(const MetconsInitial());

  void loadMetcons(List<Metcon> metcons) {
    emit(MetconsLoaded.fromList(metcons));
  }

  void addMetcon(Metcon metcon) {
    if (state is MetconsLoaded) {
      final metcons = (state as MetconsLoaded).metcons;
      if (!metcons.containsKey(metcon.id)) {
        metcons[metcon.id] = metcon;
        emit(MetconsLoaded(metcons));
      } else {
        addError(Exception("Adding metcon that already exists."));
      }
    } else {
      addError(Exception("Adding metcon when metcons are not yet loaded."));
    }
  }

  void addMetconIfNotExists(Metcon metcon) {
    if (state is MetconsLoaded) {
      final metcons = (state as MetconsLoaded).metcons;
      if (!metcons.containsKey(metcon.id)) {
        metcons[metcon.id] = metcon;
        emit(MetconsLoaded(metcons));
      }
    } else {
      addError(Exception("Adding metcon when metcons are not yet loaded."));
    }
  }

  void deleteMetcon(int id) {
    if (state is MetconsLoaded) {
      final metcons = (state as MetconsLoaded).metcons;
      if (metcons.containsKey(id)) {
        metcons.remove(id);
        emit(MetconsLoaded(metcons));
      } else {
        addError(Exception("Deleting metcons that does not exist."));
      }
    } else {
      addError(Exception("Deleting metcon when metcons are not yet loaded."));
    }
  }

  void editMetcon(Metcon metcon) {
    if (state is MetconsLoaded) {
      final metcons = (state as MetconsLoaded).metcons;
      if (metcons.containsKey(metcon.id)) {
        metcons[metcon.id] = metcon;
        emit(MetconsLoaded(metcons));
      } else {
        addError(Exception("Editing metcon that does not exist."));
      }
    } else {
      addError(Exception("Editing metcon when metcons are not yet loaded."));
    }
  }
}