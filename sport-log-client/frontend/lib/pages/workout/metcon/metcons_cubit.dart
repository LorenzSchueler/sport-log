
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/models/metcon.dart';

abstract class MetconsState {
  const MetconsState();
}

class MetconsInitial extends MetconsState {
  const MetconsInitial() : super();
}

class MetconsLoaded extends MetconsState {
  MetconsLoaded(Map<int, UiMetcon> metcons)
    : _metcons = metcons, super();

  MetconsLoaded.fromList(List<UiMetcon> metcons)
    : _metcons = {}, super() {
    for (final metcon in metcons) {
      assert(metcon.id != null);
      if (metcon.id != null) {
        _metcons[metcon.id!] = metcon;
      }
    }
  }

  final Map<int, UiMetcon> _metcons;

  Map<int, UiMetcon> get metconsMap => _metcons;
  List<UiMetcon> get metconsList => _metcons.values.toList();

  UiMetcon? getMetcon(int id) => _metcons[id];
}

class MetconsCubit extends Cubit<MetconsState> {
  MetconsCubit() : super(const MetconsInitial());

  void loadMetcons(List<UiMetcon> metcons) {
    emit(MetconsLoaded.fromList(metcons));
  }

  void addMetcon(UiMetcon metcon) {
    if (state is MetconsLoaded) {
      final metcons = (state as MetconsLoaded).metconsMap;
      if (!metcons.containsKey(metcon.id)) {
        if (metcon.id != null) {
          metcons[metcon.id!] = metcon;
          emit(MetconsLoaded(metcons));
        } else {
          addError(Exception("Adding metcon that does not have an id"));
        }
      } else {
        addError(Exception("Adding metcon that already exists."));
      }
    } else {
      addError(Exception("Adding metcon when metcons are not yet loaded."));
    }
  }

  void addMetconIfNotExists(UiMetcon metcon) {
    if (state is MetconsLoaded) {
      final metcons = (state as MetconsLoaded).metconsMap;
      if (!metcons.containsKey(metcon.id)) {
        if (metcon.id != null) {
          metcons[metcon.id!] = metcon;
          emit(MetconsLoaded(metcons));
        } else {
          addError(Exception("Adding metcon that does not have an id."));
        }
      }
    } else {
      addError(Exception("Adding metcon when metcons are not yet loaded."));
    }
  }

  void deleteMetcon(int id) {
    if (state is MetconsLoaded) {
      final metcons = (state as MetconsLoaded).metconsMap;
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

  void updateMetcon(UiMetcon metcon) {
    if (state is MetconsLoaded) {
      final metcons = (state as MetconsLoaded).metconsMap;
      if (metcons.containsKey(metcon.id)) {
        if (metcon.id != null) {
          metcons[metcon.id!] = metcon;
          emit(MetconsLoaded(metcons));
        } else {
          addError(Exception("Editing metcon that does not have an id."));
        }
      } else {
        addError(Exception("Editing metcon that does not exist."));
      }
    } else {
      addError(Exception("Editing metcon when metcons are not yet loaded."));
    }
  }
}